---
name: create-verification-skill
description: "Generates and proves a project-local verification skill that drives the real app through user-facing UI, CLI, or service journeys and captures evidence."
disable-model-invocation: true
---

# Create a verification skill

Generate a project-local `verify-<app>` skill that launches the real app, exercises user-facing behavior, and captures evidence. Write it for the next agent: it will be read cold, mid-task, by an agent that has never seen the app.

## 1. Interview the repo, not the user

Answer these from the codebase and only ask the user what you cannot observe:

- **Surface:** what does a user actually touch? A web UI, a CLI/TUI, a desktop app, an API, a mobile app, a library? A repo can have several; pick the primary one and note the rest.
- **Run:** how does the app start locally? Prefer the repo's own documented dev command (package scripts, Makefile, README quickstart). Note ports, env vars, seed data, auth.
- **Drive:** how can an agent interact with it programmatically? Existing harnesses first — Playwright/Cypress specs, expect scripts, PTY helpers, curl-able endpoints, a debug port. For browser work without an existing harness, prefer the available `agent-browser` skill. Otherwise use an available browser/CDP tool, a tmux/PTY harness for CLI/TUI, or plain HTTP for services. Check tool availability before documenting commands; ask before adding dependencies.
- **Observe:** what evidence can be captured? Screenshots, terminal transcripts, response bodies, logs, exit codes, DB state.
- **Isolate:** can two instances run side by side (ports, data dirs, profiles)? If not, say so in the generated skill: refusing to double-drive a shared instance beats corrupting the user's session.

Locate existing project-local verification skills before writing. Reuse the relevant one; if it needs upkeep, offer `/maintain-verification-skill` rather than replacing it. Ask before overwriting existing files.

Choose the repository's documented or established project-local skill location and call the resulting `verify-<app>/` directory `<skill-dir>` below. If the convention is absent or ambiguous, ask which agent and location to target; do not assume `.cursor/skills/`.

If the checkout doesn't build or start as-is, report the exact blocker. Ask before fixing application code outside the approved task. Only create missing startup assets as explicitly identified, disposable verification scaffolding that does not change application behavior; remove that scaffolding in cleanup. If startup remains blocked, report that generation cannot be proved; any output is a draft.

Use disposable local or test state. Ask before using production data, making purchases, sending real messages, or causing other external side effects. Keep credentials and sensitive data out of generated instructions and evidence. Include these safeguards in the generated skill.

## 2. Generate the skill

Write `<skill-dir>/SKILL.md` with YAML frontmatter (`name: verify-<app>` and a `description` that names the app, the surface, and verification after implementation or fixes). Allow automatic invocation of the generated skill. Include these sections, each grounded in what the interview actually found (no placeholders left):

- **Launch:** the exact command that starts the app for verification, and how to tell it's ready (a log line, a prompt). Launch must reach a usable state from an empty data dir, including any migrations and seed data. Ready means usable, not just that a process answers. A database health check can pass while its init scripts are still running. Include teardown. For a short-lived CLI or TUI there is no server to keep alive: launch means build the binary (or install deps) once, then start each drive in its own isolated PTY or tmux session.
- **Doctor:** one read-only check that answers "is this instance worth driving?" — process up, right version/build, port owned by us, auth valid. An agent runs this before the first drive, on each fresh session, and again after a failed drive. If the process is healthy but the app state is wedged, reset to a known state or relaunch.
- **Drive:** the harness recipe with real selectors/commands from this repo, not examples. Prefer stable handles (ARIA labels, data attributes, prompt strings, route paths) over coordinates and tab order.
- **Scope and results:** read the feature-map index and select journeys covering the current task's acceptance criteria and affected entry points. Add or correct missing recipes within the approved scope; report unresolved coverage gaps rather than substituting an unrelated journey. For each required journey, report pass, fail, or blocked, with the entry point, observed result, evidence paths, and tested revision including relevant uncommitted changes. Mark runtime verification not applicable only when the change has no runtime behavior to exercise, and explain why. Generation's one-feature proof does not verify a later implementation task.
- **Evidence:** what to capture for a proof and where it goes. State the proof standards: exercise the real user path, not internal setters or test-only endpoints; capture the action and the resulting state, not just the final screen; verify side effects (files written, rows inserted, messages sent) alongside what's visible; mocks only where a production boundary already isolates the external system. When the safe path is a dry-run or test mode, verify what it actually skips by observing (files, network, git refs) rather than trusting its name: some dry-runs still touch the network or open a browser.
- **Cleanup:** how to tear down instances the run created. Never kill by process name; kill what you started. Cleanup removes instances and scratch state, never the evidence: proof artifacts survive the teardown, in a location the skill names.
- **Helpers:** any script the skill ships is executable and its invocation is shown in the skill body. A helper the reader has to reverse-engineer is not a helper.

## 3. Seed the feature map

Create `<skill-dir>/features/README.md` plus one file per user-facing feature you can identify (aim for the top 3-5 to start, from routes, commands, menus, or docs). Read [the example index](references/feature-map-example/README.md) for the map contract, [create-note.md](references/feature-map-example/create-note.md) for a state-changing journey, and [search.md](references/feature-map-example/search.md) for a read-only journey. These describe an illustrative Notes app; `control-notes` is not a dependency. Copy their structure, not their commands. Each file answers, from the user's point of view: what the feature is, how to reach it, how to drive it with the harness, and what observable end state proves it works. The four H2s are `Sub-features`, `How to get to it (user POV)`, `Driving it with <harness>`, and `Gotchas`. If the seed data lacks a precondition that a journey needs, the journey reports a failure and the reason goes in that feature's `Gotchas`. Never weaken the journey to make it pass. The map is the repo's maintained verification source; a proof that drives one convenient entry point is incomplete when the map lists others.

## 4. Prove the generated skill before handing it over

Run its own instructions end to end once: launch, doctor, drive ONE mapped feature (one is enough; the map exists so later runs can cover the rest), capture evidence, clean up. After cleanup, confirm the evidence still exists at the named location — a cleanup that eats the proof fails this step. Fix what fails, and run the generated cleanup after every failed iteration too, so broken attempts don't strand processes and ports. A generated skill that was never executed is a draft, not a deliverable. If you proved it in a stand-in for the real target (a container in place of a fresh VM, a local stack in place of a remote one), list every setup step the stand-in did that the target will not. Those steps stay unverified until a run on the real target covers them.

## 5. Offer the maintenance loop

Point the user at `/maintain-verification-skill` for keeping the map honest as the app changes. Suggest a cadence only if they ask.

## Gotchas

- A listening port does not prove the app is usable. Wait for migrations, seed data, and authentication before driving it.
- A final screenshot alone does not prove the action worked. Capture the action and confirm the persisted or external result.
- A generated skill that was never executed remains a draft. Do not report other mapped features as verified by its one-feature proof.
