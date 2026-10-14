#!/usr/bin/env bash
# Runs PHPCS and (if configured) PHPStan on a Drupal module or theme path,
# through lando or ddev when the project uses them.
#
# Usage: run-checks.sh <path> [--tests]
#   <path>    Module or theme directory, relative to the project root.
#   --tests   Also run PHPUnit on <path>.
# Run from the project root (the directory containing composer.json).
# Exits non-zero if any check fails.

set -u

target="${1:-}"
run_tests=0
[[ "${2:-}" == "--tests" ]] && run_tests=1

if [[ -z "$target" ]]; then
  echo "Usage: run-checks.sh <path-to-module-or-theme> [--tests]" >&2
  exit 2
fi
if [[ ! -f composer.json ]]; then
  echo "composer.json not found in $(pwd). Run this from the Drupal project root." >&2
  exit 2
fi
if [[ ! -e "$target" ]]; then
  echo "Path '$target' does not exist (relative to $(pwd))." >&2
  exit 2
fi

if [[ -f .lando.yml ]]; then
  run() { lando php "$@"; }
  env_name="lando"
elif [[ -d .ddev ]]; then
  run() { ddev exec php "$@"; }
  env_name="ddev"
else
  run() { php "$@"; }
  env_name="host"
fi
echo "Environment: $env_name"

failed=()
ran=0

echo
echo "== PHPCS (Drupal, DrupalPractice) =="
if [[ -x vendor/bin/phpcs ]]; then
  # Extensions match drupal/coder's recommended list for Drupal code.
  ran=$((ran + 1))
  if ! run vendor/bin/phpcs --standard=Drupal,DrupalPractice \
      --extensions=php,module,inc,install,test,profile,theme,info,yml \
      -p "$target"; then
    failed+=("phpcs (try: vendor/bin/phpcbf --standard=Drupal,DrupalPractice $target)")
  fi
else
  echo "SKIPPED: vendor/bin/phpcs missing. Install with: composer require --dev drupal/coder"
fi

echo
echo "== PHPStan =="
if [[ -f phpstan.neon || -f phpstan.neon.dist ]]; then
  if [[ -x vendor/bin/phpstan ]]; then
    ran=$((ran + 1))
    run vendor/bin/phpstan analyse --no-progress "$target" || failed+=("phpstan")
  else
    echo "SKIPPED: phpstan config found but vendor/bin/phpstan missing. Run composer install."
  fi
else
  echo "SKIPPED: no phpstan.neon or phpstan.neon.dist in project root."
fi

if [[ $run_tests -eq 1 ]]; then
  echo
  echo "== PHPUnit =="
  if [[ -x vendor/bin/phpunit ]]; then
    config_args=()
    if [[ ! -f phpunit.xml && ! -f phpunit.xml.dist ]]; then
      for core in web/core docroot/core core; do
        [[ -f "$core/phpunit.xml" || -f "$core/phpunit.xml.dist" ]] && config_args=(-c "$core") && break
      done
    fi
    ran=$((ran + 1))
    run vendor/bin/phpunit "${config_args[@]}" "$target" || failed+=("phpunit")
  else
    echo "SKIPPED: vendor/bin/phpunit missing."
  fi
fi

echo
if [[ ${#failed[@]} -gt 0 ]]; then
  echo "FAILED: ${failed[*]}"
  exit 1
fi
if [[ $ran -eq 0 ]]; then
  echo "NO CHECKS RAN: every check was skipped. Install the missing tools listed above."
  exit 3
fi
echo "All checks that ran passed. Skipped checks are listed above."
