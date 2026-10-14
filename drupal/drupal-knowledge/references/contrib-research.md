# Contrib research

Do this before writing custom code for new functionality. Skip it for bug fixes and edits to existing custom code.

## Search

1. Search drupal.org (`https://www.drupal.org/project/project_module`) and the web for modules that cover the requirement.
2. Check whether a recipe (Drupal 10.3+) bundles the needed configuration.
3. Check whether the project already has a module installed that can do it (`drush pm:list --status=enabled`).

## Evaluate each candidate

- It has a release compatible with the project's core version.
- It is covered by the security advisory policy (shield icon on the project page).
- It had a commit or release in the last 12 months.
- Its reported install count is meaningful for the use case.
- Its issue queue has recent maintainer responses, and no open critical bug blocks the use case.

## Decide

Present two or three candidates with the evidence above and a recommendation. Let the user choose. Prefer, in order:

1. Configuring an installed module.
2. Installing a healthy contrib module or applying a recipe.
3. Patching a contrib module that nearly fits, and contributing the patch upstream (see the `drupalorg-contrib` skill).
4. Extending a contrib module through its hooks, events, or plugins in a small custom module.
5. Writing custom code.

Use a recipe for configuration-only needs (content types, views, roles). Use a module when PHP code is required.
