# Debugging

Work through these in order when a change does not take effect or the site errors.

1. Rebuild caches: `drush cr`.
2. Read recent errors: `drush watchdog:show --severity=Error --count=20`.
3. Check PHP syntax: `php -l path/to/File.php`.
4. Confirm the class autoloads: `drush php:eval "var_dump(class_exists('Drupal\my_module\MyClass'));"`. If it is `false`, check the namespace matches the path under `src/` and that the module is enabled.
5. Confirm a service is registered: `drush php:eval "var_dump(\Drupal::hasService('my_module.my_service'));"`. With Devel installed, `drush devel:services | grep my_module` lists them.
6. Confirm a hook is registered: `drush devel:hook HOOK_NAME` (Devel) lists implementations.
7. Confirm a route exists: `drush route --name=my_module.page` shows its path, controller, and requirements.
8. Confirm the module is enabled: `drush pm:list --filter=my_module`.
9. Compare active and exported config: `drush config:status`, then `drush config:get CONFIG_NAME`.

For stale output, set `http.response.debug_cacheability_headers: true` in `development.services.yml` and inspect the `X-Drupal-Cache-Tags` and `X-Drupal-Cache-Contexts` response headers.

For pending database updates after a code change, run `drush updatedb:status`, then `drush updb -y`.
