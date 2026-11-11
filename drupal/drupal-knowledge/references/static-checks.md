# Static checks

Writing and running Drupal tests is covered by the `testing-standards` skill (`references/drupal.md`). This file covers only static analysis.

Run `scripts/run-checks.sh` (see SKILL.md). It runs the checks below with the right environment prefix.

- PHPCS with `Drupal,DrupalPractice` standards (`drupal/coder`). Auto-fix with `phpcbf`, then fix the rest by hand.
- PHPStan, if the project has a `phpstan.neon` or `phpstan.neon.dist`.

Install the tools if they are missing:

```bash
composer require --dev drupal/coder mglaman/phpstan-drupal phpstan/phpstan-deprecation-rules
```

Common PHPCS failures:

- Missing trailing comma on the last item of a multi-line array or parameter list.
- Missing or malformed docblocks on classes, methods, and properties.
- `\Drupal::` calls inside a class (DrupalPractice).
- Two-space indentation and line-length violations.
