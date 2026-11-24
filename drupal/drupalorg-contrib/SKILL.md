---
name: drupalorg-contrib
description: File and search Drupal.org contrib project issues and merge requests on git.drupalcode.org with `glab`. Use this whenever the user wants to search a Drupal.org issue queue (for duplicates of a local patch, existing fixes, or related bugs), create an upstream issue, contribute a patch upstream, or open a merge request against a Drupal contrib module (e.g. canvas, webform, pathauto).
disable-model-invocation: true
---

# Drupal.org contrib: search, issue, and MR workflow

Everything goes through `glab` against git.drupalcode.org. The non-obvious parts — and
the reason this skill exists — are that drupalcode **blocks personal forks**, uses
**shared issue forks** created by a bot command, and that some projects still use the legacy drupal.org issue queue where none of this applies.

## Prerequisites

```bash
glab --version
glab auth status --hostname git.drupalcode.org
```

If not authenticated, stop and tell the user to run
`glab auth login --hostname git.drupalcode.org` with a personal access token that has
`api` scope (users log in to git.drupalcode.org with their drupal.org account via SSO).

Pass `--hostname git.drupalcode.org` to every `glab api` call and
`--repo git.drupalcode.org/project/PROJECT` to every subcommand; never rely on the
current directory. `PROJECT_PATH` below is URL-encoded, e.g. `project%2Fcanvas`.

## Step 0: Legacy queue or GitLab work items?

Check where the project's issues live before doing anything:

```bash
curl -s -o /dev/null -w "%{http_code} %{redirect_url}\n" "https://www.drupal.org/project/issues/PROJECT"
```

- **301 to `git.drupalcode.org/.../work_items`** → migrated project. The full API
  workflow below applies.
- **200 (stays on drupal.org)** → legacy queue. Issues are drupal.org nodes; they
  cannot be created via the GitLab API. Search with WebFetch/WebSearch on
  drupal.org, and direct the user to create the issue in the drupal.org web UI.
  Issue forks for legacy issues are created from the button on the drupal.org
  issue page, not via `/do:fork`.

Also check whether the project was **renamed** (e.g. `experience_builder` → `canvas`):
old issues may live under the old project name on drupal.org while new ones are in
the new project's GitLab. Search both when hunting duplicates.

## Searching the issue queue (optional duplicate/prior-art hunting)

Search the Drupal.org issue queue unless the user explicitly says it has already been
searched, provides an existing issue/MR to use, or asks to skip duplicate hunting. In
those cases, acknowledge that prior search context and continue with the requested
issue/MR workflow instead of re-running searches.

When searching is needed, use `glab`, not the work-items UI (a JS SPA that returns an
empty shell to fetchers):

```bash
glab issue list --repo git.drupalcode.org/project/PROJECT --all --search "TERM" -P 50
glab issue view IID --repo git.drupalcode.org/project/PROJECT --comments
```

Search tips that matter in practice:
- Run several distinct phrasings: the reporter's symptom words ("too many redirects",
  "modal does not open"), the class/method name (`redirectCanvasToDefaultLanguage`),
  and the subsystem term. Each surfaces different issues.
- Complement with `WebSearch` restricted to `drupal.org` — it finds issues under old
  project names and in release notes that the GitLab search misses.
- To check whether a fix landed in a release, don't trust issue state alone: fetch the
  actual file at the release tag and compare with the default branch:
  ```bash
  glab api --hostname git.drupalcode.org "/projects/PROJECT_PATH/repository/files/URLENCODED%2FFILE%2FPATH.php/raw?ref=TAG"
  ```
- MR status: `glab mr view IID --repo git.drupalcode.org/project/PROJECT`.
  An MR referenced in composer patches may still be open — worth reporting to the user.

## Before any write

- Confirm the target repo and branch with the user. A PAT is not project-scoped; it
  reaches every repo they can write to.
- Do not @-mention, assign, or add reviewers unless the user asks.
- Run write calls with `-i` and check for `HTTP 201`. A bare 200 means nothing was
  created (see Gotchas).

## Creating an issue

```bash
glab api -i --hostname git.drupalcode.org "/projects/PROJECT_PATH/issues" \
  -f title="..." \
  -f description='### Overview
...'
# response: .iid (the issue number), .web_url
```

Follow Drupal issue conventions in the body — maintainers expect these sections:

```markdown
### Overview
What's wrong, why, and on which version it was confirmed.

### Steps to reproduce
Numbered steps + **Expected** / **Actual**.

### Proposed resolution
What the fix does. Mention alternatives if the approach is debatable
(e.g. "hardcoding a contrib module name here may not be desirable — could
instead be made opt-out-able generically").

### Related issues
- #NNNNNNN (with a word on how each relates)
```

Reference related issues as `#NNNNNNN` — GitLab links them automatically. Note the
API cannot set version/component/priority metadata on drupalcode work items; after
creating, tell the user to add those in the web UI (and set "Needs review" once an
MR exists).

## Creating the issue fork (the part that breaks everyone)

`POST /projects/.../fork` is **blocked** on drupalcode — it 301s to
`drupal.org/git-error`. Do not retry it or try to create projects in the `issue/`
namespace. Instead, comment the DrupalBot command on the issue:

```bash
glab api -i --hostname git.drupalcode.org "/projects/PROJECT_PATH/issues/IID/notes" -f body="/do:fork"
```

DrupalBot creates a **shared fork** at `issue/PROJECT-IID` (e.g. `issue/canvas-3591772`)
within ~10–30 seconds, with push access for whoever posted the command. Poll for it:

```bash
glab api --hostname git.drupalcode.org "/projects/issue%2FPROJECT-IID"
# 404 until ready; then .id, .default_branch
```

The fork contains all upstream branches. It is shared — other contributors may push
to it later; that's by design.

## Committing the change

No local clone needed — use the commits API to create the branch and commit in one
call. Branch naming convention is `{iid}-short-kebab-description`.

Commit messages use Drupal Conventional Commits: `{type}: #{issue-id} Short summary`,
where type is one of `feat`, `fix`, `docs`, `refactor`, `test`, `ci`, `perf`, `task`,
`revert`. Credit contributors with `By:` lines using Drupal.org usernames (not GitLab
names or `@`); ask the user if unsure.

```
fix: #3591772 Skip language-prefix redirect when canvas_multilingual is installed

By: drupal-username
```

To build the file content: download the file from the fork's default branch, apply
the local patch to it (`patch -p1 --dry-run` first), then write the whole patched file
into a JSON body (e.g. with `jq --rawfile` so the content is escaped) and send it:

```json
{
  "branch": "3591772-skip-language-prefix-redirect",
  "start_branch": "1.x",
  "commit_message": "fix: #3591772 Skip language-prefix redirect when ...\n\nBy: drupal-username",
  "actions": [
    {"action": "update", "file_path": "src/...php", "content": "<full file>"}
  ]
}
```

```bash
glab api -i --hostname git.drupalcode.org "/projects/issue%2FPROJECT-IID/repository/commits" \
  --input commit.json
```

`start_branch` is the upstream development branch.

Use `"action": "create"` for new files (e.g. tests). Multiple files go in one
`actions` array — keep it one commit unless there's a reason not to.

Before committing PHP service changes, check whether `*.services.yml` needs updating:
if the module's services file has `_defaults: autowire: true`, constructor-injection
changes need no services.yml edit; otherwise the service definition needs the new
argument listed.

## Opening the merge request

Cross-project MR from the issue fork to upstream:

```bash
glab api --hostname git.drupalcode.org "/projects/PROJECT_PATH"   # upstream .id
glab api -i --hostname git.drupalcode.org "/projects/issue%2FPROJECT-IID/merge_requests" \
  -F target_project_id=UPSTREAM_ID \
  -f source_branch="3591772-skip-language-prefix-redirect" \
  -f target_branch="1.x" \
  -f title="fix: #3591772 Skip language-prefix redirect when canvas_multilingual is installed" \
  -f description='Closes #3591772.

What and why; note anything reviewers should check.' \
  -F allow_collaboration=true
# response: .iid, .web_url
```

The MR title follows the commit format because GitLab squash-merges use it as the
commit message. `allow_collaboration` is the Drupal norm: maintainers push to MR branches.

`target_project_id` is what makes it land on the upstream project instead of the
fork. Target the development branch (`1.x`, `2.x`, `11.x`), never a release tag —
even if the fix was developed against a tagged release. If the file differs between
the tag and the dev branch, re-verify the patch applies to the dev branch first.

## After filing — close the loop

Report the issue and MR URLs plainly, then offer these follow-ups:

- **composer.json**: the MR is consumable as a patch at
  `https://git.drupalcode.org/project/PROJECT/-/merge_requests/IID.patch`. Trade-off
  to surface: the URL's content changes whenever the branch gets new commits, so a
  local patch file is more stable; the MR URL self-documents the upstream thread.
  Either way, put the issue number in the patch description or filename.
- Remind the user to set the issue's version/component and "Needs review" status in
  the web UI.

## Gotchas

- HTTP writes must go to `git.drupalcode.org`. A write sent to `git.drupal.org` is
  redirected and downgraded to a GET: it returns 200 with a list and creates nothing.
- SSH `git push` goes to `git@git.drupal.org:…`, not drupalcode (the drupalcode CDN has
  no SSH listener, so the push hangs).
- `-f field=@file` does not read the file; it sends the literal string `@file`. Pass
  text inline in single quotes, or send a JSON body with `--input`.
- Use `-f` for strings and `-F` for integers and booleans.

## Troubleshooting

- **Fork API returns 301 / drupal.org/git-error** → expected; use `/do:fork`.
- **`issue/PROJECT-IID` 404s after a minute** → check the `/do:fork` note posted
  (`glab issue view IID --repo ... --comments`); the bot only reacts to the bare command as the note body.
- **Empty results scraping work_items pages** → it's a JS SPA; use the API.
- **GitLab project search finds nothing for a contrib module** → the module may not
  be migrated (Step 0), or issues may live under a former project name.
- **Commit API 400 "branch already exists"** → omit `start_branch` and commit to the
  existing branch, or pick the branch up where it is.
