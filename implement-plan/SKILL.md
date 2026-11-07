---
name: implement-plan
description: Executes an approved implementation plan from plan-implementation task by task. Each task is implemented, checked with its own Validate command, and committed before the next one starts. Ends with focused checks and agent-run project verification, an implementation report saved next to the plan, and a handoff to cross-review.
argument-hint: "[path-to-plan]"
disable-model-invocation: true
---

# Implement Plan

Execute the plan at `$ARGUMENTS`. The plan is written by `plan-implementation`, which inherits from `decide-architecture`. Its decisions are settled: build what it says, in thin verified steps, and do not redesign it.

If `$ARGUMENTS` is empty or the file cannot be read, ask for the plan path before doing anything else.

## 1. Read the plan and check it against the code

1. Read the whole plan: Intent and Scope, Acceptance Criteria, Inherited Decisions, Implementation Evidence, Approach, Tasks, Validation, and Assumptions.
2. Spot-check the `path:line` references in Implementation Evidence against the current worktree. Plans go stale; a moved symbol is fine, a missing contract is not.
3. If a task has no **Validate** command, use a static check of its touched files (lint, type check, or syntax check).
4. If the plan conflicts with the code in a way that changes an inherited decision, a contract, or scope, stop and ask before editing.

## 2. Prepare the branch

Detect the base branch: `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'` (fall back to `main`).

- If you are on a feature branch or in a worktree, use it.
- If you are on the base branch with a clean worktree, run `git checkout -b feature/<plan-slug>`.
- If you are on the base branch with uncommitted changes, stop and ask the user to commit or stash them.

Run `git status --short` and record the files that are already dirty or untracked. They are not yours: never stage, commit, revert, or clean them.

If `git log` already shows commits for some of the plan's tasks on this branch, confirm with the user and resume at the first task without one.

## 3. Choose inline or delegated execution

Run tasks inline by default; you keep the full context across tasks.

If the plan has more than about six tasks, or the tasks together span many files, delegate each task to a fresh worker subagent instead. Give the worker the task block verbatim, plus Intent and Scope, Inherited Decisions, and the evidence lines the task references. The worker implements and runs the Validate command; you review its diff, then commit (step 4.4). Run workers one at a time, in plan order, because later tasks build on earlier ones.

## 4. Execute each task in order

For each task under `## Tasks`:

1. **Read** the files the task lists and the **Pattern** reference it points to.
2. **Implement** exactly the **Change**, honoring its **Constraints**. Write the tests the task calls for as part of the task, not at the end.
3. **Validate** by running the task's **Validate** command. If it fails, fix and re-run. Do not start the next task until it passes. If passing would require work outside this task, stop and ask.
4. **Commit** only the files this task changed: `git add <paths>`, then commit using the repository's message convention (check `git log --oneline -10`), for example `feat: <task title>`. Never stage plan files, report files, `docs/plans/*`, `docs/adr/*`, or `CONTEXT.md`.
5. **Record** anything that differed from the plan, and why, for the report's Deviations section.

### Deviations

- If the difference is local and does not change behavior or a contract (a renamed symbol, a moved file, an extra import), make it and record it.
- If the difference changes an inherited decision, a public contract, the acceptance criteria, or scope, stop and ask. The user decides; you do not.

### Scope

Touch only what the current task requires. If you notice something worth fixing outside it, add it to the report's "Noticed, not touched" list instead of fixing it.

Write the simplest code that satisfies the task. Do not add logging, documentation, abstractions, or defensive checks that the plan did not ask for.

## 5. Run the plan's validation

1. Run each command under **Validation → Focused Automated Checks** once. Do not re-run a command that already passed unless the code changed since.
2. If a check fails, fix the cause, commit the fix as its own commit, and re-run that check.
3. For the plan's **Runtime Verification**, locate and read the project's relevant `verify-<app>/SKILL.md`, feature-map index, and required feature files. Follow repository skill-location conventions; ask when the target is ambiguous. For older plans, treat **Manual Smoke Checks** as runtime journeys to execute, not homework to hand back.
4. If runtime verification is needed but no relevant skill exists, ask before running `create-verification-skill`. If setup is declined, unavailable, or unproved, report verification as blocked. Do not create a skill silently. If no runtime behavior is affected, record not applicable with the reason instead.
5. Follow the verification skill's launch, doctor, drive, evidence, and cleanup instructions for journeys covering the plan's acceptance criteria and affected entry points. Update missing or stale recipes within the approved scope; escalate changes that widen it. Generation's one-feature proof is not a substitute for these journeys.
6. Fix in-scope failures, commit the fix separately, and rerun affected automated checks and runtime journeys. Follow cleanup after failed attempts too. Confirm proof artifacts survive final cleanup and describe the tested revision and relevant uncommitted changes.
7. Record pass, fail, or blocked for each required journey, with observed results and evidence paths. Missing credentials, unavailable tooling or hardware, human-only judgment, or unsafe external side effects are explicit blockers; ask for the minimum action needed to unblock them. Never bypass approval or mark skipped checks as passed. If required verification remains failed or blocked, the report status is PARTIAL.

## 6. Write the report

Save the report next to the plan as `<plan-dir>/<plan-slug>.report.md`, for example `.claude/plans/user-export.md` becomes `.claude/plans/user-export.report.md`. Do not commit it. If the file exists, ask before overwriting it.

Use this structure, and omit sections that would only say "none" except Deviations:

```markdown
# Implementation Report — <feature>

**Plan:** <path>   **Branch:** <branch>   **Status:** COMPLETE | PARTIAL

## Summary
<What was built, 2-4 sentences.>

## Tasks
- <task title> — <commit sha> — <files>

## Validation
- `<command>` — pass/fail <counts>

## Runtime verification
- **Skill:** <path, or not applicable with reason>
- <journey and entry point> — pass/fail/blocked — <observed result> — <evidence paths>
- **Tested state:** <revision and relevant uncommitted changes>
- **Cleanup:** <outcome; evidence retained>

## Deviations from the plan
<What differed and why, or "None". Reviewers treat these as intentional.>

## Noticed, not touched
- <out-of-scope observation>

## Verification blockers
- <affected criterion, unmet prerequisite, and minimum action needed; omit when empty>
```

## 7. Hand off

Report the branch, the commit list, the report path, any deviations, runtime verification results with evidence paths, and any verification blockers. Then suggest the review command:

```text
/cross-review <reviewer-model> <plan-path> <report-path>
```

## Gotchas

- `plan-implementation` puts tests inside each task. Writing all tests after the last task breaks the per-task Validate gate.
- Plan files and reports are working artifacts and must never be committed. A blanket `git add -A` or `git commit -a` will pick them up, along with the user's unrelated changes, so stage explicit paths.
- Runtime journeys are the agent's responsibility, including smoke checks in older plans. A generated skill or passing unit test does not prove a user journey; report only what was actually driven.
- Running the full suite, build, and lint after every task wastes time. The task's Validate command is the per-task gate; the focused checks run once at the end.
- If a Validate command fails for reasons unrelated to the change (a missing service, flaky infrastructure), do not mark the task as passing. Report the exact failure and ask.
