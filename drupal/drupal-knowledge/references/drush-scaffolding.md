# Drush scaffolding

## Contents

- Code generators
- Non-interactive generation
- Content types and fields
- Test content

## Code generators

Run `drush generate` with no arguments to list the generators available in the project. Names below are for Drush 12+ (DCG 3+).

| Need | Generator |
|------|-----------|
| Module | `module` |
| Controller | `controller` |
| Form | `form:simple`, `form:config`, `form:confirm` |
| Service | `service:custom` |
| Event subscriber | `service:event-subscriber` |
| Other tagged services | `service:access-checker`, `service:route-subscriber`, `service:twig-extension`, ... |
| Hook | `hook` |
| Plugins | `plugin:block`, `plugin:condition`, `plugin:filter`, `plugin:field:type`, `plugin:field:widget`, `plugin:field:formatter` |
| Entity types | `entity:content`, `entity:configuration`, `entity:bundle-class` |
| Tests | `test:unit`, `test:kernel`, `test:browser`, `test:webdriver` |
| Drush command | `drush:command-file` |

After generating, read every created file and adapt it to the project's conventions before adding logic.

## Non-interactive generation

Generators prompt interactively. Pass answers with repeated `-a` (`--answer`) flags. They are consumed in the order the prompts appear.

1. Run the generator once with `--dry-run` to see the prompts and the files it would write.
2. Re-run with one `-a` per prompt, in order, still with `--dry-run`. Check the printed output.
3. Run again without `--dry-run`.

```bash
drush generate form:config --dry-run
drush generate form:config -a my_module -a 'My Module' -a SettingsForm ... --dry-run
```

Other useful options: `--destination` (write somewhere else), `--replace` (overwrite without asking).

## Content types and fields

Create fields with `drush field:create`. Never hand-write `field.storage.*`, `field.field.*`, `core.entity_form_display.*`, or `core.entity_view_display.*` YAML.

```bash
drush field:create node article \
  --field-name=field_subtitle \
  --field-label="Subtitle" \
  --field-type=string \
  --field-widget=string_textfield \
  --is-required=0 \
  --cardinality=1

drush field:create node article \
  --field-name=field_tags \
  --field-label="Tags" \
  --field-type=entity_reference \
  --field-widget=entity_reference_autocomplete \
  --cardinality=-1 \
  --target-type=taxonomy_term
```

Discover valid values with `drush field:types`, `drush field:widgets`, and `drush field:formatters`. Check the options with `drush field:create --help`. Inspect a bundle with `drush field:info node article`. Delete with `drush field:delete`.

Drush has no command for creating a content type. Create it with `php:eval`, then export:

```bash
drush php:eval "\Drupal\node\Entity\NodeType::create(['type' => 'event', 'name' => 'Event', 'new_revision' => TRUE])->save();"
drush cex -y
```

## Test content

Requires the `devel_generate` submodule of Devel. Never run it on production; `--kill` deletes existing content of that type.

```bash
drush devel-generate:content 50 --bundles=article,page
drush devel-generate:terms 100 --bundles=tags
drush devel-generate:users 20
drush devel-generate:media 30 --media-types=image
```

Sources: [Drush generate](https://www.drush.org/13.x/commands/generate/), [Drush field:create](https://www.drush.org/13.x/commands/field_create/), [DCG](https://github.com/Chi-teck/drupal-code-generator)
