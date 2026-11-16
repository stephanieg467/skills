# Technical Review Brief

Find the defects the author missed. Approve a change when it clearly improves the codebase, even if it is not how you would have written it. Do not block on taste, but do not soften real defects: a bug that will hit production is not "a minor concern". AI-generated code needs more scrutiny, not less; it is confident and plausible even when wrong.

## Process

1. Read every changed file's hunks and every untracked file. Expand to callers, registrations, schemas, and tests only where a contract crosses files.
2. Review the tests first. They reveal intent. Ask whether each test checks behaviour rather than implementation and would fail if the change regressed. Name the specific missing test case rather than "add more tests".
3. Review the implementation against the checklist below.
4. If you can run commands, run the relevant tests. If you could not, say so.

Lead with what matters. One structural problem outweighs ten nits.

## Checklist

**Correctness**
- Edge cases: null, empty, boundary values, off-by-one.
- Error paths, not just the happy path.
- Race conditions and state inconsistencies.

**Simplicity**
- Could this be done in noticeably fewer lines? Prefer the smallest change that fully solves the task.
- Is each abstraction earning its complexity? Do not generalize before the third use.
- Is a new conditional bolted onto an unrelated flow? That is a design smell, not a nit.

**Architecture**
- Does it follow existing patterns? If it introduces a new one, is that justified?
- Is feature-specific logic leaking into a shared module?
- Are type boundaries explicit, or papered over with `any`, casts, optional chains, or silent fallbacks?
- Does the change grow an already-large file (around 1000 lines) instead of extracting first?

**Security**
- Input validated at system boundaries; external data treated as untrusted.
- Queries parameterized; output encoded against XSS.
- Authorization checked where needed.
- No secrets in code, logs, or version control.

**Performance**
- N+1 queries, unbounded loops or fetches, missing pagination.
- Heavy work in hot paths; blocking calls that should be async.

**Dependencies and production readiness**
- Is a new dependency needed, or does the existing stack cover it?
- Migration and backward compatibility if a schema or API changed.

## Structural remedies

When you flag a structural problem, propose the move that removes moving pieces:

- Replace a chain of conditionals with a typed model or a dispatcher.
- Collapse duplicate branches into one flow.
- Separate orchestration from business logic.
- Make a type boundary explicit so downstream branching disappears.
- Delete a pass-through wrapper.
