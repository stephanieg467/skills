---
name: cross-review
description: Reviews code changes with an independent agent running a reviewer model chosen by the user, then either fixes accepted findings or returns copy-pasteable merge request comments. Works for self-generated changes and for someone else's merge request or pull request.
argument-hint: "<reviewer-model> [comment] [target] [plan-path|-] [report-path]"
disable-model-invocation: true
---

# Cross Review

Send a change set to a fresh, read-only reviewer on a different model, verify what it finds, then act on it. Different models have different blind spots; a reviewer on the same model as the author shares them.

## 1. Parse arguments

Usage: `/cross-review <reviewer-model> [comment] [target] [plan-path|-] [report-path]`. The reviewer model is required and always first. The other tokens may appear in any order except plan before report.

- The first token is the reviewer model, such as `claude-opus-5-5` or `openai-codex/gpt-6.1-sol`.
- If there are no arguments, or the first token is `comment`, `-`, an existing file, `!<n>`, `#<n>`, or a URL, the model is missing. Stop and ask the user which reviewer model to use before doing anything else. Use `AskUserQuestion` when it is available, and offer the models listed by `pi --list-models` as options.
- The exact token `comment` turns on comment mode (see step 6).
- A token that is an existing file is a context document. The first is the implementation plan, the second is the post-implementation report.
- The token `-` stands in for a missing plan, so a report can be passed alone.
- Any other token is the target: a git ref, `!123` (GitLab MR), `#123` (GitHub PR), or an MR/PR URL.
- Resolve paths relative to the current working directory and quote paths with spaces.
- If a context document cannot be read, ask for a corrected path before going further.

```text
/cross-review claude-opus-5-5
/cross-review openai-codex/gpt-6.1-sol docs/plan.md docs/report.md
/cross-review claude-opus-5-5 - "docs/implementation report.md"
/cross-review openai-codex/gpt-6.1-sol comment !482
/cross-review claude-opus-5-5 comment main docs/plan.md
```

## 2. Resolve the target

- If there is no target, review the current branch against the merge-base with the default branch, plus staged, unstaged, and untracked files.
- If the target is a git ref, review `git diff <ref>...HEAD` plus worktree changes.
- If the target is a GitLab MR, run `glab mr view <n>` for the description, source branch, and target branch, then `git fetch origin <source> <target>`.
- If the target is a GitHub PR, run `gh pr view <n> --json title,body,headRefName,baseRefName,headRefOid`, then `git fetch origin <head> <base>`.
- If the MR/PR has no plan argument, use its description as the spec.

Confirm the refs resolve and the diff is non-empty before spawning anything. If nothing is reviewable, stop and say so.

An MR/PR target is someone else's code: never check it out and never edit it. Comment mode is the default for it; without `comment`, give the full report and still make no changes.

## 3. Launch the reviewer model

Use exactly the reviewer model from step 1.

- If the model is a Claude model and `claude_agent_spawn` is available (Pi), spawn it with `model` set to that model, `working_dir` set to the repo root, and `reasoning_effort: high`.
- Otherwise, run Pi headless in the background:
  `pi -p --no-session --model <reviewer-model> --thinking high --tools read,bash @<brief-file> "Perform the review described in the attached brief."`
- If the model is the same as the one running this session, warn that the review is no longer independent and ask the user to confirm or pick another model.
- If the model cannot be launched, stop and ask the user for another model. Never substitute a model on your own.

Report which model reviewed in the final output.

## 4. Build the brief and run the review

1. Read [references/reviewer-brief.md](references/reviewer-brief.md) and copy it verbatim as the start of the brief.
2. Append a `## Target` section with the exact diff command, commit list, MR/PR head SHA if any, and the list of untracked files to read directly.
3. Append the repo's standards sources: `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, `CODING_STANDARDS.md`, lint configs, and any other file that documents how code is written here. List paths only; the reviewer reads them.
4. Append each supplied document's resolved path and full contents under `## Implementation Plan`, `## Post-Implementation Report`, or `## Spec (MR/PR description)`. Omit headings for documents not supplied.
5. Write the brief to a temp file and launch the reviewer as described in step 3.

The reviewer cannot see this conversation, so everything it needs must be in the brief.

## 5. Verify the findings

Do not forward the reviewer's output mechanically. For each finding, check it against the diff and the surrounding code, then mark it:

- **accept**: real, and worth acting on in this change.
- **reject**: wrong, speculative, or pure taste. Note why in one line.
- **escalate**: needs a product, API, or scope decision from the user.

Merge duplicates and keep the reviewer's severity unless verification changes it.

## 6. Act on accepted findings

**If comment mode is on**, make no changes and run no further rounds. Output only the accepted findings in the format below, ready to paste. Order them Critical, Required, Consider, Nit. Drop Nits when there are more than three. End with one overall summary comment for the MR/PR.

````markdown
**`src/cart/CartService.php:88`**

Required: `applyDiscount()` reads `$cart->total` before `recalculate()` runs, so a coupon added in the same request applies to the stale total. Moving the call below `recalculate()` on line 91 fixes it, and a test adding a coupon and an item in one request would catch a regression.
````

- Write each comment to the code, not the author, in plain direct sentences.
- Say what is wrong, why it matters, and the smallest fix.
- If the fix is an exact small replacement, add a `suggestion` block (GitHub: ```` ```suggestion ````, GitLab: ```` ```suggestion:-0+0 ````).

**Otherwise, for this session's own changes**, send accepted Critical and Required findings to one worker subagent to fix. Then run a fresh review limited to the fixes and the code they touch. Stop after three review rounds, or earlier when no Critical or Required finding remains. Do not spend a round on Consider or Nit items; list them for the user instead.

## 7. Report

For non-comment mode, end with:

- the reviewer model and number of rounds;
- the reviewer's verdict, after your verification;
- findings fixed, rejected (with reason), escalated, and left as Consider or Nit;
- checks the reviewer or worker ran, with outcomes;
- manual smoke checks the user should still do.

## Gotchas

- The old `review-with-claude` hardcoded Claude, so a review run from Claude Code was Claude reviewing Claude. That is why the reviewer model is a required argument and is never guessed.
- `git diff` omits untracked files. List them explicitly in the brief, or new files go unreviewed.
- An MR/PR head is not checked out. The reviewer must read changed files with `git show <head-sha>:<path>`, not from the working tree, or it reviews the wrong version.
- The plan and report describe intent and claims. They are not proof. The brief already tells the reviewer to verify claims; do not soften that.
- A false positive pasted into someone's MR costs trust. Comment mode needs step 5 more than any other mode.
- Pi in `-p` mode can run for many minutes. Run it in the background and wait for it to exit; a foreground call times out.
