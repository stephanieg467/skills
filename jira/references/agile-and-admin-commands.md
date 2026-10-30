# Boards, sprints, projects, filters, and fields

All commands start with `acli jira`. Run any command with `--help` for full flags. Mutations here follow the write loop in SKILL.md.

## Boards

| Task | Command |
|---|---|
| Find boards | `board search --project ABC --type scrum --json` |
| View a board | `board view --id <board-id> --json` |
| List sprints | `board list-sprints --id <board-id> --state active,future --json` |
| Projects on a board | `board list-projects --id <board-id> --json` |
| Create a board | `board create --name '<n>' --type scrum --filter-id <id> --location-type project --project ABC --json` |
| Delete boards | `board delete --id <id>[,<id>] --yes` |

A board needs an existing filter, and acli cannot create filters.

## Sprints

| Task | Command |
|---|---|
| Tickets in a sprint | `sprint list-workitems --sprint <sprint-id> --board <board-id> --json` |
| View a sprint | `sprint view --id <sprint-id> --json` |
| Create a sprint | `sprint create --name '<n>' --board <board-id> --start 2026-11-02 --end 2026-11-16 --goal '<g>' --json` |
| Start or close a sprint | `sprint update --id <sprint-id> --state active --json` (or `closed`) |
| Delete sprints | `sprint delete --id <id>[,<id>] --yes` |

To find the current sprint: `board search --project ABC` gives the board ID, then `board list-sprints --id <board-id> --state active` gives the sprint ID. `sprint list-workitems` needs both IDs.

acli cannot move a ticket into a sprint. Closing a sprint with open tickets follows Jira's server rules, which acli does not let you choose.

## Projects

| Task | Command |
|---|---|
| List projects | `project list --json` (default 30; add `--paginate` for all) |
| View a project | `project view --key ABC --json` |
| Create from a template project | `project create --from-project ABC --key XYZ --name '<n>'` |
| Update | `project update --project-key ABC --name '<n>'` |
| Archive or restore | `project archive --key ABC`, `project restore --key ABC` |
| Delete | `project delete --key ABC` |

`--from-project` works only with a company-managed source project. For other options, use `project create --generate-json`.

## Filters and dashboards

| Task | Command |
|---|---|
| My or favourite filters | `filter list --my --json`, `filter list --favourite --json` |
| Search filters | `filter search --name '<part>' --json` |
| View a filter | `filter view --id <id> --json` |
| Run a filter | `workitem search --filter <id> --json` |
| Update a filter | `filter update --id <id> --jql '<jql>' --json` |
| Change owner | `filter change-owner --id <id> --owner <email>` |
| Favourite | `filter add-favourite --filter-id <id>` |
| Search dashboards | `dashboard search --name '<part>' --json` |

`filter update --share-permissions` and `--edit-permissions` change who can see or edit the filter. Show the user the JSON before applying it.

## Custom-field definitions

`field create`, `field update`, `field delete` (moves to trash), and `field restore` manage field definitions for the whole site. They do not set a field's value on a ticket. These are site-admin changes; confirm before any of them.
