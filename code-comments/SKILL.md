---
name: code-comments
description: Decide whether and how to write code comments and doc blocks (JSDoc, TSDoc, PHPDoc, docstrings) in any language. Use during any coding task that creates or changes functions, classes, or modules, even when the user never mentions comments, and whenever adding, editing, reviewing, or removing comments or doc blocks, including requests to "document this", "add JSDoc", or "clean up comments".
---

# Code Comments

A comment earns its place only when it tells the reader something the code cannot. Default to no comment. Clear names and straightforward code come first.

## Decide whether to comment

- Do not add a comment just because a function, class, or file is new.
- If a better name or a simpler structure would make the comment unnecessary, change the code instead.
- Add a comment when it explains intent, a business rule, a constraint, units, an invariant, a trade-off, surprising behavior, or an API contract the signature does not show.
- Explain why the code does something. Do not narrate what each line does.
- Do not add `ponytail:` comments.

## Choose the form

- If one short line is enough, use an ordinary line comment.
- Use a structured doc block (JSDoc, TSDoc, PHPDoc, docstring) only when the API, tooling, or project conventions warrant it. Public or exported APIs and generated docs are typical reasons. Small internal helpers usually are not.
- Follow the project's required documentation format when one exists, even if these rules would otherwise omit the block.

## Write a doc block

- Start with a concise description of the purpose or behavior.
- Do not put the main explanation inside `@param` or `@returns`.
- Add a `@param` or `@returns` tag only when it states meaning the signature does not, such as units, accepted ranges, side effects, or what `null` means. The other reason is tooling that requires the tag.
- Do not write filler like "the value", "submitted values", or "returns the result".
- Do not document a return value the function does not have.
- Use the language's conventional layout: description first, then one tag per line. Do not cram several tags into a one-line `/** ... */`.

## Types in comments

- In TypeScript, do not restate interfaces, type aliases, or typed signatures with `@typedef`, `@property`, or typed `@param {Type}` tags.
- In JavaScript, use `@typedef` and `@property` only when they supply type information the code lacks and that type checking or editors actually use.
- In PHP, keep PHPDoc types that native types cannot express, such as `list<User>`, `array<string, int>`, or array shapes. Drop PHPDoc types that only repeat native declarations.

## Editing existing comments

- When you change code, update or remove the comments on that code so they stay accurate.
- Remove obsolete or redundant comments only within the code you were asked to touch. Do not run a repository-wide comment cleanup.
- Before deleting a tag-only comment, check its purpose. Keep tags that drive tooling, type checking, generated docs, deprecation (`@deprecated`), licensing, or linter and analyzer suppression (`@phpstan-ignore`, `@ts-expect-error`, `eslint-disable`).
- Never strip security explanations, operational warnings, or other essential context to make a comment shorter.
- Do not change public doc blocks in ways that break documented API compatibility.

## Examples

These show the decision, not a template to copy.

An obvious helper needs no comment. The name and signature already say everything:

```ts
// Before
/** @param value Untrusted JSON value. @returns Whether it is an object. */
function isRecord(value: unknown): value is Record<string, unknown> { ... }

// After
function isRecord(value: unknown): value is Record<string, unknown> { ... }
```

A non-obvious rule deserves one line explaining why:

```php
// Before
if ($order->total() < 5000) {

// After
// Carrier rejects COD shipments of $50 or more; amounts are in cents.
if ($order->total() < 5000) {
```

A doc block adds value when it leads with behavior and its tags carry real meaning:

```ts
// Before
/**
 * @param values Submitted form values.
 * @param formikHelpers Submission feedback helpers.
 * @returns Saves and advances only after an accepted Delivery quote, or after a non-Delivery submit.
 */

// After
/**
 * Saves the step and advances the wizard. Delivery orders advance only after
 * the customer accepts a quote; other fulfilment types advance immediately.
 */
```

The second "After" has no tags because the typed signature already describes the parameters.
