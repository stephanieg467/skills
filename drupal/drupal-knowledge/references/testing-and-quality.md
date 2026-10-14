# Testing and quality checks

Whether to write a test, and how to keep it meaningful, is covered by the `testing-standards` skill. This file covers only the Drupal mechanics.

## Test types

| Type | Base class | Use for |
|------|------------|---------|
| Unit | `UnitTestCase` | Pure PHP logic with no container |
| Kernel | `KernelTestBase` | Services, entities, queries, hooks, config schema |
| Functional | `BrowserTestBase` | Forms, routes, access control, page output |
| FunctionalJavascript | `WebDriverTestBase` | AJAX and JavaScript behavior |

Prefer kernel tests. They exercise real services and the database while running much faster than functional tests.

- Put tests in `tests/src/{Unit,Kernel,Functional,FunctionalJavascript}/` with namespace `Drupal\Tests\my_module\{Type}`.
- In kernel tests, list every module the test needs in `protected static $modules` and install entity schemas and config with `installEntitySchema()` and `installConfig()`.
- Functional tests must set `protected $defaultTheme = 'stark';`.

```bash
vendor/bin/phpunit -c web/core web/modules/custom/my_module
vendor/bin/phpunit -c web/core --filter testMethodName web/modules/custom/my_module
```

Kernel and functional tests need `SIMPLETEST_DB` and `SIMPLETEST_BASE_URL`. Check the project's `phpunit.xml` before assuming they are set.

## Static checks

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

Sources: [PHPUnit in Drupal](https://www.drupal.org/docs/develop/automated-testing/phpunit-in-drupal), [Types of tests](https://www.drupal.org/docs/develop/automated-testing/types-of-tests)
