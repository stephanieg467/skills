---
name: decide-architecture
description:
  'Decides the high-level code architecture for an initiative (PRD, ticket,
  epic, URL, or idea) through an evidence-backed, dependency-aware conversation
  and an explicit approval gate, before implementation planning.'
disable-model-invocation: true
---

# Decide Architecture

Decide the high-level architecture for an initiative by building shared understanding with the user before writing anything. Act as a pragmatic staff architect: propose rather than dictate, and prefer simple, reversible, familiar designs that fit the stated goals.

## Contract

Accept an approved PRD, a tracker issue or epic, a URL, or a free-form idea, plus optional reference documents.

The output is architecture: solution shape, module responsibilities, domain and data ownership, seams, interfaces, data flow, trust boundaries, and major contracts. It must never contain:

- file-by-file edits or project structure changes;
- tasks, sequences, or implementation phases;
- migrations or rollout procedures;
- test commands or testing plans.

Brownfield compatibility constraints may be recorded, but their execution belongs downstream.

If product intent is too unclear to judge architectural fitness, explain the blocking ambiguity, recommend `create-prd`, and stop. Sufficient intent covers the problem, goals, required behavior, scope or non-goals, and architecture-driving constraints. Record non-blocking product unknowns; never fill them in.

Never silently converge on a consequential decision. Never write the architecture document before the synthesis is approved.

## Information Ownership

Classify every piece of information:

1. **Discoverable facts** — investigate them with the repository, references, integrations, or subagents. Never ask the user for something you can discover.
2. **User-owned decisions** — ask about preferences, priorities, strategic direction, cost tolerance, risk appetite, team familiarity, and undocumented constraints.
3. **Unavailable facts** — label them unknown, research them, defer the dependent decision with a trigger, or propose a spike. Never invent them.

Attach evidence (repo paths, document titles, links, tool results, primary sources) to the decision it informs, and mark inferences as inferences. Subagents gather evidence; they never make user-owned decisions. Verify load-bearing findings directly before relying on them.

## Skills to Load

Load each skill below when its condition applies, even if the input does not mention it:

- `domain-modeling` — before reading or proposing changes to `GLOSSARY.md`, `GLOSSARY-MAP.md`, or ADRs. It owns their formats and the test for when a decision deserves an ADR.
- `codebase-design` — when a decision adds or reshapes modules, interfaces, or seams. Use its deep-module vocabulary in options and recommendations.
- `research` — when a consequential decision depends on current external facts such as pricing, limits, or vendor guarantees. Run it in the background and keep working on independent decisions.
- `jira` — to read a ticket or epic input, and to create approved spike tickets.
- Any platform or framework skill whose description matches the target system (e.g. `drupal`). It defines the inherited conventions brownfield decisions must respect.

Hand off instead of loading: `create-prd` when product intent is insufficient, and `plan-implementation` after approval.

## Workflow

Whenever user input or approval is required, ask a small round of questions, end the turn, and wait.

### 1. Orient

1. Read the conversation and every supplied input. If the input is a tracker resource or URL, read it through an available integration; if it is inaccessible, ask for an accessible copy.
2. Record known intent, sourced constraints, assumptions, unknowns, and the requested destination.
3. Determine whether the initiative targets a repository or an existing system.
4. Derive a tentative initiative name and kebab-case slug.
5. Apply the product-intent gate from the Contract.

### 2. Load Domain Documentation and Existing Decisions

1. Load domain documentation the way `domain-modeling` describes: use `GLOSSARY-MAP.md` to find the relevant `GLOSSARY.md` files, or read the root `GLOSSARY.md`.
2. If no relevant glossary exists, keep a small provisional vocabulary in the session and continue. Never treat a provisional or disputed term as canonical.
3. Read architecture docs and ADRs that constrain this initiative. Use search and repository organization to find them; do not read every ADR.
4. Treat canonical terms and accepted ADRs as inherited constraints unless the user reopens them. If the repository shows a decision was superseded, follow the repository.

### 3. Classify Greenfield or Brownfield

Infer the mode from the initiative and workspace. Ask only if it cannot be inferred.

**Brownfield:** Launch at most one Explore subagent (`scout` in pi) with a narrow brief, and require a compressed evidence report at the architecture level, not a file inventory. It should establish:

- current system shape and module seams;
- domain and data ownership;
- major interfaces, contracts, and data flows;
- integration and trust boundaries;
- operational conventions;
- compatibility and coexistence constraints;
- extension points and coupling that affect the initiative.

Do not repeat its broad reconnaissance yourself. Sort findings into **inherited decisions** (not reopened), **new decisions** (required by this initiative), and **proposed deviations** (need user approval). Do not reopen inherited architecture merely because another design looks cleaner.

**Greenfield:** Explore the solution space from the initiative's goals and constraints, comparing only plausible approaches. Do not choose a technology without evidence that it fits the environment, budget, and team familiarity.

Investigate only facts that can change the option set or a recommendation. If an investigation is still running, continue with independent decisions but do not decide anything downstream of it.

### 4. Build the Decision Tree

Maintain a dependency-aware decision tree internally. Each consequential node may contain:

```text
decision:       the architecture question
prerequisites:  decisions or facts that must settle first
owner:          user, inherited decision, or discoverable evidence
status:         open | investigating | decided | deferred | spike-blocked
evidence:       sources, confidence, and verified findings
options:        genuinely material alternatives
recommendation: preferred answer and reasoning
outcome:        user-approved or inherited result
consequences:   benefits, costs, risks, and follow-on constraints
```

The **current frontier** is the set of open user-owned decisions whose prerequisites are settled. Inherited decisions join the frontier only if the user reopens them or a proposal conflicts with them. Do not explore branches that cannot affect this initiative, and do not invent alternatives for obvious or cheaply reversible choices.

If a proposal conflicts with an existing ADR, surface the conflict immediately with the ADR reference and treat the deviation as a user-owned decision. Never edit, deprecate, or reinterpret the existing ADR.

### 5. Work the Frontier in Small Rounds

Ask two to four independent frontier questions per round, or fewer when fewer are ready:

```markdown
### Q1 — <decision>

**Why now:** <why it is on the frontier and what it unblocks>

**Evidence:** <relevant findings and inherited constraints>

**Options:**

- **A — <option>:** <material trade-offs>
- **B — <option>:** <material trade-offs>

**Recommendation:** <answer and evidence-backed reasoning>

**Reply with:** A / B / correction / unknown / defer / spike
```

Then stop and wait. After each answer, record the outcome and consequences, update the tree, and recompute the frontier. Accept `unknown`, `defer`, and `spike` as valid answers.

For obvious or cheaply reversible choices, state the default and why it does not need a round. If the user objects, add it to the tree.

**Spikes:** Use a spike when focused evidence can resolve an uncertain or expensive-to-reverse decision. Define it with [assets/spike-template.md](assets/spike-template.md). Never run a spike automatically.

### 6. Audit Coverage

Mark each category **covered** or **not relevant**, with a brief reason:

- intent, goals, non-goals, and constraints;
- system context and solution shape;
- domain concepts, lifecycle, and data ownership;
- modules, responsibilities, interfaces, and seams;
- integration boundaries and contracts;
- authentication, authorization, secrets, and trust boundaries;
- technology and build-versus-buy choices, when consequential;
- reliability, privacy, performance, scalability, and operational constraints;
- for brownfield work, compatibility and coexistence constraints a later rollout must honor;
- risks, unknowns, and spikes.

The session is ready for synthesis only when no architecture-blocking decision is open, every deferral has a resolution trigger, and every spike has a measurable decision rule.

### 7. Synthesize

Present a condensed version of every section in [assets/architecture-template.md](assets/architecture-template.md), plus the proposed status, destination, and any side effects to approve. Make every consequential assumption visible, and keep inherited, new, and deviating decisions distinguishable. Do not write the document yet.

### 8. Require Approval

Ask the user to approve or correct the synthesis. The original request is not approval of the synthesis. Use exactly one status:

- **Accepted** — approved, and no blocking spike remains.
- **Provisional — blocked by `<spike>`** — approved, but named spikes block final decisions. State how to resume: bring the spike evidence, apply its decision rule, re-audit affected branches, and request approval for any changed synthesis.
- **Proposed** — only when the user explicitly asks for an unapproved draft. Still show the synthesis and get confirmation to write it.

**Side effects:** Approving the architecture authorizes only the architecture document. Ask separately before each of these:

- overwriting or updating an existing target file;
- making explicitly resolved terms canonical in a `GLOSSARY.md` (creating a new one needs its own approval);
- creating an ADR, including one that supersedes a deviated ADR;
- publishing to Confluence or editing a tracker resource;
- creating Jira tickets, which this skill limits to approved spikes.

Reading a remote resource grants permission to read only.

### 9. Write

Follow the repository's architecture-document convention if one exists. Otherwise write `docs/<kebab-case-initiative>.architecture.md`.

1. Recheck that the target does not exist, or that updating it was approved.
2. Fill in [assets/architecture-template.md](assets/architecture-template.md) with only the approved content. Adapt headings but do not drop required content.
3. Link glossaries and ADRs instead of copying them. ADRs link back to this document instead of duplicating its analysis.
4. Re-read the draft against the Contract. If fixing a violation would change an approved decision, return to the user instead of guessing.

### 10. Hand Off

1. Report the exact local or remote destination and status.
2. Summarize the material decisions, and name deferred and spike-blocked ones.
3. Report every glossary update, ADR, publication, or ticket actually created.
4. Offer the applicable next moves: run a blocking spike, `plan-implementation`, publish to Confluence, create approved spike tickets, or keep refining.

Downstream planning inherits the approved architecture and reopens a decision only with new evidence, a changed requirement, or an explicit user decision.
