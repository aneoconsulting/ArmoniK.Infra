// Keeps approvals that still match the pull request diff and dismisses the
// others, replacing the ruleset's "dismiss stale approvals" setting, which also
// dismisses on a merge-base move and so on every rebase of a stack. See
// .github/approval-freshness.md.
//
// The diff fingerprint is `git patch-id --verbatim` of the diff between the head
// and its merge base with the live tip of the base branch (the API's base.sha is
// a snapshot): line numbers are ignored, whitespace, modes and binary content
// are not. Each approval's fingerprint is recorded when the approval is first
// seen, in the approval-freshness check runs of the commit it approved:
// recomputing it later would diff against a base that may have been rewritten
// or squash-merged since. An approval seen for the first time is fingerprinted
// against the current base, so it is fresh if its commit is still the head,
// whatever the base was when it was given.
//
// A stale approval is dismissed only when the head changed since the approval
// was last fresh. When only the base moved (a lower pull request amended, a
// retarget before the rebase), the approval is kept and the check fails until
// the pull request is rebased: dismissing would be irreversible, and the head
// still holds what was approved.
//
// The check run on the head is the required check: it closes the window
// between a push and the dismissals, except for a push back to a commit already
// evaluated as head, whose last check stands until the next evaluation. Posted
// with GITHUB_TOKEN, it joins the head's existing GitHub Actions check suite,
// which the relay's pull_request run provides; that suite is what lets it
// satisfy a required check from this non-PR context.
//
// A commit's record is the union of all its check runs, the earliest
// fingerprint winning, so that concurrent runs (a stacked pull request is also
// evaluated with its parent) cannot lose one; runs need no other ordering.
//
// Moving a base branch sends no event to the pull requests based on it, so the
// pull requests stacked on an evaluated one are evaluated with it. Other base
// moves (a branch that is no pull request head, a merge bringing in commits a
// pull request already contains) wait for the pull request's next event: the
// default branch, which rejects forced pushes, only takes content through a pull
// request evaluated against its own diff.

const { execFileSync } = require('child_process');

const CHECK = 'approval-freshness';
const MARKER = /<!-- approval-freshness (\{.*?\}) -->/;
const BASE_REF = 'refs/approval-freshness/base';

function git(...args) {
  return execFileSync('git', args, { encoding: 'utf8' }).trim();
}

function present(sha) {
  try {
    git('cat-file', '-e', `${sha}^{commit}`);
    return true;
  } catch {
    return false;
  }
}

// Piped so that a large diff never sits in memory; 'empty' for an empty diff,
// null when the commits share no history.
function fingerprint(head, base) {
  let mergeBase;
  try {
    mergeBase = git('merge-base', head, base);
  } catch {
    return null;
  }
  const script = 'set -o pipefail; git diff --no-color --no-ext-diff --no-textconv --no-renames --binary "$1" "$2" | git patch-id --verbatim';
  const out = execFileSync('bash', ['-c', script, 'bash', mergeBase, head], { encoding: 'utf8' });
  return out.split(' ')[0].trim() || 'empty';
}

module.exports = async ({ github, context, core }) => {
  const { owner, repo } = context.repo;

  // The latest check run on a commit, and the record of all of them: the
  // fingerprint of each approval of the commit, and the approvals found fresh
  // while it was the head.
  const runCache = new Map();
  async function latestRun(sha) {
    if (!runCache.has(sha)) {
      const runs = (await github.paginate(github.rest.checks.listForRef, {
        owner, repo, ref: sha, check_name: CHECK, filter: 'all', per_page: 100,
      })).filter((r) => r.app && r.app.slug === 'github-actions').sort((a, b) => a.id - b.id);
      const record = { prints: {}, fresh: [] };
      for (const run of runs) {
        const match = run.output && run.output.text && run.output.text.match(MARKER);
        if (!match) continue;
        const { prints = {}, fresh = [] } = JSON.parse(match[1]);
        for (const [id, print] of Object.entries(prints)) {
          if (!(id in record.prints)) record.prints[id] = print;
        }
        record.fresh = [...new Set([...record.fresh, ...fresh])];
      }
      runCache.set(sha, { run: runs[runs.length - 1], record });
    }
    return runCache.get(sha);
  }

  // Skipped when the latest run already says the same, so that re-evaluations
  // do not pile up identical runs.
  async function writeRun(sha, conclusion, title, summary, record) {
    const canonical = {
      prints: Object.fromEntries(Object.entries(record.prints).sort(([a], [b]) => a - b)),
      fresh: [...record.fresh].sort((a, b) => a - b),
    };
    const text = `<!-- approval-freshness ${JSON.stringify(canonical)} -->`;
    const { run } = await latestRun(sha);
    if (!(run && run.conclusion === conclusion && run.output
          && run.output.summary === summary && run.output.text === text)) {
      await github.rest.checks.create({
        owner, repo, name: CHECK, head_sha: sha, status: 'completed', conclusion,
        output: { title, summary, text },
      });
    }
    runCache.set(sha, { run: { conclusion, output: { summary, text } }, record: canonical });
  }

  // Fetches a commit that may be gone: false when the API no longer knows it,
  // a throw when the fetch failed for another reason.
  async function fetchCommit(sha) {
    if (present(sha)) return true;
    try {
      git('fetch', '--quiet', '--no-tags', 'origin', sha);
      return true;
    } catch (error) {
      try {
        await github.rest.repos.getCommit({ owner, repo, ref: sha });
      } catch (missing) {
        if (missing.status === 404 || missing.status === 422) return false;
      }
      throw error;
    }
  }

  async function dismiss(number, review, reason) {
    try {
      await github.rest.pulls.dismissReview({
        owner, repo, pull_number: number, review_id: review.id, event: 'DISMISS', message: reason,
      });
      return true;
    } catch (error) {
      // Another run may have dismissed it first.
      try {
        const { data } = await github.rest.pulls.getReview({ owner, repo, pull_number: number, review_id: review.id });
        if (data.state === 'DISMISSED') return true;
      } catch {
        // Reported below with the original error.
      }
      core.warning(`#${number}: cannot dismiss review ${review.id}: ${error.message}`);
      return false;
    }
  }

  // False when the head is left failing: a stale approval could not be
  // dismissed, or only the base moved.
  async function evaluate(pr) {
    const number = pr.number;
    const head = pr.head.sha;
    git('fetch', '--quiet', '--no-tags', 'origin', `+refs/heads/${pr.base.ref}:${BASE_REF}`, `refs/pull/${number}/head`);
    const base = git('rev-parse', BASE_REF);
    if (!await fetchCommit(head)) throw new Error(`head ${head} not found`);
    const current = fingerprint(head, base);
    if (current === null) throw new Error(`head ${head} shares no history with ${pr.base.ref}`);
    const prints = new Map([[head, current]]);

    const reviews = await github.paginate(github.rest.pulls.listReviews, {
      owner, repo, pull_number: number, per_page: 100,
    });
    const approvals = reviews.filter((review) => review.state === 'APPROVED');

    // Per commit, the record extended with the fingerprints first seen now.
    const { record: headRecord } = await latestRun(head);
    const updates = new Map([[head, { prints: { ...headRecord.prints }, fresh: [...headRecord.fresh] }]]);
    const lines = [];
    let undismissed = 0;
    let kept = 0;
    for (const review of approvals) {
      const sha = review.commit_id;
      const short = sha ? sha.slice(0, 7) : 'unknown commit';
      const who = review.user ? `@${review.user.login}` : `review ${review.id}`;
      let print = null;
      if (sha) {
        const { record } = await latestRun(sha);
        print = record.prints[review.id];
        if (print === undefined) {
          if (!prints.has(sha)) prints.set(sha, await fetchCommit(sha) ? fingerprint(sha, base) : null);
          print = prints.get(sha);
          if (print !== null) {
            if (!updates.has(sha)) updates.set(sha, { prints: { ...record.prints }, fresh: [...record.fresh] });
            updates.get(sha).prints[review.id] = print;
          }
        }
      }
      if (print === current) {
        if (!updates.get(head).fresh.includes(review.id)) updates.get(head).fresh.push(review.id);
        lines.push(`- ${who} (${short}): fresh`);
        continue;
      }
      if (headRecord.fresh.includes(review.id)) {
        kept += 1;
        lines.push(`- ${who} (${short}): stale since the base moved, kept until the head changes`);
        continue;
      }
      const reason = print === null
        ? `The approved commit ${short} can no longer be compared with the pull request diff.`
        : `The pull request diff changed since this approval of ${short}.`;
      if (await dismiss(number, review, reason)) {
        lines.push(`- ${who} (${short}): stale, dismissed`);
      } else {
        undismissed += 1;
        lines.push(`- ${who} (${short}): stale, NOT dismissed`);
      }
    }

    // A record on a commit other than the head is written as a failure, so
    // that a push back to that commit stays blocked until it is re-evaluated.
    for (const [sha, recorded] of updates) {
      if (sha === head) continue;
      await writeRun(sha, 'failure', 'Approval fingerprints only, not evaluated as head',
                     'This commit is not the pull request head.', recorded);
    }
    const summary = lines.length > 0 ? lines.join('\n') : 'No approval yet.';
    core.info(`#${number} ${head} ${current}\n${summary}`);
    if (undismissed > 0) {
      await writeRun(head, 'failure', `${undismissed} stale approval(s) could not be dismissed`, summary, updates.get(head));
      core.error(`#${number}: ${undismissed} stale approval(s) could not be dismissed`);
      return false;
    }
    if (kept > 0) {
      await writeRun(head, 'failure', `The base moved: rebase to re-evaluate ${kept} approval(s)`, summary, updates.get(head));
      return true;
    }
    await writeRun(head, 'success', 'Every remaining approval matches the current diff', summary, updates.get(head));
    return true;
  }

  // The pull requests to evaluate, depending on the trigger.
  let prs = [];
  if (context.eventName === 'workflow_run') {
    // pull_requests is empty when the head is in a fork: look it up by head.
    const run = context.payload.workflow_run;
    for (const { number } of run.pull_requests) {
      prs.push((await github.rest.pulls.get({ owner, repo, pull_number: number })).data);
    }
    if (prs.length === 0 && run.head_repository) {
      prs = await github.paginate(github.rest.pulls.list, {
        owner, repo, state: 'open', head: `${run.head_repository.owner.login}:${run.head_branch}`, per_page: 100,
      });
    }
  } else {
    const input = context.payload.inputs && context.payload.inputs['pull-request'];
    if (input) {
      prs = [(await github.rest.pulls.get({ owner, repo, pull_number: Number(input) })).data];
    } else {
      prs = await github.paginate(github.rest.pulls.list, { owner, repo, state: 'open', per_page: 100 });
    }
  }
  prs = prs.filter((pr) => pr.state === 'open');

  // Plus the pull requests stacked on them, whose base branch they are.
  const queue = new Map(prs.map((pr) => [pr.number, pr]));
  for (const pr of prs) {
    if (!pr.head.repo || pr.head.repo.full_name !== `${owner}/${repo}`) continue;
    const stacked = await github.paginate(github.rest.pulls.list, {
      owner, repo, state: 'open', base: pr.head.ref, per_page: 100,
    });
    for (const child of stacked) queue.set(child.number, child);
  }

  let failures = 0;
  for (const [number, pr] of queue) {
    try {
      if (!await evaluate(pr)) failures += 1;
    } catch (error) {
      failures += 1;
      core.error(`#${number}: ${error.message}`);
      // An approval may be stale and not dismissed: block until a run succeeds.
      try {
        await writeRun(pr.head.sha, 'failure', 'Approvals could not be evaluated', error.message,
                       (await latestRun(pr.head.sha)).record);
      } catch (reportError) {
        core.error(`#${number}: cannot report the failure: ${reportError.message}`);
      }
    }
  }
  if (failures > 0) core.setFailed(`${failures} pull request(s) could not be evaluated`);
};
