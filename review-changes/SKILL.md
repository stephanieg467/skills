---
name: review-changes
description: Reviews uncommitted worktree changes—or the latest commit when the worktree is clean—for bugs, security issues, and standards compliance, then writes a report. Use as a pre-commit or post-commit quality gate.
---

# Code Review

Perform a technical code review of uncommitted worktree changes, falling back to the latest commit when the worktree is clean.

## Core Principles

Review Philosophy:

- Simplicity is the ultimate sophistication - every line should justify its existence
- Code is read far more often than it's written - optimize for readability
- The best code is often the code you don't write
- Elegance emerges from clarity of intent and economy of expression
- Focus findings on real bugs, security risks, performance problems, and standards violations—not subjective style

## Select the Review Scope

Start with status and summaries; do not emit a full unbounded diff into the model context.

```bash
git status --short
```

### Uncommitted Worktree Scope

If `git status --short` has any output, review only the worktree changes. Include staged files, unstaged files, deletions, and untracked files. Gather the shape of the change first:

```bash
git diff --stat HEAD
git diff --name-status HEAD
git diff --numstat HEAD
git ls-files --others --exclude-standard
```

Then inspect bounded diff context by relevant file or file cluster, expanding where needed:

```bash
git diff --find-renames --unified=40 HEAD -- <paths>
```

### Latest Commit Scope

If `git status --short` has no output, review the latest commit instead. Gather its metadata and shape first:

```bash
git rev-parse --verify HEAD
git show --format=fuller --no-patch HEAD
git show --stat --format= HEAD
git show --numstat --format= HEAD
git diff-tree --root --no-commit-id --name-status -r -M HEAD
```

Then inspect bounded diff context by relevant file or file cluster:

```bash
git show --format= --find-renames --unified=40 HEAD -- <paths>
```

The `--root` flag ensures the initial commit can also be reviewed. If the repository has no commits, report that there are no changes to review and stop.

Do not combine scopes: worktree changes take precedence, and the latest commit is only the clean-worktree fallback.

## Gather Relevant Context Efficiently

Every changed file must receive primary review coverage, including untracked files and removed content from deletions. Use the diff/search first to identify affected symbols, contracts, callers, tests, and project rules, then read targeted symbols or line ranges. Read a complete file when it is small or when full context is needed to understand a lifecycle, contract, callers, or interactions. Never truncate a function, type, or contract merely to satisfy a range limit.

For deleted files, inspect removed content from the relevant base revision (`HEAD` in worktree scope or `HEAD^` in latest-commit scope, when available). For untracked files, inspect their contents directly because they do not appear in `git diff HEAD`.

Read `AGENTS.md` and relevant portions of `README.md`, documented standards, `.agent/references/`, and core modules only when they govern or clarify the diff. Avoid broad docs or core-module scans unrelated to the changed behavior.

For broad reviews, delegate non-overlapping changed-file clusters to fresh review subagents. Assign every changed file exactly once for primary coverage, including deleted and untracked files, and require concise reports with `file:line` evidence. The parent must not duplicate every child read; it verifies actionable or high-impact findings and any load-bearing context needed to accept or reject them.

Bound each model-facing tool-result batch by expected output—roughly 20–30K new tokens. Split large diffs, searches, and reads by file cluster; use targeted follow-up reads. At settled boundaries (scope inventory, cluster review, verification), summarize coverage, findings, and unresolved claims so compaction can run safely.

## Review Each Changed File

For every assigned file, analyze the changed behavior and relevant surrounding context for:

1. **Logic Errors**
   - Off-by-one errors
   - Incorrect conditionals
   - Missing error handling
   - Race conditions

2. **Security Issues**
   - SQL injection vulnerabilities
   - XSS vulnerabilities
   - Insecure data handling
   - Exposed secrets or API keys

3. **Performance Problems**
   - N+1 queries
   - Inefficient algorithms
   - Memory leaks
   - Unnecessary computations

4. **Code Quality**
   - Violations of DRY principle
   - Overly complex functions
   - Poor naming
   - Missing type hints/annotations

5. **Adherence to Codebase Standards and Existing Patterns**
   - Relevant standards documented in the repository
   - Linting, typing, and formatting standards
   - Logging standards
   - Testing standards

Also inspect cross-file interactions where the diff changes a contract, registration path, lifecycle, schema, or caller/callee relationship. Complete changed-file coverage does not mean reviewing files in isolation.

## Verify Issues Are Real

- Verify actionable and high-impact findings against the relevant surrounding code
- Run focused tests for issues found when practical
- Confirm type errors are legitimate
- Validate security concerns with context
- Do not report speculative issues without a concrete failure mode

## Output Format

Save a new file to `.agent/code-reviews/[appropriate-name].md`

**Stats:**

- Files Modified: 0
- Files Added: 0
- Files Deleted: 0
- New lines: 0
- Deleted lines: 0

**For each issue found:**

```
severity: critical|high|medium|low
file: path/to/file.py
line: 42
issue: [one-line description]
detail: [explanation of why this is a problem]
suggestion: [how to fix it]
```

If no issues found: "Code review passed. No technical issues detected."

## Important

- Be specific (line numbers, not vague complaints)
- Focus on real bugs, not style
- Suggest fixes, don't just complain
- Flag security issues as CRITICAL
