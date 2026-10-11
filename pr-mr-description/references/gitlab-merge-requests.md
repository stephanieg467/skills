# GitLab Merge Requests

Use the `glab` CLI. Check it with `command -v glab`. If a command fails with an auth error, tell the user to run `! glab auth login`.

## Find the merge request

- By ID: `glab mr view <id> -F json`
- For the current branch: `glab mr view -F json`

The JSON has `iid`, `web_url`, `title`, `target_branch`, and `description`. Use `origin/<target_branch>` as the target branch when none was given.

## Update the description

```bash
glab mr update <id> --description-file <temp_file>
```

Do not pass `--description -`; it opens an editor instead of reading stdin. If an older `glab` rejects `--description-file`, use `description="$(cat "$temp_file")" && glab mr update <id> --description "$description"`.

## Create a merge request

Only after the user confirms. Push the branch first with `git push -u origin HEAD`.

```bash
glab mr create --target-branch <target_branch_without_origin> --title "<title>" --description-file <temp_file>
```

## Linking tickets

- `Closes #123` closes the issue when the MR merges into the default branch.
- Use `group/project#123` for an issue in another project, and `!123` for a merge request.
- Write Jira keys such as `ACRO-482` as plain text; GitLab links them only if the Jira integration is enabled.
