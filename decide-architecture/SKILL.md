---
name: decide-architecture
description:
  'Decides the high-level code architecture for an initiative through an
  evidence-backed, dependency-aware conversation and explicit approval gate.
  Use when the user provides an approved PRD, tracker issue or epic, URL,
  free-form idea, or reference documents and wants to decide system shape,
  domain ownership, module responsibilities, seams, interfaces, data flow,
  integration contracts, trust boundaries, or consequential technology choices
  before implementation planning.'
disable-model-invocation: true
---

# Decide Architecture

Decide the high-level code architecture for an initiative by establishing shared understanding before writing. Act as a pragmatic staff architect and decision facilitator: propose rather than dictate.

Optimize for:

- fitness to the stated goals and constraints;
- coherent domain ownership;
- simplicity and evolutionary change;
- operability;
- familiarity with the existing system and team;
- reversibility;
- focused deliberation on consequential decisions.

## Contract

Accept any of these as the initiative input:

- an approved PRD;
- a tracker issue, epic, or URL;
- a free-form idea;
- optional reference documents.

The output is architecture, not product discovery or an implementation plan. It may describe solution shape, system and module responsibilities, domain and data ownership, seams, interfaces, data flow, trust boundaries, and major contracts. It must not produce:

- file-by-file edits or project structure changes;
- task sequences or implementation steps;
- migrations or rollout procedures;
- test commands or testing plans;
- implementation phases.

Architecture-level compatibility and coexistence constraints may be recorded for brownfield work, but their execution belongs in downstream planning.

If product intent is too unclear to support responsible architecture decisions, stop and recommend `create-prd`. Do not silently conduct product discovery here. A responsible input establishes enough of the problem, goals, required product behavior, scope or non-goals, and architecture-driving constraints to judge architectural fitness. Preserve non-blocking product unknowns explicitly; do not fill them in.

The conversation precedes the final document. Never silently converge on consequential decisions, and never write the architecture document before the required synthesis and approval gate.

## Information Ownership

Classify information continuously:

1. **Discoverable facts** — investigate with the repository, supplied references, available integrations, tools, or subagents. Never ask the user for something that can reasonably be discovered.
2. **User-owned decisions** — ask about preferences, priorities, strategic direction, cost tolerance, risk appetite, team familiarity, and undocumented constraints.
3. **Unavailable facts** — label them as unknown, research them, defer them with a resolution trigger, or propose a spike. Never invent them.

Keep evidence attached to the decision it informs. Cite repository paths, document titles, links, commands or tool results, or primary sources as appropriate. Clearly distinguish sourced facts from inferences.

For repository and codebase reconnaissance, use only the `scout` subagent. Other subagent roles must not be used as substitutes for scouting. External research may use a research-specific agent when current external facts are required. Subagents gather facts and evidence; they do not make user-owned architecture decisions. Verify only load-bearing findings directly before relying on them.

## Workflow

Follow these phases in order:

**ORIENT → LOAD INTENT, REFERENCES, DOMAIN DOCUMENTATION, AND EXISTING DECISIONS → CLASSIFY GREENFIELD OR BROWNFIELD → GATHER DISCOVERABLE FACTS → BUILD THE DECISION TREE → WORK THE CURRENT FRONTIER IN SMALL ROUNDS → AUDIT ARCHITECTURE COVERAGE → SYNTHESIZE → REQUIRE USER APPROVAL → WRITE OR PUBLISH APPROVED ARTIFACTS → HAND OFF**

Pause whenever user input or approval is required. Ask a small round of questions, end the turn, and wait rather than continuing through a gate.

### 1. Orient

1. Read the current conversation and every supplied input and reference.
2. When the input is a tracker resource or URL, use an available integration to read it. If it is inaccessible, ask the user for an accessible copy or the minimum missing content.
3. Record known intent, sourced constraints, assumptions, unknowns, and the requested destination, if any.
4. Determine whether the initiative targets a repository or an existing system.
5. Derive a tentative initiative name and kebab-case slug, but do not create the architecture document.
6. Apply the product-intent sufficiency gate from the Contract. If it fails, explain the blocking ambiguity, recommend `create-prd`, and stop.

Reading a Jira, Confluence, or other remote resource grants permission to read only. It does not grant permission to publish, edit, comment, or create tickets.

### 2. Load Intent, References, Domain Documentation, and Existing Decisions

For the relevant repository or system:

1. Read the approved PRD, issue, epic, brief, and supplied references.
2. Look for a repository-root `CONTEXT-MAP.md`. If present, use it to load only the relevant bounded-context `CONTEXT.md` files and understand relationships between contexts.
3. Otherwise, read the relevant root `CONTEXT.md` when present. If no relevant `CONTEXT.md` exists, maintain a small provisional vocabulary in session memory and continue; absence of canonical domain documentation is not a blocker.
4. Read relevant architecture documentation and ADRs. Do not read every ADR indiscriminately; use repository organization, context, and search to find decisions that constrain this initiative.
5. Note canonical terms, `_Avoid_` synonyms, context ownership, inherited architecture, and existing decisions before discussing changes. Keep provisional terms clearly distinct from canonical terms.
6. Inspect available references before asking whether undocumented references or constraints exist.

Treat canonical domain documentation and accepted ADRs as inherited constraints unless the user explicitly reopens them. Do not mistake an old decision for a current fact when the repository shows it has been superseded.

### 3. Classify Greenfield or Brownfield

Infer the mode from the initiative and workspace. Ask only if it remains genuinely unavailable.

#### Brownfield

Use the `scout` subagent for gathering context from repository code and tests.

Launch at most one fresh-context scout with a narrowly scoped task and require a compressed evidence report covering only the architecture-driving surfaces. The parent may directly inspect canonical documentation and perform targeted verification of load-bearing scout findings, but must not repeat the scout's broad reconnaissance.

Scout the relevant codebase surfaces at the architecture level rather than producing a file inventory. Establish:

- current system shape and module seams;
- domain and data ownership;
- major interfaces, contracts, and data flows;
- integration and trust boundaries;
- operational conventions;
- compatibility and coexistence constraints;
- extension points and coupling that affect the initiative.

Read relevant `CONTEXT.md`, `CONTEXT-MAP.md`, and ADRs before proposing deviations. Separate findings into:

- **Inherited decisions** — already established and not reopened;
- **New decisions** — required by this initiative;
- **Proposed deviations** — intentional departures requiring user approval.

Brownfield architecture is inherited by default. Do not reopen it merely because another design appears cleaner or more fashionable.

#### Greenfield

Explore the solution space from the initiative's actual goals and constraints. Use first principles and compare only plausible approaches. Use research agents when a consequential decision depends on current external facts, and prefer primary sources such as official documentation, standards, pricing, limits, or vendor guarantees.

Do not choose fashionable technologies without evidence that they fit the initiative, operational environment, budget, and team familiarity.

### 4. Gather Discoverable Facts

Build a compact evidence ledger before asking architecture questions:

- fact or finding;
- source;
- confidence;
- decisions affected;
- whether direct verification is required.

Investigate facts that can change the option set or recommendation. Do not turn reconnaissance into an exhaustive codebase audit or broad market survey. If an investigation is still running, treat it as an unsettled prerequisite: continue with independent frontier decisions, but do not ask or decide downstream questions yet.

For unavailable facts, choose explicitly among:

- retain as an unknown that does not block architecture;
- conduct focused research;
- defer the dependent decision with a trigger;
- propose a measurable spike.

### 5. Build the Decision Tree

Maintain a dependency-aware decision tree internally. Each consequential node may contain:

```text
decision:      the architecture question
prerequisites: decisions or facts that must settle first
owner:         user, inherited decision, or discoverable evidence
status:        open | investigating | decided | deferred | spike-blocked
evidence:      sources and verified findings
options:       genuinely material alternatives
recommendation: preferred answer and reasoning
outcome:       user-approved or inherited result
consequences:  benefits, costs, risks, and follow-on constraints
```

The **current frontier** contains only open user-owned decisions whose prerequisites are settled. Inherited decisions are not frontier questions unless the user explicitly reopens them or a proposed design conflicts with them. Discoverable facts are investigation work, not questions for the user.

Shape the tree around the current initiative. Do not explore speculative branches that cannot affect it. Do not invent alternatives for inherited, obvious, or cheaply reversible choices merely to satisfy a template.

### 6. Work the Current Frontier in Small Rounds

Ask two to four independent frontier questions per round; ask fewer when fewer are ready. For each question:

1. name the decision;
2. explain why it matters now and what it unblocks;
3. summarize the relevant evidence and inherited constraints;
4. present only genuinely material options and trade-offs;
5. recommend an answer with reasoning;
6. make the response inexpensive, such as `A`, `B`, a short correction, `unknown`, `defer`, or `spike`.

Use a compact shape such as:

```markdown
### Q1 — <decision>

**Why now:** <why this is on the current frontier>

**Options:**

- **A — <option>:** <material trade-offs>
- **B — <option>:** <material trade-offs>

**Recommendation:** <answer and evidence-backed reasoning>

**Reply with:** A / B / correction / unknown / defer / spike
```

Then stop and wait. After the user answers, record the outcome and consequences, update the tree, and recompute the frontier. Accept `unknown`, `defer`, and `spike` as valid answers; do not pressure the user into false certainty.

For obvious or low-cost reversible choices, state the inherited/default approach and why it does not merit a decision round. If the user objects, add it to the tree.

The decision-tree session is complete only when:

- no architecture-blocking decisions remain unresolved;
- relevant coverage categories have been audited;
- deferred decisions are explicit and have resolution triggers where possible;
- spike-blocked decisions have measurable decision rules;
- the user approves the shared-understanding synthesis.

## Domain Vocabulary Discipline

Use lightweight vocabulary discipline inline; do not invoke the full `domain-modeling` skill by default.

- Read relevant canonical domain documentation before architecture discussion.
- Challenge vague, overloaded, or conflicting terminology when it affects an architecture decision.
- Use concrete scenarios and edge cases to sharpen domain relationships and ownership.
- Never treat an inferred or disputed term as canonical.
- If no relevant `CONTEXT.md` exists, keep only the terms needed for this initiative in a provisional, session-local vocabulary and continue without blocking. Never create `CONTEXT.md` automatically.
- At synthesis or approval, ask once whether explicitly resolved terms should become canonical. Treat this as a separate side effect from approval of the architecture.
- Update an existing `CONTEXT.md` only for explicitly resolved terms and only after the user authorizes that update. Respect the owning context and `CONTEXT-MAP.md`.
- Creating a new `CONTEXT.md` requires separate explicit approval after the user elects to canonicalize the resolved terms.
- Keep glossary entries free of implementation details and general programming vocabulary.
- If canonicalization is declined, retain only the agreed vocabulary needed in the architecture document.

A glossary entry should remain concise:

```markdown
**<Canonical term>**:
<One or two sentences defining the domain concept.>
_Avoid_: <conflicting or discouraged synonyms>
```

Do not edit domain documentation before synthesis and side-effect approval.

## Existing ADRs and Deviations

If a proposal conflicts with an existing ADR:

1. surface the conflict immediately with the ADR reference;
2. treat deviation as a user-owned decision;
3. do not silently violate, overwrite, edit, deprecate, or reinterpret the existing ADR;
4. if deviation is approved, offer a new ADR that explicitly supersedes the old one.

Offer a separate ADR only when all three conditions apply:

1. the decision is meaningfully hard to reverse;
2. a future reader would find it surprising without context;
3. it resulted from a genuine trade-off.

Require confirmation before creating each ADR. Keep it concise: title plus the context, decision, and why; add status, considered options, consequences, or supersession only when useful. Follow existing repository location and numbering conventions. The initiative architecture document remains canonical, so link to it and avoid duplicating its full analysis across ADRs.

## Spikes

Use a spike for an uncertain or expensive-to-reverse decision when focused evidence can resolve it. Never execute a spike automatically.

Every spike must contain:

```markdown
### <Spike name>

- **Blocked decision:** <decision this must unlock>
- **Uncertainty:** <fact or behavior not yet known>
- **Smallest useful experiment:** <minimal experiment, not an implementation project>
- **Timebox:** <bounded duration>
- **Evidence to capture:** <measurements, observations, or artifacts>
- **Decision rule:** <measurable conditions selecting or rejecting each relevant option>
- **Artifact disposition:** <keep, discard, or productionize only after a separate decision>
```

A spike-blocked architecture may be approved as `Provisional — blocked by <spike>`. Distinguish settled decisions from provisional ones and state how to resume architecture work after the spike: return with the captured evidence, apply the decision rule, resolve the blocked node, re-audit affected branches, and request approval for any changed synthesis.

## Adaptive Architecture Coverage

Before synthesis, audit each category for unresolved architecture-driving decisions. Mark a category **covered** or **not relevant**, with a brief reason. Do not force questions or document sections for irrelevant categories.

- intent, goals, non-goals, and constraints;
- system context and solution shape;
- domain concepts, lifecycle, and data ownership;
- modules, responsibilities, interfaces, and seams;
- integration boundaries and contracts;
- authentication, authorization, secrets, and trust boundaries;
- technology and build-versus-buy choices when materially consequential;
- architecture-driving reliability, privacy, performance, scalability, and operational constraints;
- for brownfield work, compatibility, coexistence, and constraints that a later migration or rollout plan must honor, without designing that plan here;
- risks, unknowns, and spikes.

Explicitly noting irrelevance prevents silent omission. Do not pursue speculative concerns that cannot affect the current initiative.

### 7. Synthesize

Before writing or publishing, present a concise shared-understanding synthesis containing:

- initiative intent, goals, non-goals, and architecture-driving constraints;
- source PRD, issue, epic, and reference links;
- inherited context for brownfield work;
- recommended architecture overview;
- system and module responsibilities, seams, domain and data ownership;
- boundaries, contracts, data flow, and trust boundaries;
- every material decision with evidence, alternatives, rationale, consequences, and reversibility;
- inherited decisions, new decisions, and approved deviations clearly distinguished;
- risks, unknowns, spike-blocked decisions, and explicit deferrals;
- coverage audit, including categories marked not relevant;
- the decisions downstream implementation planning must inherit rather than reopen;
- proposed status and destination;
- explicitly resolved vocabulary, plus any proposed canonical glossary updates, ADRs, remote publication, or Jira spike tickets as separate side effects.

Make every consequential assumption visible. Do not write the architecture document during synthesis.

### 8. Require User Approval

Ask the user to approve or correct the synthesis explicitly. The original request to create architecture is not approval of the later synthesis.

Use exactly these document statuses:

- **Accepted** — the synthesis is approved and no blocking spike remains.
- **Provisional — blocked by `<spike>`** — the synthesis is approved but one or more named spikes block final decisions.
- **Proposed** — only when the user explicitly requests an unapproved draft.

If the user requests an unapproved draft, still present the synthesis and ask for confirmation to write that displayed content as `Proposed`; this authorizes the write but is not architectural approval.

At the approval gate, also confirm any unresolved side effects:

- If the target already exists, ask whether to update it or create a new file. Never overwrite without confirmation.
- Ask once whether explicitly resolved terms should become canonical. If yes, request explicit authorization for the proposed update to an existing owning `CONTEXT.md`, or separate approval to create a new `CONTEXT.md`; architecture approval alone authorizes neither.
- Ask separately before creating an ADR.
- Ask separately before publishing remotely or creating Jira spike tickets.

### 9. Write or Publish Approved Artifacts

Follow an existing repository architecture-document convention when one exists. Otherwise default to:

`docs/<kebab-case-initiative>.architecture.md`

Immediately before writing, recheck whether the target exists. If it does and overwrite or update approval has not been given, stop and ask. Write only the approved synthesis, or the explicitly authorized `Proposed` draft.

Use this structure, adapting headings without dropping required content:

```markdown
# Architecture — <Initiative Name>

| Field        | Value                                                         |
| ------------ | ------------------------------------------------------------- |
| Status       | <Accepted, Provisional — blocked by named spike, or Proposed> |
| Owner        | <owner or TBD>                                                |
| Last updated | YYYY-MM-DD                                                    |

## Intent and Architecture-Driving Constraints

<Goals, non-goals, and constraints that shape the architecture.>

## Sources

- <PRD, issue, epic, repository document, or reference link>

## Inherited Context

<Brownfield architecture, conventions, decisions, compatibility constraints, and links to relevant ADRs. State not applicable for greenfield work.>

## Architecture Overview

<Concise system shape and how it satisfies the intent.>

## Responsibilities and Seams

<System/module responsibilities, interfaces, seams, and ownership at a high level.>

## Domain Model and Data Ownership

<Link canonical CONTEXT.md files rather than duplicating their glossaries. Describe relevant relationships, lifecycle, and ownership. If canonical documentation was declined, include only the agreed initiative vocabulary needed here.>

## Boundaries, Contracts, Data Flow, and Trust

<Major integration contracts, information flow, authentication/authorization posture, secrets, and trust boundaries.>

## Material Decisions

### <Decision>

- **Classification:** Inherited | New | Approved deviation
- **Outcome:** <decision>
- **Evidence:** <sources and facts>
- **Alternatives:** <material alternatives considered, or why alternatives were not material>
- **Rationale:** <why this best fits the goals and constraints>
- **Consequences:** <benefits, costs, risks, and constraints>
- **Reversibility:** <cost and conditions for changing course>

## Risks, Unknowns, and Spikes

<Risks and unknowns, followed by complete spike definitions where applicable.>

## Deferred Decisions

<Decision, reason for deferral, owner, and evidence or trigger that will resolve it.>

## Coverage Notes

<Relevant audited categories and explicit not-relevant categories.>

## Planning Handoff

<List the architecture decisions, constraints, contracts, ownership, provisional points, and deferred decisions that implementation planning must inherit rather than reopen without new evidence. Do not provide tasks, sequencing, migrations, test commands, or phases.>
```

Keep the document concise and high-level. Link canonical glossaries and ADRs rather than reproducing them.

Remote writes are always opt-in:

- Never publish to Confluence or edit a tracker resource unless explicitly requested.
- Never create Jira tickets unless explicitly requested.
- Jira creation from this skill is limited to approved spike tickets.
- General implementation-ticket creation belongs downstream.
- Report each external destination or created ticket exactly.

## Boundary and Quality Audit

Before writing, and again after drafting, verify:

- architecture remains distinct from product definition and implementation planning;
- no file edits, tasks, sequences, migrations, test commands, or implementation phases leaked in;
- the conversation and explicit approval preceded the document;
- material decisions include evidence, alternatives where genuine, reasoning, consequences, and reversibility;
- discoverable facts were investigated rather than pushed onto the user;
- no consequential assumption is silent;
- brownfield architecture was inherited unless explicitly reopened;
- inherited, new, and deviating decisions are distinguishable;
- domain and data ownership are coherent;
- glossary and ADR behavior avoids duplicate or inappropriate documentation;
- every spike has a measurable decision rule and artifact disposition;
- deferred and provisional decisions are visible;
- irrelevant coverage categories are explicitly noted;
- all glossary and external writes were explicitly authorized.

If correcting a boundary violation could change an approved decision, return to the user rather than guessing.

### 10. Hand Off

After writing or publishing:

1. Report the exact local or remote destination and status.
2. Summarize the architecture and material decisions briefly.
3. Name deferred and spike-blocked decisions.
4. Report any glossary updates, ADRs, publications, or Jira spike tickets actually created.
5. Offer, but do not force, the applicable next moves:
   - run a blocking spike;
   - create an implementation plan;
   - publish to Confluence;
   - create approved Jira spike tickets;
   - continue refining the architecture.

The implementation-planning handoff must treat the approved architecture as an inherited constraint. Reopen a decision only when new evidence, a changed requirement, or an explicit user decision justifies it.
