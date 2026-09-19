---
name: drupal-update-modules
description: Identify and update Drupal Composer packages, including core, contributed modules, and themes, within existing composer.json constraints
disable-model-invocation: true
---

# Step 1: Identify tooling
Inspect workspace to determine whether to use lando or ddev. NOTE: all commands below assume the workspace uses lando but if it is determine that the current workspace uses ddev then the commands should be run with ddev instead of lando.

# Step 2: Identify Drupal packages with available updates and notify user
Use `lando composer outdated "drupal/*"` to list newer releases for Drupal Composer packages, including core, contributed modules, and themes. Newer releases are not necessarily installable within the current `composer.json` constraints.
Use `lando composer audit` to identify known security advisories affecting installed dependencies. An advisory does not necessarily mean that a security release or an installable fix is available.
Use `lando composer update "drupal/*" --with-dependencies --dry-run` to preview the package changes Composer resolves within the current constraints without applying dependency changes. Report proposed version changes, dependency additions or removals, and resolution conflicts. Distinguish available updates from installable updates; dependent non-Drupal packages may appear in the resolved changes. Never change version constraints without user approval. A successful dry run does not prove that patches will apply or database updates will succeed.
Present the user with the available releases, installable updates, and security advisories, then ask which updates they would like to apply. Identify any potential concerns or flags that may require additional attention before updating. If the user chooses to update, proceed to step 3.

Before updating, run `lando drush config:status` and inspect existing Git changes in the project's configuration sync directory. Record any existing differences so they are not mistaken for changes caused by module updates. Do not overwrite unrelated changes; ask the user if their intended state is unclear.

# Step 3: Update Drupal packages
For the full Drupal package selection approved in step 2, run `lando composer update "drupal/*" --with-dependencies`.
For a subset, rerun the dry run for all selected packages together using the same dependency flag, for example `lando composer update drupal/module_one drupal/module_two --with-dependencies --dry-run`. Report the revised plan and get user approval before running the same command without `--dry-run`.
Address and fix any issues that arise during the update process, such as dependency conflicts or errors. Once complete notify the user of all packages updated, including dependent non-Drupal packages, and any issues that were resolved during the update process. If there are any issues that could not be resolved, notify the user and provide guidance on how to address them. If no issues remain ask for confirmation to proceed to step 4.

# Step 4: Apply database updates and reconcile configuration
Run `lando drush updb -y && lando drush cr`.

Then run `lando drush config:status` and compare the result with the pre-update baseline.

- If configuration is synchronized, no export is needed.
- If differences exist, inspect the actual active configuration and sync YAML before deciding what to do. Use `lando drush config:get CONFIG_NAME` to inspect an affected configuration object.
- When the database contains intended update-hook changes, run `lando drush cex -y` to capture them and review the resulting Git diff. Do not export unrelated or unexplained changes.
- Investigate unexpected UUID changes, deletions, permission changes, or other suspicious differences. Do not automatically accept or revert them.
- If reviewed corrections were made to sync YAML, apply them with `lando drush cim -y && lando drush cr`. First ensure the YAML includes the intended update-hook changes, so importing does not undo them.
- After an import, run `lando drush config:status` again. Drupal may normalize imported configuration, leaving another difference. Inspect it; if it is expected normalization, run `lando drush cex -y` and review the resulting diff.
- Finish by checking configuration status. Report any remaining differences rather than repeatedly importing or exporting to force a clean result.

Remember: `cex` copies database configuration into YAML; `cim` copies YAML into the database. Neither should overwrite changes that have not been reviewed.

# Step 5: List all updated packages and testing guidance
Provide the user with a list of all updated packages and any testing guidance or recommendations for verifying that the updates were successful. This may include checking for any changes in functionality, reviewing logs for errors, and testing any custom code that may be affected by the updates.
