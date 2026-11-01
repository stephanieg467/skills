# JSON input for acli jira

Each command has its own schema. Generate the template for the exact command first and adapt it; do not reuse one command's shape for another.

```sh
acli jira workitem create --generate-json        # single create
acli jira workitem create-bulk --generate-json   # bulk create
acli jira workitem edit --generate-json          # edit
acli jira workitem link create --generate-json   # bulk links
```

`--generate-json` prints to stdout. Redirect it to a file under `$HOME/.cache/jira-skill/` when you need one.

## Single create with custom fields

Use `workitem create --from-json <file> --json`. Custom field values go in `additionalAttributes`. Find the field ID by viewing an existing ticket in the project with `workitem view KEY --fields '*all' --json`.

```json
{
  "projectKey": "ABC",
  "type": "Task",
  "summary": "Investigate login failure",
  "description": {
    "type": "doc",
    "version": 1,
    "content": [
      {"type": "paragraph", "content": [{"type": "text", "text": "Reproduction steps"}]}
    ]
  },
  "labels": ["triage"],
  "assignee": "user@example.com",
  "parentIssueId": "ABC-100",
  "additionalAttributes": {"customfield_10001": 50}
}
```

`description` is ADF here, not plain text.

## Bulk create

Use `workitem create-bulk --from-json <file> --yes`. The top level is an object with an `issues` array, and the keys differ from single create: `issueType`, not `type`, and `label`, not `labels`.

```json
{
  "issues": [
    {
      "summary": "Investigate login failure",
      "projectKey": "ABC",
      "issueType": "Bug",
      "label": ["triage"],
      "assignee": "user@example.com"
    }
  ]
}
```

For plain tickets without custom fields, `workitem create-bulk --from-csv <file> --yes` is simpler. Its columns are `summary, projectKey, issueType, description, label, parentIssueId, assignee`.

1. Create one ticket from the file first and verify it with `workitem view`.
2. Then run the rest. Bulk create has no JSON output, so verify with `workitem search --jql 'project = ABC AND created >= -10m' --json`.

## Edit

`workitem edit --from-json <file> --yes --json` accepts `issues`, `summary`, `type`, `assignee`, ADF `description`, `labelsToAdd`, and `labelsToRemove`. It does not accept `additionalAttributes`, `reporter`, or `parentIssueId`.

## Bulk links

`workitem link create --from-json <file> --yes` takes a bare array:

```json
[{"outwardIssue": "ABC-123", "inwardIssue": "ABC-456", "type": "Blocks"}]
```

## ADF

Use ADF only for rich formatting such as headings, lists, code blocks, or mentions. A `--description-file` or `--body-file` holding ADF must contain a single `{"type": "doc", "version": 1, "content": [...]}` object. For comments with ADF, `workitem comment update` takes `--body-adf`.
