# Caching

Every render array that depends on data needs three kinds of metadata:

- **Tags** say which data the output depends on. Saving that data invalidates the cache.
- **Contexts** say which request variations change the output (user, role, URL, language).
- **Max-age** says how long the output stays valid. `Cache::PERMANENT` is the default; `0` disables caching.

```php
$build = [
  '#theme' => 'item_list',
  '#items' => $items,
  '#cache' => [
    'tags' => ['node_list:article'],
    'contexts' => ['user.permissions', 'url.query_args:page'],
  ],
];

// Add an entity's or config object's metadata instead of hand-writing tags.
CacheableMetadata::createFromObject($node)->applyTo($build);
(new CacheableMetadata())->addCacheableDependency($config)->applyTo($build);
```

## Tag conventions

- `node:123` is one entity. Entities provide it through `getCacheTags()`.
- `node_list` invalidates on any node save; `node_list:article` (bundle-specific) invalidates only on article saves.
- `config:my_module.settings` is a config object.
- For custom data, invalidate your own tag with `Cache::invalidateTags(['my_module:thing'])` when the data changes.

## Rules

- Prefer tags over a short max-age. A max-age is a guess; a tag is exact.
- Use the narrowest context that is correct: `user.roles` or `user.permissions` instead of `user` wherever the output does not differ per user.
- A `user` context on a block makes it uncacheable across users. For small per-user parts, use a `#lazy_builder` so the rest of the page stays cached.
- Access results carry cache metadata too. Return `AccessResult::allowedIfHasPermission(...)` and add `->addCacheableDependency()` for anything else the decision reads.
- Max-age bubbles minimum-wins: one child with max-age `0` makes the whole parent, and usually the page, uncacheable. Personalized parts belong in lazy builders for this reason.
- Without `#cache['keys']`, an array's metadata still bubbles up, but the array is not render-cached on its own. Add keys only to expensive subtrees worth caching separately.
- Set `#access` to an `AccessResult`, not a boolean. A boolean drops the access check's cacheability; the object's metadata merges into the render tree.

## Lazy builders

```php
$build['cart'] = [
  '#lazy_builder' => ['my_module.cart_builder:build', [$user->id()]],
  '#create_placeholder' => TRUE,
];
```

- Arguments must be scalars; see the lazy-builder gotcha in SKILL.md.
- The callback service must implement `TrustedCallbackInterface` and list the method in `trustedCallbacks()`.

## Controllers and responses

- HTML controllers return render arrays. `new Response($html)` discards all cache metadata.
- JSON endpoints return a `CacheableJsonResponse` and call `addCacheableDependency()` for each entity, config object, or `CacheableMetadata` the data depends on.
- Outside a request (Drush, cron, queue workers), render with `renderInIsolation()`, not `render()`. `render()` throws a `LogicException` when no render context exists.

## Debugging

- Enable `http.response.debug_cacheability_headers: true` in `development.services.yml` and inspect the `X-Drupal-Cache-Tags` and `X-Drupal-Cache-Contexts` response headers.
- `X-Drupal-Cache: HIT` is Internal Page Cache (anonymous users). `X-Drupal-Dynamic-Cache` is Dynamic Page Cache.
