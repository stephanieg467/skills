# Worker brief

Fill this in for every delegated task. Only the task number, the Done criteria, and the Lessons list change between briefs.

```markdown
Repo: <path>   Branch: <branch>
Plan: <plan-path>. Implement ONLY Task <N>.
Read in the plan: Intent and Scope, Inherited Decisions, Task <N>, and the Implementation Evidence lines it references.
Load before editing: <companion skills>.

Rules:
- Do not commit, stage, stash, reset, or checkout. To see the previous version of a file, run `git show HEAD:<file>`.
- Lint suppressions and `SAFETY:` comments: <policy from Inherited Decisions>.

Done criteria:
- `<task Validate command>` passes.
- `<lint command> <touched files>` is clean.
- Project's linter reports no new issues compared with HEAD.
- No behavior change beyond what the plan asks for.

Lessons from earlier tasks:
- <one general sentence each; "None yet." for the first task>

Report back:
- Files changed.
- Tests added or changed, and what each proves.
- Lint suppressions, each with its reason.
- Deviations from the plan.
- Inputs that used to be accepted and would now be rejected.
- Remaining diagnostics.
- Validate result with pass and fail counts.
```
