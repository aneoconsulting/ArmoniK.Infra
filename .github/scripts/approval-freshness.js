// Keeps approvals that still match the pull request diff and dismisses the
// others, replacing the ruleset's "dismiss stale approvals" setting, which also
// dismisses on a merge-base move and so on every rebase of a stack.
//
// The diff fingerprint is `git patch-id --verbatim` of the merge-base diff:
// line numbers are ignored, whitespace, modes and binary content are not.
// Each approval's fingerprint is recorded when the approval is first seen, in
// the approval-freshness check run of the commit it approved: recomputing it
// later would diff against a base that may have been rewritten or squash-merged
// since. An approval seen for the first time is fingerprinted against the
// current base, which can only err towards dismissing it.
//
// The check run on the head is the required check: it closes the window
// between a push and the dismissals, and fails when a stale approval could not
// be dismissed. Every run re-reads the whole state, so runs need no ordering.

const { execFileSync } = require('child_process');

const CHECK = 'approval-freshness';
const MARKER = /<!-- approval-fingerprints (\{.*?\}) -->/;

function git(args, input) {
  return execFileSync('git', args, { encoding: 'utf8', input, maxBuffer: 1 << 30 });
}

function fetched(sha) {
  try {
    git(['cat-file', '-e', `${sha}^{commit}`]);
    return true;
  } catch {
    try {
      git(['fetch', '--quiet', '--no-tags', 'origin', sha]);
      return true;
    } catch {
      return false;
    }
  }
}

// null when a commit cannot be fetched or shares no history with the base.
function fingerprint(head, base) {
  if (!fetched(head) || !fetched(base)) return null;
  let mergeBase;
  try {
    mergeBase = git(['merge-base', head, base]).trim();
  } catch {
    return null;
  }
  const diff = git(['diff', '--no-color', '--no-ext-diff', '--no-textconv', '--no-renames',
                    '--binary', mergeBase, head]);
  if (diff === '') return 'empty';
  return git(['patch-id', '--verbatim'], diff).split(' ')[0];
}

module.exports = async ({ github, context, core }) => {
  const { owner, repo } = context.repo;

  // The fingerprints recorded on a commit, from its latest check run.
  const recordCache = new Map();
  async function records(sha) {
    if (!recordCache.has(sha)) {
      const { data } = await github.rest.checks.listForRef({
        owner, repo, ref: sha, check_name: CHECK, filter: 'latest', per_page: 100,
      });
      const latest = data.check_runs
        .filter((run) => run.app && run.app.slug === 'github-actions')
        .sort((a, b) => b.id - a.id)[0];
      const match = latest && latest.output && latest.output.text && latest.output.text.match(MARKER);
      recordCache.set(sha, match ? JSON.parse(match[1]) : {});
    }
    return recordCache.get(sha);
  }

  async function writeRun(sha, conclusion, title, summary, fingerprints) {
    await github.rest.checks.create({
      owner, repo, name: CHECK, head_sha: sha, status: 'completed', conclusion,
      output: { title, summary, text: `<!-- approval-fingerprints ${JSON.stringify(fingerprints)} -->` },
    });
  }

  async function evaluate(number) {
    const { data: pr } = await github.rest.pulls.get({ owner, repo, pull_number: number });
    if (pr.state !== 'open') return;
    const head = pr.head.sha;
    const base = pr.base.sha;
    git(['fetch', '--quiet', '--no-tags', 'origin', base, `refs/pull/${number}/head`]);
    const current = fingerprint(head, base);
    if (current === null) throw new Error(`#${number}: cannot fingerprint ${head} against ${base}`);

    const reviews = await github.paginate(github.rest.pulls.listReviews, {
      owner, repo, pull_number: number, per_page: 100,
    });
    const approvals = reviews.filter((review) => review.state === 'APPROVED');

    // Per commit, the recorded fingerprints merged with the ones first seen now.
    const updates = new Map();
    const lines = [];
    let undismissed = 0;
    for (const review of approvals) {
      const sha = review.commit_id;
      const recorded = await records(sha);
      let print = recorded[review.id];
      if (print === undefined) {
        print = fingerprint(sha, base);
        if (print !== null) {
          if (!updates.has(sha)) updates.set(sha, { ...recorded });
          updates.get(sha)[review.id] = print;
        }
      }
      const who = review.user ? `@${review.user.login}` : `review ${review.id}`;
      if (print === current) {
        lines.push(`- ${who} (${sha.slice(0, 7)}): fresh`);
        continue;
      }
      try {
        await github.rest.pulls.dismissReview({
          owner, repo, pull_number: number, review_id: review.id, event: 'DISMISS',
          message: `The pull request diff changed since this approval of ${sha.slice(0, 7)}.`,
        });
        lines.push(`- ${who} (${sha.slice(0, 7)}): stale, dismissed`);
      } catch (error) {
        undismissed += 1;
        lines.push(`- ${who} (${sha.slice(0, 7)}): stale, NOT dismissed: ${error.message}`);
        core.warning(`#${number}: cannot dismiss review ${review.id}: ${error.message}`);
      }
    }

    // A record on a commit other than the head is written as a failure, so
    // that a push back to that commit stays blocked until it is re-evaluated.
    for (const [sha, fingerprints] of updates) {
      if (sha === head) continue;
      await writeRun(sha, 'failure', 'Approval fingerprints only, not evaluated as head',
                     'This commit is not the pull request head.', fingerprints);
    }
    const headPrints = updates.get(head) || await records(head);
    const summary = lines.length > 0 ? lines.join('\n') : 'No approval yet.';
    if (undismissed > 0) {
      await writeRun(head, 'failure', `${undismissed} stale approval(s) could not be dismissed`, summary, headPrints);
      core.setFailed(`#${number}: ${undismissed} stale approval(s) could not be dismissed`);
    } else {
      await writeRun(head, 'success', 'Every remaining approval matches the current diff', summary, headPrints);
    }
    core.info(`#${number} ${head} ${current}\n${summary}`);
  }

  // The pull requests to evaluate, depending on the trigger.
  let numbers = [];
  if (context.eventName === 'pull_request_target') {
    numbers = [context.payload.pull_request.number];
  } else if (context.eventName === 'workflow_run') {
    // pull_requests is empty when the head is in a fork: look it up by head.
    const run = context.payload.workflow_run;
    numbers = run.pull_requests.map((pr) => pr.number);
    if (numbers.length === 0 && run.head_repository) {
      const prs = await github.paginate(github.rest.pulls.list, {
        owner, repo, state: 'open', head: `${run.head_repository.owner.login}:${run.head_branch}`, per_page: 100,
      });
      numbers = prs.map((pr) => pr.number);
    }
  } else if (context.eventName === 'workflow_dispatch') {
    const input = context.payload.inputs && context.payload.inputs['pull-request'];
    if (input) {
      numbers = [Number(input)];
    } else {
      const prs = await github.paginate(github.rest.pulls.list, { owner, repo, state: 'open', per_page: 100 });
      numbers = prs.map((pr) => pr.number);
    }
  }

  let failures = 0;
  for (const number of numbers) {
    try {
      await evaluate(number);
    } catch (error) {
      failures += 1;
      core.error(`#${number}: ${error.message}`);
    }
  }
  if (failures > 0) core.setFailed(`${failures} pull request(s) could not be evaluated`);
};
