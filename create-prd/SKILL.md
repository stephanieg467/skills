---
name: create-prd
description: >-
  Creates a Product Requirements Document through an evidence-aware,
  domain-aware interview and an explicit approval gate. Use when the user
  wants to define why a product change matters, who it affects, required
  observable behavior, scope, product constraints, assumptions, and open
  questions before architecture or implementation planning.
---

# Create PRD

Create a Product Requirements Document (PRD) by establishing shared understanding before writing. Adapt the depth of the interview to the evidence and decisions already available.

## Contract

A PRD produced by this skill defines:

- why the product change matters;
- affected people and roles;
- required observable product behavior;
- in-scope and out-of-scope behavior;
- relevant product constraints;
- assumptions, unknowns, and unresolved questions.

Keep the PRD at the product-behavior level. Do not include user stories, success metrics, door checks, architecture, APIs, schemas, data models, module boundaries, implementation choices, delivery sequencing, testing strategy, or testing decisions.

Acceptance criteria are required. They describe observable product behavior in plain declarative language; they do not prescribe tests or use `Given/When/Then`.

Never invent missing evidence or silently resolve uncertainty. Never modify domain documentation. Never write the PRD file until the user has approved the mandatory synthesis.

## Workflow

Follow these phases in order:

**ORIENT → LOAD PRODUCT AND DOMAIN CONTEXT → INTERVIEW THE GAPS → SYNTHESIZE → REQUIRE USER APPROVAL → DRAFT → BOUNDARY AUDIT → WRITE → HAND OFF**

Pause whenever user input is needed. Ask a small cluster of related questions, end the turn, and wait for answers rather than continuing through a gate.

### 1. Orient

1. Read the current conversation and all supplied research, product documentation, and reference files.
2. Record what is already known, what is sourced, and what remains unresolved.
3. Do not ask for information already answered by the conversation or supplied evidence.
4. Determine whether this concerns an existing repository and whether the user requested a destination.
5. Derive a tentative initiative name and kebab-case filename slug, but do not create a file yet.

When evidence is cited in the PRD, identify its source with a path, link, document title, or concise source description. Do not present an inference as a sourced fact.

### 2. Load Product and Domain Context

For an existing repository:

1. Look for a repository-root `CONTEXT-MAP.md`.
2. If no context map exists, look for a repository-root `CONTEXT.md`.
3. If a context map exists, use it to load only bounded contexts relevant to the proposed change. Do not read every context by default.
4. Extract canonical terms, their meanings, and any `_Avoid_` synonyms from the relevant context documents.
5. Read relevant product documentation.
6. Inspect code only when necessary to establish existing user-visible behavior. Do not inspect code to design a solution.
7. Read only relevant existing ADRs and treat them as product constraints where applicable, not as invitations to make new architectural decisions.
8. Do not edit `CONTEXT.md`, `CONTEXT-MAP.md`, ADRs, glossaries, or other domain documentation.

If neither `CONTEXT-MAP.md` nor `CONTEXT.md` exists:

- continue without blocking;
- notify the user that no canonical `CONTEXT.md` exists;
- establish the relevant vocabulary during the interview;
- include that vocabulary in the PRD;
- suggest using the future `domain-modeling` skill to create canonical context.

If the user's terminology conflicts with the canonical glossary:

- notify the user of the conflicting terms without stopping the interview;
- preserve the conflict for the shared-understanding synthesis;
- use the canonical term unless the user approves different terminology during synthesis;
- do not update the glossary from this skill.

### 3. Interview the Gaps

Conduct an adaptive interview containing only unresolved, high-impact questions. Ask related questions in small clusters, then stop and wait. Do not mechanically run a fixed questionnaire.

Cover these topics only when the conversation and evidence have not already resolved them:

- affected people and roles;
- observable problem and context;
- current behavior or workaround;
- impact and why the change matters now;
- desired outcomes;
- required product behavior;
- product-level edge cases;
- in-scope and out-of-scope behavior;
- relevant accessibility, compatibility, privacy, reliability, or externally imposed performance constraints;
- domain terminology;
- evidence, assumptions, unknowns, and open questions;
- PRD owner.

Challenge vague or solution-shaped answers with the smallest useful follow-up. Translate proposed technical solutions back into the product behavior or constraint they are intended to satisfy. A shortened interview is appropriate when the conversation and source material are already sufficient.

Use these labels consistently:

- **Evidence:** sourced facts or observations.
- **Assumptions:** working beliefs without adequate supporting evidence.
- **Unknowns:** information that is not currently available.
- **TBD — needs validation:** a requirement or decision that must eventually be resolved.

If the user chooses to proceed with incomplete information, retain unresolved items under the correct label rather than filling the gaps.

### 4. Synthesize

Before drafting or writing any PRD file, present a concise shared-understanding synthesis containing:

- problem and context;
- people and roles;
- desired outcomes;
- proposed product requirements and their proposed Must/Should/Could priorities;
- relevant quality requirements;
- scope and non-goals;
- canonical vocabulary and any terminology conflicts;
- evidence, assumptions, unknowns, and open questions.

Make uncertainty visible. Keep the proposed requirements at the observable product-behavior level. Group them under product capability headings and assign tentative globally unique identifiers (`PR-001`, `PR-002`, and so on) so the user can review scope and priorities.

### 5. Require User Approval

Always ask the user to approve or correct the synthesis. Do not treat the original request to create a PRD as approval of the later synthesis. Do not draft to disk, create the target file, or overwrite an existing file before this approval.

The user may explicitly approve an incomplete PRD. In that case, mark unresolved information as an assumption, unknown, open question, or `TBD — needs validation`, as appropriate.

If the target file already exists, also ask whether to update that file or create a new file. Never overwrite an existing PRD without explicit approval. This file decision may be requested alongside synthesis approval when it is already known.

### 6. Draft

After approval, draft the PRD using the required template below.

#### Product Requirements

Organize requirements under product capability headings while keeping identifiers globally unique and sequential across the document.

Every requirement contains:

- identifier and title;
- priority;
- one observable product requirement;
- plain declarative acceptance criteria.

Use only these priorities:

- **Must:** The intended product change is incomplete without it.
- **Should:** Important, but the product remains useful without it initially.
- **Could:** Valuable and in scope, but optional.

Acceptance criteria describe externally observable states, behavior, permissions, outcomes, or product-level edge cases. Do not describe test cases, test tooling, internal components, storage, APIs, or implementation mechanisms.

Example:

```markdown
#### PR-001 — Revoke an outstanding invitation

**Priority:** Must

A Workspace Administrator can revoke an invitation that has not been accepted.

**Acceptance criteria:**

- Revocation is available only while the invitation is outstanding.
- A revoked invitation can no longer be accepted.
- The administrator can distinguish revoked invitations from outstanding ones.
```

#### Required PRD Template

Use this structure. Use the current date in `YYYY-MM-DD` format for both date fields when creating the document. Omit irrelevant quality subsections rather than leaving them empty.

```markdown
# <Initiative Name>

| Field | Value |
|---|---|
| Status | Draft |
| Owner | <owner or TBD> |
| Created | YYYY-MM-DD |
| Last updated | YYYY-MM-DD |

## Summary

<Concise description of the change and why it matters.>

## Problem and Context

<Observable problem, current context, current behavior or workaround, impact, and why now.>

## People and Roles

<Affected people and relevant product roles.>

## Evidence and Assumptions

### Evidence

- <Sourced fact or observation, with source.>

### Assumptions

- <Working belief that lacks adequate evidence.>

### Unknowns

- <Information that is not currently available.>

## Desired Outcomes

<Product outcomes without prescribing a technical solution.>

## Product Requirements

### <Capability Area>

#### PR-001 — <Requirement title>

**Priority:** Must | Should | Could

<Observable product requirement.>

**Acceptance criteria:**

- <Declarative product behavior.>

## Scope

### In Scope

- <Included product behavior.>

### Out of Scope / Non-goals

- <Excluded product behavior or outcome.>

## Quality Requirements

### <Only a relevant subsection, such as Accessibility, Compatibility, Privacy and Security Outcomes, Reliability, or Externally Imposed Performance Constraints>

- <Product-level constraint or observable outcome.>

## Domain Vocabulary

| Term | Meaning in this PRD | Terminology notes |
|---|---|---|
| <Canonical term> | <Meaning> | <_Avoid_ synonym, conflict, or other note> |

## Open Questions

- [ ] <Question or TBD — needs validation>

## Deferred Decisions

Architecture, APIs, schemas, module boundaries, implementation approach, delivery sequencing, and testing strategy are intentionally deferred to later work.
```

The `Evidence and Assumptions` section is required even when no supporting evidence was supplied. In that case, say that no supporting evidence was supplied under `Evidence`; do not fabricate an entry. If a subsection has no assumptions or unknowns, state `None currently identified.`

The `Open Questions` section is required. If there are no open questions, state `None currently identified.` instead of leaving a placeholder.

### 7. Boundary Audit

Before writing, audit the draft for accidental downstream engineering decisions:

- architecture or technology choices;
- APIs, schemas, or data-model decisions;
- modules, file paths, or project structure;
- implementation sequencing;
- testing strategy or test seams;
- requirements that unnecessarily prescribe a technical solution.

Correct straightforward wording problems automatically by restating the product behavior or constraint. If removing a technical prescription could alter product intent, ask the user rather than guessing and do not write until resolved or explicitly marked `TBD — needs validation` with user approval.

Also verify that every product requirement has a unique identifier, approved priority, observable requirement, and declarative acceptance criteria; vocabulary follows the approved terminology; evidence is sourced; and unresolved information is visibly labeled.

### 8. Write

- Default to `docs/<kebab-case-slug>.prd.md` relative to the repository root or current working directory.
- Honor an explicitly requested destination.
- Create `docs/` only after approval if it does not exist.
- Recheck whether the target exists immediately before writing.
- If it exists and overwrite/update approval has not been given, stop and ask whether to update it or create a new file.
- Never overwrite an existing PRD without explicit approval.
- Write only the approved, boundary-audited PRD.

### 9. Hand Off

After writing:

1. Report the exact file path.
2. Briefly summarize the PRD.
3. Report the number of product requirements and open questions.
4. Mention important assumptions, unknowns, or unresolved terminology.
5. If no canonical domain context exists, repeat that fact and suggest the future `domain-modeling` skill.
6. Recommend moving next to the `decide-architecture` skill without proposing or making architecture decisions.
