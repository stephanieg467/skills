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
├── assets/           optional: templates and files used in output
└── config.json       optional: setup answers saved from the user
```

Frontmatter fields:

```yaml
---
name: skill-name            # max 64 chars: lowercase letters, numbers, hyphens; no XML tags, no "anthropic" or "claude"
description: What it does and when to use it.  # required, max 1,024 chars, no XML tags; prefer short and concise
argument-hint: "[optional: what $ARGUMENTS should contain]"
disable-model-invocation: true   # optional: only the user may invoke it
---
```

## 1. The description is the trigger

The model reads only the name and description when deciding whether to load a skill. Write the description around the user's intent, not the implementation: "Use when creating a new article" beats "Article generation pipeline using the CMS API". Write it in the third person ("Processes Excel files…", not "I can help…" or "You can use this to…"); it is injected into the system prompt, and a mixed point of view hurts discovery.

Models tend to under-trigger, so be slightly pushy. Name the situations, phrasings, and synonyms that should activate the skill, including cases where the user does not say the obvious keyword. Put all "when to use" guidance in the description, not the body; the body is not read until after the decision is made.

If the skill has disable-model-invocation: true, then the description doesn't need to include the "when to use" guidance, but it should still describe the skill's purpose and what it does.

## 2. Build from real expertise

Do not let the model invent the skill's content. Source it from domain knowledge, runbooks, code reviews, past reports, and corrections made in earlier sessions. A skill generated from nothing encodes generic advice the model already has.

## 3. Spend context wisely

Keep SKILL.md under 500 lines (roughly 5,000 tokens). Anything longer raises cost on every invocation and degrades performance by crowding out the task itself. Assume the model is already very capable, and test each piece of content: Does the model really need this explanation? Can I assume it already knows this? Does this paragraph justify its token cost? Prefer one clear instruction over three overlapping ones.

Spend the lines on knowledge that pushes the model out of its default way of thinking, not on what it would do anyway. A frontend design skill, for example, earns its place by steering away from the Inter font and purple gradients.

## 4. Use progressive disclosure

Move large or rarely needed material into `references/`. Keep in SKILL.md only what every invocation needs. The model then loads a reference only for the tasks that require it.

- Link every reference file directly from SKILL.md, with one line saying when to read it.
- Do not link from one reference file to another. The model may preview a nested file only partially, for example with `head -100`, and miss content.
- If a reference file is longer than about 100 lines, start it with a short table of contents. The model then sees the full scope even when it reads only part of the file.
- Name files after their content, such as `references/form-validation-rules.md` rather than `doc2.md`, and organize directories by domain or feature.

When a skill covers several variants (frameworks, providers, environments), give each its own reference file and keep SKILL.md to the shared workflow plus selection logic.

## 5. Match freedom to fragility

Make each instruction as specific as the task is fragile.

- **Narrow bridge:** If only one path is safe, give the exact command and say what must not change: "Run exactly `scripts/migrate.sh`. Do not add flags."
- **Middle ground:** If a preferred pattern exists but details vary, give a template or parameterized pseudocode for the model to adapt.
- **Open field:** If many paths work, give a heuristic or a short list of priorities and trust the model.

Over-specifying an open field wastes context and breaks on cases the rules did not foresee; see "Keep safeguards proportionate" in §12.

## 6. Use deterministic scripts

Put code in `scripts/` for two reasons. First, narrow-bridge steps that must not be improvised, such as math, strict data transforms, or exact command sequences, need a script: natural-language instructions are re-interpreted on every run, while a script produces the same result every time. Second, helper scripts and libraries let the model spend its turns on composition, deciding what to do next, instead of reconstructing boilerplate.

- Say whether the model should run the script ("Run `scripts/x.py` to …") or read it as reference ("See `scripts/x.py` for the algorithm"). Prefer running, because only the output uses context.
- Handle expected errors inside the script instead of failing and leaving the model to work them out.
- Make error messages specific enough to act on, for example "Field 'signature_date' not found. Available fields: customer_name, order_total, …".
- Give every constant a reason. Do not leave unexplained values like `TIMEOUT = 47`.
- List the packages the script needs and the command to install them. Do not assume they are installed.
- If an operation is batch or destructive, use plan, validate, then execute: the model writes a plan file, a script validates it, and only then are the changes applied.

## 7. Give workflows steps and feedback loops

- If a task has several steps, number them.
- If a task is long or complex, give a checklist the model copies into its response and ticks off as it goes.
- If quality matters, add a loop: run the check, fix the errors, and run the check again. Continue only when the check passes. The check can be a script (§6) or a reference document the model compares its output against.

## 8. Provide templates and examples for output

When the response must follow a specific shape, put the template in `assets/` or inline it in SKILL.md and tell the model to fill it in. A concrete template reduces variance and hallucinated structure far more than a prose description of the format. Match the template's strictness to the need: say "ALWAYS use this exact structure" for strict formats, or "a sensible default; adapt as needed" for flexible ones.

If the output depends on style, such as commit messages, give two or three example input and output pairs. Concrete examples convey style better than a template or a prose description.

## 9. Write down gotchas

Give every skill a Gotchas section. Gotchas are the highest-signal content in a skill: they come from real failure points, the mistakes the model would otherwise make again. Add to the section each time a new failure is observed.

Explicit negative constraints are unusually effective at preventing recurring errors. State the reason where possible so the model can generalize instead of pattern-matching. Make each gotcha as specific as these:

- "The `subscriptions` table is append-only. The row you want is the one with the highest version, not the most recent `created_at`."
- "This field is called `@request_id` in the API gateway and `trace_id` in the billing service. They're the same value."
- "Staging returns 200 even when the Stripe webhook didn't actually process. Check `payment_events` for the real state."

## 10. Set up config

Some skills need context from the user before they can run; a standup skill, for example, needs to know which Slack channel to post to.

- Store setup answers in `config.json` in the skill directory.
- If the config is missing or incomplete, ask the user for the values and save them to the file.
- If the questions are structured or multiple choice, tell the model to use the `AskUserQuestion` tool.

## 11. Keep persistent memory

A skill can keep its own data between runs in an append-only log, JSON files, or a SQLite database. For example, a `standup-post` skill appends every post to `standups.log`, so the next run can tell what changed since yesterday. Store the data in a stable location. For plugin skills, use `${CLAUDE_PLUGIN_DATA}`, which points to a directory that persists.

## 12. Write plain, single-sourced instructions

Dense instructions get misread by the model and are hard for humans to maintain. Write for a reader who follows every word.

- **One rule per bullet, as a full sentence.** Avoid slash lists ("owner/parent/permissions") and "X means Y" chains that pack several rules into one line.
- **Use if/then for branches.** "If the write times out, read the doc before offering a retry" beats "Timeouts require read-before-retry."
- **Put the action first; give the reason only when it isn't obvious.**
- **State each rule once.** Give it one home (gates and workflow in SKILL.md, mechanics in references) and link to it by name everywhere else. Restating a rule in several files lets the copies drift apart.
- **Use one term per concept.** Pick one word, such as "field", and use it throughout; do not mix "field", "box" and "element".
- **Give a default, not a menu.** Name one approach and add an alternative only for a specific case: "Use pdfplumber. For scanned PDFs, use pytesseract instead."
- **Avoid content that will go out of date.** Write the current method in the main text, not "before August 2025, use the old API"; move legacy behavior to a collapsed "Old patterns" section.
- **Let scripts carry the details.** If a script enforces a rule, the prose needs one line saying to run it, not a paragraph explaining what it checks.
- **Keep safeguards proportionate.** Each gate is one more thing the model has to track through the whole run. Ask what actually goes wrong if a gate is removed. Prefer one general rule ("verify after each write; never retry automatically") over a separate gate for every case.

## Before finishing a skill

- The description, in the third person, states what the skill does and lists the situations that should trigger it.
- SKILL.md is under 500 lines and every paragraph justifies its token cost.
- Large or variant-specific material lives in `references/`, linked directly from SKILL.md.
- Fragile steps are scripts, not prose.
- Instructions are as specific as each step is fragile, and quality-critical steps loop until a check passes.
- Required output formats have a template, and style-dependent output has input and output examples.
- A Gotchas section records failures actually observed, each with its reason.
- If the skill needs user context, it reads `config.json` and asks for missing values.
- Each rule appears in exactly one file, written as a plain sentence.
