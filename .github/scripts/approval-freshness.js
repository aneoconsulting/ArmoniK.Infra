// Keeps approvals that still match the pull request diff and dismisses the
// others, replacing the ruleset's "dismiss stale approvals" setting, which also
// dismisses on a merge-base move and so on every rebase of a stack. See
// .github/approval-freshness.md.
//
// The diff fingerprint is `git patch-id --verbatim` of the diff between the head
// and its merge base with the live tip of the base branch (the API's base.sha is
// a snapshot): line numbers are ignored, whitespace, modes and binary content
// are not. Each approval's fingerprint is recorded when the approval is first
// seen, in the approval-freshness-record check runs of the commit it approved:
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
// The approval-freshness commit status on the head is the required check: it
// closes the window between a push and the dismissals, except for a push back to
// a commit already evaluated as head, whose last status stands until the next
// evaluation. It is a status rather than a check run because a check run created
// through the API joins an existing GitHub Actions check suite of the commit,
// and a pull request hides the whole suite of a workflow run superseded on the
// same commit (two events for one push), check run included. Record check runs
// are read whatever suite they are in, and written only when a record grows.
//
// A commit's record is the union of all its record check runs, the earliest
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

const STATUS = 'approval-freshness';
const RECORD = 'approval-freshness-record';
// Check runs named like the status hold records too.
const RECORD_NAMES = [RECORD, STATUS];
const MARKER = /<!-- approval-freshness (\{.*?\}) -->/;
const BASE_REF = 'refs/approval-freshness/base';
const ATTEMPTS = 3;

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

// A record in a stable form, so that equal records compare equal as text.
function canonical(record) {
  return {
    prints: Object.fromEntries(Object.entries(record.prints).sort(([a], [b]) => a - b)),
    fresh: [...record.fresh].sort((a, b) => a - b),
  };
}

module.exports = async ({ github, context, core }) => {
  const { owner, repo } = context.repo;

  // The record of a commit, the union of its record check runs: the
  // fingerprint of each approval of the commit, and the approvals found fresh
  // while it was the head.
  const records = new Map();
  async function recordOf(sha) {
    if (!records.has(sha)) {
      const runs = [];
      for (const name of RECORD_NAMES) {
        runs.push(...await github.paginate(github.rest.checks.listForRef, {
          owner, repo, ref: sha, check_name: name, filter: 'all', per_page: 100,
        }));
      }
      runs.sort((a, b) => a.id - b.id);
      const record = { prints: {}, fresh: [] };
      for (const run of runs) {
        if (!run.app || run.app.slug !== 'github-actions') continue;
        const match = run.output && run.output.text && run.output.text.match(MARKER);
        if (!match) continue;
        const { prints = {}, fresh = [] } = JSON.parse(match[1]);
        for (const [id, print] of Object.entries(prints)) {
          if (!(id in record.prints)) record.prints[id] = print;
        }
        record.fresh = [...new Set([...record.fresh, ...fresh])];
      }
      records.set(sha, canonical(record));
    }
    return records.get(sha);
  }

  // Reports a verdict on a commit, written every time so that its details link
  // to the run that reached it.
  async function writeStatus(sha, state, title) {
    await github.rest.repos.createCommitStatus({
      owner, repo, sha, state, context: STATUS, description: title,
      target_url: `${context.serverUrl}/${owner}/${repo}/actions/runs/${context.runId}`,
    });
  }

  // Extends the record of a commit, skipped unless it grows, so a commit gets a
  // record run only once it has an approval to record.
  async function writeRecord(sha, summary, record) {
    const extended = canonical(record);
    if (JSON.stringify(extended) === JSON.stringify(await recordOf(sha))) return;
    const prints = Object.keys(extended.prints).length;
    const fresh = extended.fresh.length;
    await github.rest.checks.create({
      owner, repo, name: RECORD, head_sha: sha, status: 'completed', conclusion: 'neutral',
      output: {
        title: [prints && `${prints} approval fingerprint(s)`, fresh && `${fresh} fresh approval(s)`]
          .filter(Boolean).join(', '),
        summary,
        text: `<!-- approval-freshness ${JSON.stringify(extended)} -->`,
      },
    });
    records.set(sha, extended);
  }

  // The record goes first: a verdict written without it could keep a head
  // passing whose fresh approvals a later base move would then dismiss.
  async function report(sha, state, title, summary, record) {
    await writeRecord(sha, summary, record);
    await writeStatus(sha, state, title);
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
  // dismissed, or only the base moved. reached.head is the head a failure
  // belongs to, which moves when the evaluation starts over.
  async function evaluate(pr, reached, attempt = 1) {
    const number = pr.number;
    const head = pr.head.sha;
    reached.head = head;
    git('fetch', '--quiet', '--no-tags', 'origin', `+refs/heads/${pr.base.ref}:${BASE_REF}`, `refs/pull/${number}/head`);
    const base = git('rev-parse', BASE_REF);
    if (!await fetchCommit(head)) throw new Error(`head ${head} not found`);
    const current = fingerprint(head, base);
    if (current === null) throw new Error(`head ${head} shares no history with ${pr.base.ref}`);
    const prints = new Map([[head, current]]);

    const reviews = await github.paginate(github.rest.pulls.listReviews, {
      owner, repo, pull_number: number, per_page: 100,
    });
    // An approval of a newer head would be compared with this one and
    // dismissed: start over on the pull request as it is now if it moved.
    const { data: latest } = await github.rest.pulls.get({ owner, repo, pull_number: number });
    if (latest.state !== 'open') return true;
    if (latest.head.sha !== head || latest.base.ref !== pr.base.ref) {
      if (attempt >= ATTEMPTS) {
        reached.head = latest.head.sha;
        throw new Error(`the pull request moved during ${ATTEMPTS} evaluations`);
      }
      return evaluate(latest, reached, attempt + 1);
    }
    const approvals = reviews.filter((review) => review.state === 'APPROVED');

    // Per commit, the record extended with the fingerprints first seen now.
    const headRecord = await recordOf(head);
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
        const record = await recordOf(sha);
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
      await report(sha, 'failure', 'Approval fingerprints only, not evaluated as head',
                   'This commit is not the pull request head.', recorded);
    }
    const summary = lines.length > 0 ? lines.join('\n') : 'No approval yet.';
    core.info(`#${number} ${head} ${current}\n${summary}`);
    if (undismissed > 0) {
      await report(head, 'failure', `${undismissed} stale approval(s) could not be dismissed`, summary, updates.get(head));
      core.error(`#${number}: ${undismissed} stale approval(s) could not be dismissed`);
      return false;
    }
    if (kept > 0) {
      await report(head, 'failure', `The base moved: rebase to re-evaluate ${kept} approval(s)`, summary, updates.get(head));
      return true;
    }
    await report(head, 'success', 'Every remaining approval matches the current diff', summary, updates.get(head));
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
    const reached = { head: pr.head.sha };
    try {
      if (!await evaluate(pr, reached)) failures += 1;
    } catch (error) {
      failures += 1;
      core.error(`#${number}: ${error.message}`);
      // An approval may be stale and not dismissed: block until a run succeeds,
      // whatever the record holds.
      try {
        await writeStatus(reached.head, 'failure', 'Approvals could not be evaluated');
      } catch (reportError) {
        core.error(`#${number}: cannot report the failure: ${reportError.message}`);
      }
    }
  }
  if (failures > 0) core.setFailed(`${failures} pull request(s) could not be evaluated`);
};
