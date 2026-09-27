---
name: skill-creation
description: Best practices for writing and improving skills (SKILL.md files and their references, scripts, and assets folders). Use whenever the user wants to create a new skill, turn a workflow or set of notes into a skill, review or improve an existing skill.
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

## 2. Build from real expertise

Do not let the model invent the skill's content. Source it from domain knowledge, runbooks, code reviews, past reports, and corrections made in earlier sessions. A skill generated from nothing encodes generic advice the model already has.

Record every gotcha: the environment-specific mistake that was made once and corrected. These are the highest-value lines in a skill because they are the things the model would otherwise get wrong again.

## 3. Spend context wisely

Keep SKILL.md under 500 lines (roughly 5,000 tokens). Anything longer raises cost on every invocation and degrades performance by crowding out the task itself. Cut explanations the model does not need, and prefer one clear instruction over three overlapping ones.

## 4. Use progressive disclosure

Move large or rarely needed material into `references/`. Keep in SKILL.md only what every invocation needs, and add a one-line pointer saying when to read each reference file. The model then loads a reference only for the tasks that require it.

When a skill covers several variants (frameworks, providers, environments), give each its own reference file and keep SKILL.md to the shared workflow plus selection logic.

## 5. Use deterministic scripts

For steps that must not be improvised, such as math, strict data transforms, or exact command sequences, put the logic in `scripts/` and instruct the model to run the script. Natural-language instructions are re-interpreted on every run; a script produces the same result every time.

## 6. Provide templates for output

When the response must follow a specific shape, put the template in `assets/` or inline it in SKILL.md and tell the model to fill it in. A concrete template reduces variance and hallucinated structure far more than a prose description of the format.

## 7. Say what not to do

Add a gotchas or constraints section that names the mistakes to avoid. Explicit negative constraints are unusually effective at preventing recurring errors and unwanted formatting. Where possible, state the reason so the model can generalize instead of pattern-matching.

## Before finishing a skill

- The description states what the skill does and lists the situations that should trigger it.
- SKILL.md is under 500 lines and every section earns its place.
- Large or variant-specific material lives in `references/` with pointers.
- Fragile steps are scripts, not prose.
- Required output formats have a template.
- Known gotchas are written down.

## What not to do

- Do not describe the implementation in the description; describe the user's intent.
- Do not pad SKILL.md with background the model already knows.
- Do not inline long reference docs; link them from `references/`.
- Do not rely on prose for steps that need identical results every run.
- Do not write a skill from imagination when runbooks, reviews, or past corrections exist.
