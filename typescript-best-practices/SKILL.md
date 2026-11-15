---
name: typescript-best-practices
description: TypeScript type-safety and modeling standards. Use whenever writing, editing, refactoring, or reviewing any .ts or .tsx file, even when the user never mentions TypeScript or types, including requests to "fix the type error", "remove the any", "type this API response", "model this state", or "clean up these casts".
---

# TypeScript Best Practices

Make illegal states unrepresentable, validate untrusted data once at the boundary, and trust the types everywhere inside. Then stop: the simplest type that keeps every operation honest wins over a clever one.

Examples for every rule live in `references/patterns.md`. Read it when you need the exact shape of a pattern.

## Follow the project first

- Read `tsconfig.json` and the lint config before writing code, and write code that passes them.
- If the repository already has a convention (discriminant name, brand shape, schema library, `type` vs `interface`), follow it instead of these defaults.
- Do not change `tsconfig.json` or lint rules unless the user asks. If you create a new project, enable `strict` and `noUncheckedIndexedAccess`.

## Model data

- Model mutually exclusive states as a discriminated union with a literal `kind` field, not as a bag of optional fields and booleans.
- Keep a plain type like `T[]` or `string` while every operation on it is total.
- If a loose type forces a `!`, an `as`, or a "should never happen" throw at a use site, strengthen the type (for example `[T, ...T[]]` for non-empty) or return `T | undefined` instead.
- Brand a primitive (`string & { readonly __brand: "UserId" }`) only when two values of the same primitive are realistically confused, such as IDs passed side by side.
- Create a brand only through a function that verifies the value, never with a bare `as`.
- Derive types from what already exists (`typeof`, `ReturnType`, `Awaited`, `Pick`, `Omit`, generated API or schema types) before declaring a new interface that duplicates a shape.
- Use `as const` for fixed lookup objects and derive union types from them. Do not use `enum`.

## Validate at the boundary

- Type all external data as `unknown`: `JSON.parse`, `fetch` responses, `postMessage`, storage, environment variables, file contents, and third-party payloads.
- Parse external data once, where it enters, into a named domain type. Do not re-validate it deeper in the call chain.
- If the repository has a schema library (Zod, Valibot, ArkType, etc.), define the schema and infer the type from it (`z.infer<typeof UserSchema>`). Do not keep a separate interface that can drift from the schema.
- If the repository has no schema library, write a type guard instead of adding a dependency for one shape.
- A type guard must check everything its `x is T` claims. A guard that checks less than it claims hides the bug behind a name that says it is safe.

## Narrow, don't assert

- Never use `any`. Use `unknown` and narrow it.
- Narrow in this order of preference: discriminant check, `in`, `typeof` or `instanceof`, a type guard. Use `as` only after validation proved the claim.
- Use `satisfies` to check a literal against a type without widening it.
- Do not use the non-null assertion `!` to silence the compiler. Handle the `undefined` case or strengthen the type.
- Prefer `@ts-expect-error` with a one-line reason over `@ts-ignore`, and use either only for a genuine compiler or library limitation.
- End every `switch` over a union with an exhaustiveness check so adding a variant breaks the build:

  ```ts
  default: {
    const _exhaustive: never = shape;
    throw new Error(`Unhandled shape: ${JSON.stringify(_exhaustive)}`);
  }
  ```

## Keep types simple

- Let inference type local variables and callbacks. Annotate exported function parameters, and annotate a return type only when it is part of a public contract or inference produces something wrong or unreadable.
- Do not write conditional, mapped, or template literal types unless they remove real duplication or catch a real bug. A type a reader cannot follow in ten seconds is a cost.
- Do not add a generic parameter that is used only once. Use the concrete type.
- Pass an options object instead of positional arguments when a function takes several arguments of the same type, so a swapped argument cannot compile. Skip this on hot paths like parsers and render loops.
- Use specific function signatures, not the `Function` or `object` types.
- Use `import type` for type-only imports when the project enables `verbatimModuleSyntax` or the lint config requires it.

## Before finishing

1. Run the project's type check (for example `npx tsc --noEmit` or the `typecheck` script in `package.json`).
2. Fix every error you introduced. Do not fix them with `any`, `as`, `!`, or `@ts-expect-error`.
3. Run the check again and continue only when it passes.

For tests in TypeScript, use the `testing-standards` skill.

## Gotchas

- `"key" in obj` on a non-union object proves only that the key exists. The value is still `unknown`, so check its type too.
- With `noUncheckedIndexedAccess`, `arr[0]` is `T | undefined`. Destructure from a non-empty tuple or check the value; do not add `!`.
- `filter(Boolean)` never narrows out `undefined` or `null`. Use `filter((x) => x !== undefined)`, which TypeScript 5.5+ infers as a type predicate; on older versions write `(x): x is T => x !== undefined`.
- `as const` on an object makes it deeply `readonly`. Passing it to a function that takes a mutable array fails; change the parameter to `readonly T[]` rather than casting.
- `JSON.parse`, `response.json()`, and `Object.keys` return `any` or `string[]` by design. Treat their results as `unknown` and as plain strings, not as the type you hope they are.
- `exactOptionalPropertyTypes` makes `{ a?: string }` reject `{ a: undefined }`. If the project enables it, omit the key instead of assigning `undefined`.
- Node's built-in type stripping and `erasableSyntaxOnly` reject `enum`, `namespace`, and constructor parameter properties. Another reason to use `as const` objects and plain class fields.
