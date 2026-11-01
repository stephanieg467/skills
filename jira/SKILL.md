---
name: jira
description: Reads and changes Jira Cloud tickets with Atlassian's `acli` CLI. Use whenever the user mentions Jira, a ticket or issue key like ABC-123, a backlog, sprint, board, epic, story, bug, or JQL, including requests to look up, search, list, create, file, log, update, assign, comment on, move, transition, close, link, or clone tickets, phrasings like "what's on my plate", "what's in the current sprint", "open a bug for this", or "mark ABC-482 done", and invocations like `/jira ABC-482`.
argument-hint: "[ticket-key or request]"
---

# Jira

Work with Jira Cloud through `acli jira`. Jira tickets are called **work items** in every command name. All commands below start with `acli jira`.

## 1. Check the connection

1. Run `acli jira auth status`. It shows the active site and account. If `acli` is not found, point the user to https://developer.atlassian.com/cloud/acli/guides/install-acli/ and stop.
2. If it is not authenticated, stop and ask the user to run `! acli jira auth login --web` themselves. Never handle an API token in the chat or in a command you run.
3. Before the first write, confirm that the active site is the one the user means. If it is not, ask before running `acli jira auth switch --site <site>`, because switching changes the target of every later command.

## 2. Read

| Task | Command |
|---|---|
| Search | `workitem search --jql '<jql>' --fields 'key,summary,status,assignee' --limit 20 --json` |
| Count matches | `workitem search --jql '<jql>' --count` |
| View one ticket | `workitem view KEY --fields '*navigable' --json` |
| Comments | `workitem comment list --key KEY --json` |
| Links | `workitem link list --key KEY --json` |
| Attachments | `workitem attachment list --key KEY --json` |
| Watchers | `workitem list-watchers --key KEY --json` |
| Projects | `project list --recent --json` |

Useful JQL:

- My open work: `assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC`
- Current sprint: `project = ABC AND sprint in openSprints()`
- Recently changed: `project = ABC AND updated >= -7d ORDER BY updated DESC`
- Children of an epic: `parent = ABC-100`
- Text search: `project = ABC AND text ~ "login timeout"`

Summarize results for the user as a short table or list of key, summary, status, and assignee. Do not dump raw JSON.

If a search hits `--limit`, say that more results exist. Use `--paginate` only when the user wants everything.

## 3. Write

Every write follows the same loop:

1. Read the current state of each target ticket with `workitem view`.
2. Show the user the exact change and the ticket keys it touches, then wait for approval. A direct instruction like "assign ABC-482 to me" counts as approval for that one change.
3. Run the command. After approval, pass `--yes` where the command supports it, because an unanswered prompt hangs the run.
4. Read the ticket again and confirm the change landed. Report the key and its URL (`https://<site>/browse/KEY`).
5. If a write fails or times out, read the ticket before offering a retry. Never retry a create, comment, or clone automatically, because the first attempt may have succeeded.

| Task | Command |
|---|---|
| Create | `workitem create --project ABC --type Task --summary '<summary>' --description-file <file> --label a,b --assignee @me --json` |
| Create a sub-task or child | Add `--parent ABC-100` to the create command. |
| Edit fields | `workitem edit --key KEY --summary '<s>' --labels a,b --remove-labels c --yes --json` |
| Assign | `workitem assign --key KEY --assignee <email \| @me \| default> --yes --json` |
| Unassign | `workitem assign --key KEY --remove-assignee --yes --json` |
| Change status | `workitem transition --key KEY --status 'In Progress' --yes --json` |
| Comment | `workitem comment create --key KEY --body-file <file> --json` |
| Edit or delete a comment | `workitem comment update --key KEY --id <comment-id> --body-file <file>`, `workitem comment delete --key KEY --id <comment-id>` |
| Link | `workitem link create --out ABC-1 --in ABC-2 --type Blocks --yes` |
| Clone | `workitem clone --key KEY --to-project XYZ --yes --json` |
| Unarchive | `workitem unarchive --key KEY --yes --json` |
| Remove a watcher | `workitem watcher remove --key KEY --user <account-id>` |

Write descriptions and comments longer than one line to a file under `$HOME/.cache/jira-skill/` and pass it with `--description-file` or `--body-file`. This avoids shell quoting bugs. Remove the file afterwards. Plain text is the default; use ADF only when the user needs rich formatting.

Discover link type names with `workitem link type --json`, and comment visibility roles with `workitem comment visibility --role --project ABC`.

### Broad and destructive changes

Treat these as explicit user decisions, never as incidental steps:

- Any write selected by `--jql` or `--filter`. Run the same JQL with `--count` first and show the number and a sample of keys.
- `workitem delete`. Offer `workitem archive` as the reversible alternative.
- Deleting comments, links, attachments, boards, sprints, projects, or custom fields.
- Cloning to another site with `--to-site`.
- Changing filter sharing or ownership.

## 4. Less common tasks

- For bulk creation, multi-link input, or custom fields on create, read [references/json-input.md](references/json-input.md).
- For boards, sprints, projects, filters, dashboards, and custom-field definitions, read [references/agile-and-admin-commands.md](references/agile-and-admin-commands.md).

For exact syntax of any command, run it with `--help`. The installed binary is the source of truth; the published docs lag behind it.

## What acli cannot do

`acli jira` has no command for the tasks below. If the user asks for one, say so plainly and offer the Jira web UI (`workitem view KEY --web` opens the ticket). Do not invent an `acli` command and do not fall back to the REST API or a browser on your own.

- Upload or download attachments.
- Add a watcher (removing one is possible).
- Log work or edit time tracking.
- Move a ticket into a sprint or the backlog, or change its rank.
- Edit priority, due date, components, fix versions, estimates, parent, or custom field values on an existing ticket.
- List valid transitions, issue types, or fields.
- Create or delete filters, or manage dashboards, versions, components, workflows, or schemes.
- Anything on Jira Server or Data Center.

## Gotchas

- `workitem view` takes the key as a positional argument (`workitem view ABC-1`), while most other commands use `--key`.
- `workitem create` uses `--label`, but `workitem edit` uses `--labels`. They are not interchangeable.
- `--key` accepts a comma-separated list, so one command can change several tickets. Count them before you run it.
- `--json` exists only on some commands, and `--yes` only on some. Check the tables above or `--help`; neither flag is global.
- `workitem create --from-file` reads a summary and description as text, not JSON. Use `--from-json` for JSON.
- `--status` takes the target status name, not a transition name, and the name must exist in that project's workflow. If it fails, view the ticket and ask the user which status they mean.
- A transition can fail because the workflow requires fields acli cannot set. Report the error and point the user to the web UI.
- Never pass `--ignore-errors`. A partial failure in a bulk write is a signal to stop and report, because a half-applied change is hard to audit.
- `watcher remove --user` takes an account ID, not an email. Get it from `workitem list-watchers --key KEY --json`.
- `--type` is case-sensitive and must be an issue type that exists in the project.
- `--editor` and commands without `--yes` can open interactive prompts that hang a non-interactive run. Never pass `--editor`.
- Comment examples in acli's own help omit `create` and use `--issue`. The real command is `workitem comment create --key`.
- Do not use the deprecated `board get`, `filter get`, `filter get-columns`, `field cancel-delete`, or `workitem watcher list`; they are removed on 2026-12-01. Use `board view`, `filter view`, `filter list-columns`, `field restore`, and `workitem list-watchers`.
- A valid login can still fail with a site-admin authorization error after an acli upgrade, because each site admin must reauthorize new OAuth scopes. Tell the user; it is not fixable from the CLI.
