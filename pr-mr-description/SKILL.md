---
name: pr-mr-description
description: Writes a pull request (GitHub) or merge request (GitLab) description from the current branch's diff and applies it with the gh or glab CLI. Use whenever the user asks to write, generate, draft, update, fill in, or improve a PR or MR description, body, or summary, including phrasings like "describe this PR", "update the MR description", "write up my changes for review", or invocations like `/pr-mr-description gitlab 123`.
argument-hint: "[github|gitlab] [pr-or-mr-id] [target-branch]"
---

# PR/MR Description

Write a description that tells a reviewer why the change exists and what shape it takes, then put it on the pull request (GitHub) or merge request (GitLab).

## 1. Resolve the inputs

Treat arguments as authoritative and do not ask the user to confirm them. Arguments are positional: `<platform> <id> [target-branch]`, for example `/pr-mr-description gitlab 123 origin/develop`.

- **Platform:** Normalize `gh` to `github` and `glab` to `gitlab`. If no platform is given, infer it from `git remote get-url origin`.
- **ID:** If no ID is given, look up the PR/MR for the current branch.
- **Target branch:** If none is given, use the PR/MR's target branch. If there is no PR/MR yet, use `origin/main`.

Then read the platform reference. It has the commands for every later step.

- For GitHub, read [references/github-pull-requests.md](references/github-pull-requests.md).
- For GitLab, read [references/gitlab-merge-requests.md](references/gitlab-merge-requests.md).

Ask a follow-up only when the platform cannot be inferred. If no PR/MR exists for the branch, ask whether to create one before doing so.

## 2. Gather context

1. Fetch the target branch so the diff is not stale: `git fetch origin <branch>`.
2. Read the commits: `git log --oneline <target_branch>..HEAD`.
3. Read the full diff: `git diff <target_branch>...HEAD`.
4. Read enough surrounding code to explain behavior, not just lines changed.
5. Read the existing PR/MR description, if any.
6. Look for a ticket ID in the branch name, commit messages, and existing description.

## 3. Write the description

Fill in [assets/description-template.md](assets/description-template.md). It is a sensible default; drop optional sections that do not apply.

If the change alters a structure a reviewer must hold in their head (a schema, API contract, type, file layout, component tree, or call flow), read [references/change-outline-views.md](references/change-outline-views.md) and add one to three views under **Changes**.

Write as one person talking to another: plain, concise, and specific to this diff.

### How to Test

Write the manual checks a reviewer performs in the running app to see the change work. Leave out linting, static analysis, builds, and automated test commands: CI already runs them, so they give the reviewer nothing to do.

Each step says where to be (page, viewport, user role, config), what to do, and what should happen. Beyond the main path, cover the variations the diff affects, such as other viewports, keyboard use, JavaScript disabled, permissions, or something the change removed. For example, from a mega menu change:

```markdown
1. On a desktop viewport (above 1440px), click a top-level item that has children. The mega menu should open and the link should not navigate.
2. Tab to a top-level item and press Space. The mega menu should toggle open and closed.
3. On mobile, open the menu drawer, expand a primary item, and confirm there is no "View All" link in the submenu.
```

For a refactor, give a short smoke check of the flows it touches. Omit the section only when nothing changes that a person can observe, such as a CI-only change.

### Example

Input: a diff adding a `retry` option to `HttpClient.request()`, three commits, branch `ACRO-482-retry-timeouts`.

Output:

```markdown
## Summary

Adds opt-in retries to `HttpClient.request()` so transient timeouts no longer fail checkout.

## Motivation

Payment provider calls occasionally time out under load, and each timeout currently surfaces to the shopper as a failed order.

## Changes

- Added a `retry` option (`attempts`, `backoffMs`) to `HttpClient.request()`.
- Retries only on timeouts and 5xx responses; 4xx responses fail immediately.
- Enabled 3 attempts for `PaymentGateway.charge()`.

## Things to Note

- Retries are off by default, so existing callers are unchanged.

## How to Test

1. Set `PAYMENT_MOCK_TIMEOUT=1` and place an order. Checkout should succeed after a retry instead of showing "Payment failed".
2. Set `PAYMENT_MOCK_STATUS=400` and place an order. It should fail right away, with a single request in the payment log.

## Related Tickets

Closes ACRO-482
```

## 4. Apply the description

1. Save the Markdown to a temporary file.
2. Verify the CLI is available and update the PR/MR with the command from the platform reference.
3. If the update succeeds, reply with one line naming the platform, the PR/MR number, and its URL.
4. If the update fails, report the CLI error and give the Markdown as a manual fallback.
5. Remove the temporary file.

If the user asks only for the text, skip this step and output only the raw Markdown: no intro sentence, no code fence, no closing remark. The output starts with `## Summary` so it can be pasted straight into GitHub or GitLab.

## Gotchas

- Do not add leading or trailing horizontal rules (`---`); they can be mistaken for YAML front matter.
- Do not invent ticket IDs. If none is found, omit **Related Tickets**.
- Do not write a file-by-file changelog. Group changes by behavior.
- Do not describe uncommitted changes; they are not in the PR/MR. Mention them to the user if `git status` shows any.
- Keep screenshots, links, and checklists a human added to the existing description.
- Do not print the generated Markdown after a successful CLI update.
