# Hooks and event subscribers

## Choosing

- Use a hook to alter core or contrib behavior that is exposed as a hook (form alters, entity lifecycle, theme preprocess).
- Use an event subscriber for Symfony kernel events (`KernelEvents::REQUEST`, `RESPONSE`, `EXCEPTION`), config events, migrate events, and modules that dispatch events (Commerce, for example).
- If a module offers both for the same purpose, follow what the rest of the project uses.

## OOP hooks (Drupal 11.1+)

Classes in `src/Hook/` are registered as autowired services automatically. No `services.yml` entry is needed on 11.1+.

```php
namespace Drupal\my_module\Hook;

use Drupal\Core\Form\FormStateInterface;
use Drupal\Core\Hook\Attribute\Hook;
use Drupal\node\NodeInterface;

final class MyModuleHooks {

  #[Hook('form_alter')]
  public function formAlter(array &$form, FormStateInterface $form_state, string $form_id): void {
  }

  #[Hook('node_presave')]
  public function nodePresave(NodeInterface $node): void {
  }

}
```

- Inject services through the constructor; autowiring resolves them by interface.
- OOP preprocess hooks and the `order` parameter for hook ordering arrived in 11.2. On 11.1, keep preprocess hooks procedural.
- Install, update, and post-update hooks stay procedural in `.install` and `.post_update.php`.

## Supporting 10.x or 11.0 as well

Keep a procedural function marked `#[LegacyHook]` that delegates to the class. Versions before 11.1 call the function; 11.1+ ignores it and calls the class, so the hook runs once.

```php
// my_module.module
use Drupal\Core\Hook\Attribute\LegacyHook;
use Drupal\my_module\Hook\MyModuleHooks;

#[LegacyHook]
function my_module_node_presave(NodeInterface $node): void {
  \Drupal::service(MyModuleHooks::class)->nodePresave($node);
}
```

Also register the class in `my_module.services.yml` so `\Drupal::service()` can find it on older versions:

```yaml
services:
  Drupal\my_module\Hook\MyModuleHooks:
    class: Drupal\my_module\Hook\MyModuleHooks
    autowire: true
```

## Event subscribers

```php
final class MyRequestSubscriber implements EventSubscriberInterface {

  public static function getSubscribedEvents(): array {
    return [KernelEvents::REQUEST => ['onRequest', 100]];
  }

  public function onRequest(RequestEvent $event): void {
  }

}
```

```yaml
services:
  my_module.request_subscriber:
    class: Drupal\my_module\EventSubscriber\MyRequestSubscriber
    tags:
      - { name: event_subscriber }
```

Higher priority runs earlier. Routing runs at priority 32 on `REQUEST`; subscribe above it to act before routing, below it to read the matched route.

Sources: [OOP hooks change record](https://www.drupal.org/node/3442349), [Hooks vs events](https://www.specbee.com/blogs/hooks-vs-events-in-drupal-making-informed-choice)
