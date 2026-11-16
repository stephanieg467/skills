---
name: code-review
description: "Reviews the changes since a fixed point (commit, branch, tag, or merge-base) along three axes in parallel sub-agents: Standards (repo docs and matching coding-standard skills), Spec (the plan, report, Jira ticket, or PR/MR description it implements), and Technical (correctness, security, performance, simplicity). Verifies every finding before reporting, and can fix accepted findings or output copy-pasteable PR/MR comments. Use when the user wants to review a branch, a PR or MR, work-in-progress changes, or the result of implement-plan, or asks to \"review since X\"."
argument-hint: "[fixed-point] [spec-paths...] [fix|comment]"
---

Three-axis review of the diff between `HEAD` and a fixed point:

- **Standards**: does the code conform to this repo's documented coding standards?
- **Spec**: does the code faithfully implement the plan, ticket, or PR/MR it came from?
- **Technical**: is the code correct, secure, performant, and simple?

Each axis runs as a **parallel sub-agent** so they don't pollute each other's context, then this skill verifies and aggregates their findings. Start every sub-agent with a fresh context window.

Different models have different blind spots. If this session's model wrote the change (for example, Claude reviewing work `implement-plan` did in Claude Code), warn the user that the review is not independent before continuing.

## Process

### 1. Parse arguments

Usage: `/code-review [fixed-point] [spec-paths...] [fix|comment]`, in any order.

- The exact token `fix` turns on fix mode (step 8). The exact token `comment` turns on comment mode (step 7). Without either, fix is the default.
- Every token that is an existing file is a spec path, such as a plan or an implementation report.
- Any other token is the fixed point (a commit SHA, branch name, tag, `main`, `HEAD~5`, etc.).
- If there is no fixed point, use the default branch: `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'`, falling back to `main`. Say which one you used.

### 2. Pin the diff

Capture the diff once and write it to a file outside the repo: `git diff <fixed-point>...HEAD > <scratch-dir>/review.diff` (three-dot, so the comparison is against the merge-base). Sub-agents may not be able to run Git, so they review this file, not a command. Also note the list of commits via `git log <fixed-point>..HEAD --oneline`, and list untracked files via `git ls-files --others --exclude-standard`, excluding plan and report files.

Before going further, confirm the fixed point resolves (`git rev-parse <fixed-point>`) and the diff is non-empty. A bad ref or empty diff should fail here, not inside three parallel sub-agents.

### 3. Identify the spec source

Look for the originating spec, in this order, and stop at the first hit:

1. The spec paths from the arguments.
2. A Jira key (`ABC-123`) in the branch name or commit messages, fetched with the `jira` skill: summary, description, and acceptance criteria.
3. The current branch's PR/MR description: `gh pr view --json title,body` on GitHub, `glab mr view` on GitLab.
4. If nothing is found, ask the user where the spec is. If they say there isn't one, skip the **Spec** sub-agent and report "no spec available".

### 4. Identify the standards sources

- Every repo file that documents how code should be written. `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, and `CODING_STANDARDS.md` must be on the list when they exist.
- Every available skill whose description matches the diff's file types or kind of change. For example: `typescript-best-practices` for `.ts`/`.tsx`, `testing-standards` for tests and fixtures, `code-comments` for new or changed functions, and a framework skill (React, MUI, Drupal, and so on) for the code it covers. Pass their `SKILL.md` paths.

If a skill conflicts with a repo file, the repo file wins.

### 5. Spawn the three sub-agents in parallel

Issue all sub-agent (worker or general) calls together, in the foreground. Each prompt contains:

- "Read and follow `<skill-dir>/references/<axis>-brief.md`. You are read-only: do not edit files."
- The diff file path, the commit list, and the untracked files to read directly.
- The **Finding format** section below, pasted in full.
- For **Standards** ([references/standards-brief.md](references/standards-brief.md)): the standards-source paths from step 4.
- For **Spec** ([references/spec-brief.md](references/spec-brief.md)): the spec paths or fetched contents from step 3.
- For **Technical** ([references/technical-brief.md](references/technical-brief.md)): nothing extra.

#### Finding format

Report only findings backed by evidence, under 400 words. Write each finding as:

```text
[Severity] path/to/file.ext:line
Issue: <what is wrong>
Why: <concrete failure, risk, or rule broken>
Evidence: <quoted hunk, test result, spec line, or cited standard>
Fix: <smallest safe fix>
```

Severity is one of:

- **Critical**: bug, security hole, data loss, or broken functionality. Blocks merge.
- **Required**: real defect or clear standards violation. Must be fixed before merge.
- **Consider**: worth doing, not required.
- **Nit**: minor and optional.

### 6. Verify and report

Do not forward sub-agent output mechanically. Check each finding against the diff and the surrounding code, then mark it:

- **accept**: real, and worth acting on in this change.
- **reject**: wrong, speculative, or pure taste. Note why in one line.
- **escalate**: needs a product, API, or scope decision from the user.

Merge duplicates within an axis and keep the sub-agent's severity unless verification changes it.

Present the accepted findings under `## Standards`, `## Spec`, and `## Technical` headings, ordered by severity. Do **not** merge or rerank findings across axes. Follow with rejected findings (one-line reason each) and escalated ones.

End with:

- total accepted findings per axis, and the worst issue _within each axis_;
- **Ready to merge?** Yes | With fixes | No, with one sentence of reasoning.

### 7. Comment mode

Make no changes. Instead of the report, output only the accepted findings as comments ready to paste on the PR/MR. Order them Critical, Required, Consider, Nit. Drop Nits when there are more than three. End with one overall summary comment.

````markdown
**`src/cart/CartService.php:88`**

Required: `applyDiscount()` reads `$cart->total` before `recalculate()` runs, so a coupon added in the same request applies to the stale total. Moving the call below `recalculate()` on line 91 fixes it, and a test adding a coupon and an item in one request would catch a regression.
````

- Write each comment to the code, not the author, in plain direct sentences.
- Say what is wrong, why it matters, and the smallest fix.
- If the fix is an exact small replacement, add a `suggestion` block (GitHub: ```` ```suggestion ````, GitLab: ```` ```suggestion:-0+0 ````).

### 8. Fix mode

After the report, send the accepted Critical and Required findings to one worker sub-agent to fix. Leave the fixes uncommitted.

- The worker runs focused checks and the affected runtime journeys through the project's `verify-<app>` skill, retaining evidence after cleanup.
- If runtime verification is needed but no relevant skill exists, ask before creating one with `create-verification-skill`. Declined or unavailable setup is blocked verification.
- For fixes without runtime behavior, record verification as not applicable with a reason.
- Then rerun only the affected axes on the fixes (`git diff`) and the code they touch.

Stop after three review rounds, or earlier when no Critical or Required finding remains. Do not spend a round on Consider or Nit items; list them for the user instead. Report the rounds, the findings fixed, the checks run with outcomes, and runtime verification results with evidence paths. Report failed or blocked verification explicitly rather than assigning smoke checks to the user.

## Why separate axes

A change can pass one axis and fail another:

- Code that follows every standard but implements the wrong thing → **Standards pass, Spec fail.**
- Code that does exactly what the plan asked but breaks the project's conventions → **Spec pass, Standards fail.**
- Code that matches the spec and the standards but mishandles an empty list → **Technical fail.**

Reporting them separately stops one axis from masking another.

## Gotchas

- `git diff` omits untracked files. List them in every prompt, or new files go unreviewed.
- The plan and report describe intent and claims. They are not proof; the Spec brief tells the sub-agent to verify them, so do not soften that.
- A false positive pasted into a PR/MR costs trust. Comment mode needs step 6 more than any other mode.
