# GitHub Pull Requests

Use the `gh` CLI. Check it with `command -v gh`. If a command fails with an auth error, tell the user to run `! gh auth login`.

## Find the pull request

- By ID: `gh pr view <id> --json number,url,title,baseRefName,body`
- For the current branch: `gh pr view --json number,url,title,baseRefName,body`

Use `origin/<baseRefName>` as the target branch when none was given.

## Update the description

```bash
gh pr edit <id> --body-file <temp_file>
```

## Create a pull request

Only after the user confirms. Push the branch first with `git push -u origin HEAD`.

```bash
gh pr create --base <target_branch_without_origin> --title "<title>" --body-file <temp_file>
```

## Linking tickets

- `Closes #123` closes the issue when the PR merges into the default branch.
- Use `owner/repo#123` for an issue in another repository.
- Write Jira keys such as `ACRO-482` as plain text; GitHub links them only if the repository has autolinks configured.
