# Version compatibility

## Drupal 10 vs 11

| | Drupal 10 | Drupal 11 |
|---|---|---|
| PHP | 8.1+ | 8.3+ |
| Symfony | 6.4 | 7.x |
| Plugin discovery | Attributes (10.2+) or annotations | Attributes preferred; annotations still work |
| Hooks | Procedural | OOP `#[Hook]` from 11.1; procedural still works |

## Writing code that runs on both

- Set `core_version_requirement: ^10.3 || ^11` in `*.info.yml`.
- Use attributes for plugins.
- Implement hooks as OOP hooks plus a `#[LegacyHook]` procedural function that delegates to the class.
- Do not use PHP 8.3-only syntax (typed class constants, `json_validate()`) if 10.x on PHP 8.1 or 8.2 must be supported.

## Finding deprecations

Use PHPStan with Drupal and deprecation rules (`mglaman/phpstan-drupal`, `phpstan/phpstan-deprecation-rules`). For whole-site readiness, install the Upgrade Status module and run `drush upgrade_status:analyze --all`.

```bash
vendor/bin/phpstan analyse web/modules/custom
```

Apply automatic fixes with Drupal Rector (`palantirnet/drupal-rector`), then review the diff by hand.

## Upgrading D10 → D11

1. Update to the latest 10.x minor and clear all deprecation warnings in custom code.
2. Confirm every contrib module has a D11-compatible release, or a patch for it.
3. Confirm the hosting PHP version is 8.3+.
4. Update core with Composer (see the `drupal-update-modules` skill), then run `drush updb -y` and `drush cex -y`.
5. Test in a non-production environment.

## Recipes (10.3+)

Recipes apply configuration and install modules; they do not stay installed.

```bash
php core/scripts/drupal recipe core/recipes/standard
composer require drupal/RECIPE_NAME
php core/scripts/drupal recipe recipes/contrib/RECIPE_NAME   # path depends on composer installer-paths
```

Sources: [Drupal 11 system requirements](https://www.drupal.org/docs/getting-started/system-requirements), [Recipes](https://www.drupal.org/docs/extending-drupal/drupal-recipes)
