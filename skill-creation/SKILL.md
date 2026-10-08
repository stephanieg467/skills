---
name: skill-creation
description: Best practices for writing and improving skills. Use whenever the user wants to create a new skill, turn a workflow or set of notes into a skill, review or improve an existing skill.
---

# Skill Creation

A skill is documentation the model loads on demand. Every line costs context, and the description alone decides whether the skill is loaded at all. Apply the practices below when drafting or reviewing a skill.

## Anatomy

```
skill-name/
├── SKILL.md          required: frontmatter + instructions
├── references/       optional: docs loaded only when needed
├── scripts/          optional: deterministic code the model runs
└── assets/           optional: templates and files used in output
```

Frontmatter fields:

```yaml
---
name: skill-name
description: What it does and when to use it.
argument-hint: "[optional: what $ARGUMENTS should contain]"
disable-model-invocation: true   # optional: only the user may invoke it
---
```

## 1. The description is the trigger

The model reads only the name and description when deciding whether to load a skill. Write the description around the user's intent, not the implementation: "Use when creating a new article" beats "Article generation pipeline using the CMS API".

Models tend to under-trigger, so be slightly pushy. Name the situations, phrasings, and synonyms that should activate the skill, including cases where the user does not say the obvious keyword. Put all "when to use" guidance in the description, not the body; the body is not read until after the decision is made.

If the skill has disable-model-invocation: true, then the description doesn't need to include the "when to use" guidance, but it should still describe the skill's purpose and what it does.

## 2. Build from real expertise

Do not let the model invent the skill's content. Source it from domain knowledge, runbooks, code reviews, past reports, and corrections made in earlier sessions. A skill generated from nothing encodes generic advice the model already has.

Record every gotcha: the environment-specific mistake that was made once and corrected. These are the highest-value lines in a skill because they are the things the model would otherwise get wrong again.

## 3. Spend context wisely

Keep SKILL.md under 500 lines (roughly 5,000 tokens). Anything longer raises cost on every invocation and degrades performance by crowding out the task itself. Cut explanations the model does not need, and prefer one clear instruction over three overlapping ones.

## 4. Use progressive disclosure

Move large or rarely needed material into `references/`. Keep in SKILL.md only what every invocation needs, and add a one-line pointer saying when to read each reference file. The model then loads a reference only for the tasks that require it.

When a skill covers several variants (frameworks, providers, environments), give each its own reference file and keep SKILL.md to the shared workflow plus selection logic.

## 5. Match freedom to fragility

Make each instruction as specific as the task is fragile.

- **Narrow bridge:** If only one path is safe, give the exact command and say what must not change: "Run exactly `scripts/migrate.sh`. Do not add flags."
- **Middle ground:** If a preferred pattern exists but details vary, give a template or parameterized pseudocode for the model to adapt.
- **Open field:** If many paths work, give a heuristic or a short list of priorities and trust the model.

Over-specifying an open field wastes context and breaks on cases the rules did not foresee; see "Keep safeguards proportionate" in §10.

## 6. Use deterministic scripts

For narrow-bridge steps that must not be improvised, such as math, strict data transforms, or exact command sequences, put the logic in `scripts/` and instruct the model to run the script. Natural-language instructions are re-interpreted on every run; a script produces the same result every time.

## 7. Give workflows steps and feedback loops

- If a task has several steps, number them.
- If a task is long or complex, give a checklist the model copies into its response and ticks off as it goes.
- If quality matters, add a loop: run the check, fix the errors, and run the check again. Continue only when the check passes. The check can be a script (§6) or a reference document the model compares its output against.

## 8. Provide templates for output

When the response must follow a specific shape, put the template in `assets/` or inline it in SKILL.md and tell the model to fill it in. A concrete template reduces variance and hallucinated structure far more than a prose description of the format.

## 9. Say what not to do

Add a gotchas or constraints section that names the mistakes to avoid. Explicit negative constraints are unusually effective at preventing recurring errors and unwanted formatting. Where possible, state the reason so the model can generalize instead of pattern-matching.

## 10. Write plain, single-sourced instructions

Dense instructions get misread by the model and are hard for humans to maintain. Write for a reader who follows every word.

- **One rule per bullet, as a full sentence.** Avoid slash lists ("owner/parent/permissions") and "X means Y" chains that pack several rules into one line.
- **Use if/then for branches.** "If the write times out, read the doc before offering a retry" beats "Timeouts require read-before-retry."
- **Put the action first; give the reason only when it isn't obvious.**
- **State each rule once.** Give it one home (gates and workflow in SKILL.md, mechanics in references) and link to it by name everywhere else. Restating a rule in several files lets the copies drift apart.
- **Let scripts carry the details.** If a script enforces a rule, the prose needs one line saying to run it, not a paragraph explaining what it checks.
- **Keep safeguards proportionate.** Each gate is one more thing the model has to track through the whole run. Ask what actually goes wrong if a gate is removed. Prefer one general rule ("verify after each write; never retry automatically") over a separate gate for every case.

## Before finishing a skill

- The description states what the skill does and lists the situations that should trigger it.
- SKILL.md is under 500 lines and every section earns its place.
- Large or variant-specific material lives in `references/` with pointers.
- Fragile steps are scripts, not prose.
- Instructions are as specific as each step is fragile, and quality-critical steps loop until a check passes.
- Required output formats have a template.
- Known gotchas are written down.
- Each rule appears in exactly one file, written as a plain sentence.

## What not to do

- Do not describe the implementation in the description; describe the user's intent.
- Do not pad SKILL.md with background the model already knows.
- Do not inline long reference docs; link them from `references/`.
- Do not rely on prose for steps that need identical results every run.
- Do not write a skill from imagination when runbooks, reviews, or past corrections exist.
- Do not restate the same rule across SKILL.md, references, and the README; link to it instead.
