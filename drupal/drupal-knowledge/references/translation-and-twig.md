# Translation and Twig

## Translating strings

| Context | Use |
|---------|-----|
| Class with `StringTranslationTrait` (controllers, forms, blocks already have it) | `$this->t('Hello @name', ['@name' => $name])` |
| Procedural code | `t('Hello @name', ['@name' => $name])` |
| Plugin attribute | `new TranslatableMarkup('My block')` |
| Plural | `$this->formatPlural($count, '1 item', '@count items')` |
| Twig | `{{ 'Hello'\|t }}` or `{% trans %}Hello {{ name }}{% endtrans %}` |
| JavaScript | `Drupal.t('Hello')` and `Drupal.formatPlural()` |

Placeholders:

- `@name` escapes the value.
- `%name` escapes the value and wraps it in `<em class="placeholder">`.
- `:name` escapes a URL and strips dangerous protocols. Use it inside `href`.

Rules:

- Pass a literal string to `t()`. A variable or concatenation (`$this->t($label)`, `$this->t('Hi ' . $name)`) cannot be extracted for translation.
- Write source strings in English, even on a site whose default language is not English.

## Twig

- Output is autoescaped. Do not add `|escape`, and do not add `|raw` to render arrays; it bypasses autoescaping.
- Attach CSS and JS through a library: `{{ attach_library('my_module/my-library') }}`. Never inline `<script>` or `<style>`.
- Render a single field with `{{ content.field_name }}`. Use `{{ content|without('field_name') }}` to render the rest.
- Do business logic in a preprocess hook or a render array, not in the template.
- Debug with `{{ dump(variable) }}` after enabling Twig debug in `development.services.yml` (`twig.config: debug: true`), or under Configuration › Development settings on 10.1+.
