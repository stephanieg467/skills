---
name: drupal-knowledge
description: Drupal 10/11 development conventions, gotchas, and CLI workflows. Use whenever writing, reviewing, debugging, or planning code in a Drupal site or module, even when the user does not say "Drupal". Triggers include custom modules or themes, hooks, services, plugins, blocks, forms, controllers, routes, entities, fields, content types, config schema or config export, render arrays, cache tags, Twig templates, translation, Drush, Composer `drupal/*` packages, PHPCS/PHPStan on Drupal code, D10 to D11 upgrades, recipes, and files such as `*.info.yml`, `*.module`, `*.services.yml`, `*.routing.yml`, or `config/sync/*.yml`.
---

# Drupal Development

Conventions for Drupal 10.3+ and 11. This file holds the workflow, the rules every task needs, and the gotchas. Mechanics and examples live in `references/`.

## Run commands through the project's tooling

Before running Drush, Composer, PHPUnit, or PHPCS, detect the local environment:

- If `.lando.yml` exists, prefix commands with `lando` (`lando drush cr`, `lando composer ...`). Run vendor binaries with `lando php vendor/bin/...`.
- If `.ddev/` exists, prefix commands with `ddev` (`ddev drush cr`). Run vendor binaries with `ddev exec vendor/bin/...`.
- Otherwise, run commands directly.

Command examples in `references/` are written without a prefix; add the prefix above.

## Workflow

1. **Gather context.** Read two or three similar files in the project (services, forms, plugins) and match their naming, DI style, and directory layout. Project conventions override the defaults in this skill.
2. **Check for contrib.** If the task adds new functionality rather than changing existing code, search drupal.org for a contrib module or recipe before writing custom code. Present the best candidates and let the user choose. See `references/contrib-research.md`.
3. **Scaffold, then customize.** If the task creates a standard structure (module, form, plugin, service, entity, test), generate it with `drush generate` and edit the result. Create fields with `drush field:create`, not hand-written YAML. See `references/drush-scaffolding.md`.
4. **Implement** following the core rules below and the relevant reference file.
5. **Export config.** If the change altered active configuration, run `drush cex -y` and review the diff. Do not commit unrelated config changes that were already in the diff.
6. **Verify.** From the project root, run `scripts/run-checks.sh <path-to-changed-module>` (add `--tests` if the module has tests). Fix every error and run it again until it passes. If it reports that no checks ran, tell the user which tools are missing. Then `drush cr` and smoke-test the change.

## Core rules

- Inject dependencies through the constructor. Use `\Drupal::service()` only in procedural code (`.module`, `.install`, `.theme`) where injection is impossible.
- Use PHP attributes, not annotations, for new plugins.
- Put new hook implementations in `src/Hook/` classes with `#[Hook]` when the module targets 11.1+. If the module also supports 10.x or 11.0, follow the compatibility pattern in `references/hooks-and-events.md`.
- Give every render array correct `#cache` tags, contexts, and max-age. See `references/caching.md`.
- Pass every user-facing string through the translation API. See `references/translation-and-twig.md`.
- Define a config schema for every piece of custom configuration. Missing schema breaks config translation and fails kernel tests with strict schema checking.
- Use the database API or entity queries with placeholders. Never concatenate input into SQL.
- Check access on every route (`_permission`, `_entity_access`, or a custom access checker). Entity queries must set `->accessCheck(TRUE|FALSE)` explicitly.

## References

Read only the file the task needs.

- `references/contrib-research.md` — read when deciding between contrib, a recipe, a patch, or custom code.
- `references/module-code-patterns.md` — read when writing services, routes, controllers, forms, plugins, config schema, or database queries.
- `references/hooks-and-events.md` — read when implementing a hook or an event subscriber, or choosing between them.
- `references/caching.md` — read when building render arrays, blocks, or controllers that output content, or when debugging stale output.
- `references/translation-and-twig.md` — read when writing user-facing strings or Twig templates.
- `references/drush-scaffolding.md` — read when generating code, creating content types or fields, or generating test content.
- `references/version-compatibility.md` — read when targeting both D10 and D11, removing deprecations, upgrading core, or applying recipes.
- `references/testing-and-quality.md` — read when writing Drupal tests or setting up PHPCS/PHPStan. For test quality rules, use the `testing-standards` skill.
- `references/debugging.md` — read when a change does not take effect, a service or class is not found, or the site throws errors.

## Gotchas

- `drush generate` has no `--answers` JSON option. Non-interactive runs use repeated `-a`/`--answer` flags, consumed in prompt order. Run with `--dry-run` first to see the prompts and check the output.
- Generator names changed in Drush 12 (DCG 3). Use `form:simple`, `form:config`, `service:custom`, `service:event-subscriber`, `entity:content`. Run `drush generate` with no arguments to list the real names instead of guessing.
- OOP hooks (`#[Hook]` in `src/Hook/`) require Drupal 11.1. On 10.x or 11.0 the class is ignored silently and the hook never runs.
- `hook_install`, `hook_update_N`, and `hook_post_update_NAME` cannot be OOP hooks. Keep them in `.install` and `.post_update.php`.
- Internal Page Cache ignores `max-age` for anonymous users. Content that must expire for anonymous visitors needs cache tags that get invalidated, or the `page_cache_kill_switch` service.
- Cache metadata on a variable you return separately is lost. Cache metadata only bubbles when it is attached to the render array that is actually rendered; use `CacheableMetadata::createFromObject($entity)->applyTo($build)`.
- In Twig, do not add `|raw` to render arrays or `{{ content }}`. They are already safe; `|raw` on a string bypasses autoescaping and opens XSS.
- Entity queries throw an exception on D10+ if `accessCheck()` is not called. Set it explicitly, even when the answer is `FALSE`.
- New services, routes, hooks, or plugin classes are invisible until the cache is rebuilt. Run `drush cr` before concluding that code does not work.
- `drush cex` exports all active config, including changes someone made through the UI. Review `git diff config/` and drop anything unrelated to the task.
