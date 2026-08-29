---
name: plan-implementation
description: Creates a decision-complete implementation plan from a tracker ticket or free-form feature request. Inherits approved architecture, gathers targeted codebase evidence, resolves implementation-changing questions, and defines focused validation for one-pass execution.
argument-hint: "[ticket key/URL (fetched from your tracker), or a free-form feature description]"
---

# Plan a New Task

## Feature: $ARGUMENTS

Create an implementation plan, not code. The plan should be decision-complete and usable in one pass while remaining concise. Include only evidence, decisions, tasks, and validation that can change implementation.

## Resolve the Input

`$ARGUMENTS` is either a tracker ticket or a free-form feature description.

- **Tracker ticket:** Fetch it before planning. Read its acceptance criteria and ticket-specific context, then follow relevant links to its epic and approved architecture. Never plan from a bare key.
- **Free-form description:** Plan directly from the description and supplied references.

Reading a remote resource does not authorize editing or publishing it.

## Inherit, Don't Re-decide

Treat approved architecture, accepted ADRs, repository standards, and relevant epic-level decisions as constraints. Plan the ticket-level implementation: affected contracts and files, local patterns, dependency order, tests, and acceptance evidence.

Do not reopen inherited decisions without new evidence or explicit user direction. If the request requires a deviation, surface it as an approval-blocking question rather than silently diverging.

## Workflow

### 1. Establish Intent and Boundaries

Record:

- the problem and required behavior;
- concrete acceptance criteria;
- explicit non-goals and adjacent work that is out of scope;
- inherited architecture and constraints;
- affected systems and contracts.

Do not add generic user stories, metadata, or business analysis unless they clarify implementation.

### 2. Gather Targeted Codebase Evidence

Start with search to locate relevant symbols, callers, tests, configuration, and documentation. Follow with targeted source ranges. Read a full file only when it is small or when its complete lifecycle or contract is necessary.

Investigate only evidence that can affect the implementation approach, including:

- the existing seam or pattern to extend;
- affected caller/callee, schema, persistence, or registration contracts;
- project-specific standards from `AGENTS.md`, `CLAUDE.md`, or equivalent instructions;
- relevant dependency versions and local integration patterns;
- focused test examples and available validation commands.

Link findings to `path:line-line` ranges or named symbols and summarize why each matters. Do not embed large source excerpts or require broad repository reads. The implementer may inspect additional targeted context to verify current code and task sanity.

Use narrowly scoped reconnaissance subagents only when the repository area is too broad for efficient direct inspection. Require concise, source-linked findings and verify load-bearing claims.

### 3. Resolve Implementation-Changing Questions — Gate

After reconnaissance, ask one small numbered cluster of questions only for choices whose answers would change implementation. Typical topics are scope boundaries, competing repository patterns, contract shape, failure behavior, or measurable acceptance behavior.

For each question:

- cite the evidence that created the choice;
- present the material options;
- recommend a default with its trade-off.

Then stop and wait. Do not ask about facts that are discoverable or decisions already settled upstream. If nothing material remains open, say so and proceed.

If the user declines to decide, record the proposed default as an explicit assumption with its impact. Do not finalize a plan while an unresolved product, architecture, security, or scope decision could materially change the work.

### 4. Research Externally Only When Needed

Use external research only when a material implementation fact remains unresolved after checking inherited decisions, repository code, and local documentation. Prefer official primary sources and link the exact relevant section. Omit research that does not change the plan.

### 5. Design the Implementation

Choose the smallest approach consistent with inherited architecture and repository patterns. Address only relevant concerns:

- contract and data-flow changes;
- error, authorization, security, concurrency, and compatibility behavior;
- dependency order and independently executable work;
- critical tests and focused automated checks;
- manual smoke checks that cannot be automated economically.

Make consequential choices and rationale explicit. Avoid speculative extensibility and unrelated refactors.

### 6. Write the Plan

Use the structure below adaptively. Omit empty or irrelevant sections rather than filling them with boilerplate.

```markdown
# <Feature Name>

## Intent and Scope

<Required behavior, user-visible outcome, and explicit non-goals.>

## Acceptance Criteria

<Specific, observable criteria tied to the request.>

## Inherited Decisions

<Approved architecture, ADRs, repository rules, and contracts this work must preserve, with links.>

## Implementation Evidence

- `path/to/file.ts:20-48` (`symbolName`) — <pattern or contract and why it changes the implementation>
- `path/to/test.ts:75-110` — <relevant test pattern>
- [Official documentation section](https://example.com/docs#section) — <material behavior confirmed>

## Approach

<Concise solution shape, affected contracts/data flow, key decisions, and rationale.>

## Changes

### 1. <Dependency-ordered change>

- **Files:** <files to create, update, or remove>
- **Change:** <concrete behavior and contract details>
- **Pattern:** <targeted source reference to follow>
- **Constraints:** <gotchas, compatibility, security, or error behavior when relevant>
- **Acceptance:** <criteria advanced by this change>

### 2. <Next change>

- **Depends on:** <only when dependency is not obvious>
- **Files:** <paths>
- **Change:** <concrete behavior>
- **Acceptance:** <criteria advanced>

## Validation

### Focused Automated Checks

- `<targeted command>` — <behavior or affected surface it validates>

### Manual Smoke Checks

- <user-visible or environment-dependent check that remains manual>

## Assumptions and Deferred Items

<Explicit non-blocking assumptions, excluded follow-ups, and resolution triggers. Omit when empty.>
```

Tasks must be concrete enough to execute without reopening settled decisions. Group tightly related edits when that is clearer than artificial file-by-file or independently testable tasks. Include dependency ordering only where it affects execution.

Validation should match the change's risk and repository conventions. Prefer targeted tests, linting, type checks, builds, or static checks for affected surfaces. Do not require broad suites by default. Clearly distinguish automated commands from manual smoke checks, and never imply that a manual check was automated.

## Output

Default filename:

`.claude/plans/{kebab-case-descriptive-name}.md`

Follow an existing plan location when the repository defines one. Do not overwrite an existing plan without confirmation. Plan files are working artifacts; do not commit them unless explicitly authorized.

Before writing, verify that:

- implementation-changing decisions are resolved or explicitly approved assumptions;
- inherited architecture and repository standards remain intact;
- tasks are concrete, scoped, and dependency-aware;
- evidence links target the relevant source ranges or symbols;
- acceptance criteria are observable and mapped to the planned changes;
- automated checks are focused, and remaining manual smoke checks are separate;
- the plan does not require unrelated refactoring or broad reading.

After writing, report the plan path, approach, key risks or assumptions, and the manual smoke checks the implementer should report to the user. The implementer should still verify targeted source context and commands against the current worktree before editing.
