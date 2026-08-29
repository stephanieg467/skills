---
name: implement-and-review
description: Implements a scoped change or reviews existing changes with an independent cross-model Claude review and bounded fix loop. Use when work should be completed or reviewed before handoff.
argument-hint: "[task, specification, ticket, plan, current changes, commit, branch, or PR]"
---

# Implement and Review

Implement the requested change through a worker and review it, or independently review an existing change set. In both modes, a fresh, read-only Claude reviewer inspects the actual diff. The parent owns scope, decisions, finding disposition, review rounds, and the final report.

The reviewer must use a different model from any implementation or fix worker. This cross-model independence is the reason for this workflow and must not be weakened or implied when unavailable.

## Invocation Modes

- **Implement + review** — For a task, specification, issue, or approved plan, use the existing worker-to-independent-Claude-review workflow below.
- **Review existing changes** — When the user asks to review current work, a commit, branch, pull request, or changes since a fixed point, skip initial implementation. Resolve fixed points to commits and identify the base and endpoint explicitly. For changes since a fixed point, the default endpoint is the current checked-out state: review committed changes after the base, selected staged and unstaged worktree changes, and in-scope untracked files read directly. For a branch or pull request comparison, use the merge base and state whether the target includes selected worktree changes. Review any single-commit target with a root-aware patch so an initial commit is not omitted.

  Without an explicit target or fixed point, first select the worktree scope. An unscoped request to review current work includes all non-ignored untracked files; a task-bounded request includes attributable untracked files and requires scope confirmation when ownership is unclear. Review selected staged, unstaged, deleted, and in-scope untracked changes when any exist. Only when the resulting selected scope has no worktree changes, fall back to the latest commit using a root-aware patch. If no change set is available, stop and state clearly that nothing is reviewable.

Review-existing mode is read-only unless the user also authorizes fixes. When fixes are authorized, the parent still dispositions findings and one worker applies only accepted findings.

For either mode, resolve any supplied specification, plan, or issue for the **Spec** review axis. If none exists, report that Spec coverage is unavailable; do not invent requirements. Keep **Technical**, **Standards**, and **Spec** coverage separate so results in one axis do not mask another.

## Operating Contract

- The parent orchestrates; a worker is the only writer.
- Preserve unrelated dirty and untracked files. Never clean, reset, stage, commit, or overwrite them.
- Keep implementation and review bounded to the approved task.
- Escalate product, architecture, API, or scope decisions that are not already approved.
- Run focused automated checks appropriate to the changed surfaces. Report remaining manual smoke checks to the user.
- Do not write a review-report file unless the user requests one.
- Use at most three review rounds. Stop earlier when no blocker or finding worth fixing now remains; do not chase optional polish.

## 1. Establish Scope and Baseline

Before delegation:

1. Read the supplied task or review request, acceptance criteria, specification sources, approved plan or architecture, and applicable repository instructions.
2. Inspect `git status --short`, the current revision, and bounded diff summaries. Record the selected review target, its base and endpoint, and whether it includes worktree changes. Also record which worktree changes predate this task, including untracked files.
3. Define the bounded implementation or review scope, expected changed surfaces, acceptance evidence, and focused validation.
4. Record any implementation worker's model and select a Claude reviewer model that is different.

If requested work overlaps pre-existing changes and their ownership cannot be distinguished safely, stop and ask before editing. Do not use cleanup commands to manufacture a clean baseline.

Use `claude_agent_spawn` for review when it is available. Otherwise, spawn a fresh review agent explicitly configured to a Claude model. If implementation used the selected Claude model, choose another Claude model. If no different Claude model is available, report that cross-model independence could not be established; do not claim this workflow's independent review gate succeeded.

## 2. Delegate Implementation to One Worker

In implement + review mode, give the worker a compact, decision-complete brief containing:

- the approved behavior and boundaries;
- inherited architecture and repository standards;
- relevant targeted source references;
- acceptance criteria;
- baseline files that must remain untouched;
- focused automated checks and manual checks to report.

The worker validates the brief against current code, implements the smallest coherent change, and runs focused checks. It must pause for any required unapproved product, architecture, API, or scope decision rather than guessing.

After implementation, the parent inspects status and bounded diff summaries. Confirm that the diff is attributable to the task and that unrelated baseline changes remain intact before review. Skip this section in review-existing mode.

## 3. Run a Fresh Read-Only Claude Review

Start review round 1 with a fresh Claude context. The reviewer must not edit files and must not inherit a worker's reasoning as a substitute for independent analysis. Provide the review target, supplied specification sources and acceptance criteria, baseline, repository location, and review scope; let the reviewer inspect the actual diff or range and relevant repository context directly.

The reviewer must:

1. inventory added, modified, deleted, and in-scope untracked files;
2. give every changed file primary coverage, including removed content from deletions;
3. report separate Technical, Standards, and Spec coverage, comparing against supplied specification sources and applicable repository standards without letting one axis substitute for another;
4. inspect affected cross-file contracts, callers, registrations, schemas, lifecycle paths, and tests;
5. assess technical correctness, security, performance, regressions, test quality or gaps, and simplicity;
6. use bounded diff, search, and targeted context reads, expanding only when a complete contract or lifecycle is needed;
7. run focused read-only checks when practical to verify a suspected issue.

Do not flood reviewer context with an unbounded diff or broad repository reads. Start with status, name/status, stat, and numstat views; inspect relevant files or clusters with bounded context. For untracked files, read contents directly. For deletions, inspect the removed base content.

### Finding Standard

Report only evidence-backed problems with a concrete failure mode or standards violation. Exclude speculative concerns, subjective style preferences, and optional polish.

Each finding must include:

```text
severity: blocker | high | medium | low
axis: Technical | Standards | Spec
file: path/to/file.ext
line: <line or smallest relevant range>
issue: <concise problem>
impact: <concrete behavior, risk, or acceptance criterion affected>
evidence: <diff/context/test evidence>
smallest-safe-fix: <minimal correction>
```

Use multiple axes only when one finding genuinely spans them. A `low` finding is valid only when it identifies a real issue worth fixing now. If there are no qualifying findings, say so and summarize changed-file and cross-file coverage.

## 4. Parent Disposition

The parent verifies each finding against the diff, surrounding code, specification, and repository rules. Classify it as:

- **accept** — real and worth fixing now;
- **reject** — incorrect, speculative, style-only, or outside scope;
- **escalate** — requires an unapproved product, architecture, API, or scope decision;
- **defer** — real but explicitly not worth changing in this task, with rationale and risk.

Do not forward reviewer output mechanically. Resolve duplicates and preserve the smallest safe fix. Escalated findings pause the fix loop until the decision is supplied.

## 5. Apply Accepted Fixes Through One Worker

In implement + review mode, or when the user has authorized fixes in review-existing mode, send one worker only the accepted findings, evidence, constraints, and focused checks. Prefer the original implementation worker when continuity is useful, but keep a single writer. The worker applies only accepted fixes and reports the resulting diff and check outcomes. Otherwise, keep review-existing mode read-only and report the dispositions.

The parent confirms that fixes did not widen scope or disturb unrelated files.

## 6. Re-review Only When Warranted

Run a fresh, focused Claude re-review when a fix changes behavior, a contract, security-sensitive code, or enough code to create meaningful regression risk. The re-review covers the fixes and affected interactions, while retaining primary coverage evidence from the initial full review.

A review followed by disposition is one round. Repeat the review/disposition/fix cycle for no more than three rounds total. After round 3, stop and report remaining accepted, deferred, or escalated risks rather than continuing indefinitely.

Stop before the limit when:

- no blocker remains;
- no evidence-backed finding is worth fixing now;
- focused automated checks support the acceptance criteria.

Optional cleanup, taste-based refactors, and speculative hardening do not justify another round.

## 7. Final Handoff

Before reporting:

- inspect the final bounded diff and status;
- confirm each in-scope changed file received primary review coverage;
- confirm affected cross-file contracts were checked;
- run or confirm focused automated checks;
- verify no files were staged, committed, reset, or cleaned by the workflow;
- distinguish automated results from manual smoke checks still owed by the user.

Report:

- changed, added, and deleted files;
- concise implementation or reviewed-change rationale;
- reviewer model and any implementation or fix worker model, or the explicit independence limitation;
- review rounds and disposition of findings;
- commands with outcomes;
- manual smoke checks;
- residual risks and escalated decisions;
- staging/commit status and preservation of unrelated worktree files.
