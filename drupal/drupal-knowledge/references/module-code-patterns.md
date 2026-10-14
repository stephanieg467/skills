# Module code patterns

## Contents

- Module layout
- Dependency injection
- Services
- Routes and access
- Plugins
- Config schema
- Database queries
- Output and security

## Module layout

```
my_module/
├── my_module.info.yml
├── my_module.module           # Procedural code only when unavoidable
├── my_module.install          # hook_install, hook_update_N, hook_schema
├── my_module.services.yml
├── my_module.routing.yml
├── my_module.permissions.yml
├── my_module.libraries.yml
├── config/
│   ├── install/               # Default config
│   ├── optional/              # Installed only if dependencies exist
│   └── schema/                # Schema for every custom config object
├── src/
│   ├── Controller/
│   ├── EventSubscriber/
│   ├── Form/
│   ├── Hook/                  # OOP hooks (11.1+)
│   └── Plugin/
├── templates/
└── tests/src/{Unit,Kernel,Functional,FunctionalJavascript}/
```

## Dependency injection

Controllers and forms use `create()` from `ContainerInjectionInterface` (base classes already implement it). Plugins implement `ContainerFactoryPluginInterface`. Use constructor property promotion.

```php
final class MyController extends ControllerBase {

  public function __construct(
    protected readonly EntityTypeManagerInterface $entityTypeManager,
  ) {}

  public static function create(ContainerInterface $container): static {
    return new static(
      $container->get('entity_type.manager'),
    );
  }

}
```

For a plugin, `create()` also receives `$configuration, $plugin_id, $plugin_definition` and must pass them to the parent constructor.

If the project already uses `AutowireTrait` (10.2+) for controllers, follow that instead of hand-written `create()` methods.

## Services

```yaml
services:
  my_module.article_processor:
    class: Drupal\my_module\ArticleProcessor
    arguments: ['@entity_type.manager', '@logger.channel.my_module']

  logger.channel.my_module:
    parent: logger.channel_base
    arguments: ['my_module']
```

If the project uses autowiring, register by class name with `autowire: true` instead of listing arguments.

## Routes and access

```yaml
my_module.page:
  path: '/my-page'
  defaults:
    _controller: '\Drupal\my_module\Controller\MyController::content'
    _title: 'My Page'
  requirements:
    _permission: 'access content'
```

Every route needs a requirement. Use `_entity_access: 'node.update'` for entity routes and `_custom_access` or a tagged access checker for anything else.

## Plugins

```php
#[Block(
  id: 'my_module_recent_articles',
  admin_label: new TranslatableMarkup('Recent articles'),
)]
final class RecentArticlesBlock extends BlockBase implements ContainerFactoryPluginInterface {
}
```

## Config schema

Every key under `config/install` and every key a settings form saves needs schema.

```yaml
# config/schema/my_module.schema.yml
my_module.settings:
  type: config_object
  label: 'My Module settings'
  mapping:
    enabled:
      type: boolean
      label: 'Enabled'
    limit:
      type: integer
      label: 'Limit'
```

Validate with `drush config:inspect --only-error` if the `config_inspector` module is installed.

## Database queries

Prefer entity queries and entity storage. Use the database service only for custom tables.

```php
$nids = $this->entityTypeManager->getStorage('node')->getQuery()
  ->accessCheck(TRUE)
  ->condition('type', $type)
  ->range(0, 10)
  ->execute();

$result = $this->database->select('my_table', 't')
  ->fields('t', ['id', 'name'])
  ->condition('t.type', $type)
  ->execute();
```

## Output and security

- Output untrusted text with `#plain_text`, or with `#markup` (which runs `Xss::filterAdmin()`).
- Use `Html::escape()` for text placed into attributes or strings built by hand.
- Validate and cast route and query parameters before use.
- Protect state-changing GET routes with `_csrf_token: 'TRUE'`.

Sources: [Services and DI](https://www.drupal.org/docs/drupal-apis/services-and-dependency-injection)
