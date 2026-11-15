# TypeScript patterns

Examples for the rules in `SKILL.md`. Each shows the wrong shape first, then the fix.

- Discriminated unions
- Simplest total type
- Branded types
- Derived types
- `as const` instead of `enum`
- Boundary validation with a schema
- Boundary validation without a schema
- Removing an `as`
- `satisfies`
- Options objects

## Discriminated unions

```ts
// Don't: loading, data, and error can all be set at once.
type Request = { loading: boolean; data?: User; error?: string };

// Do: only the valid states exist.
type Request =
  | { kind: "loading" }
  | { kind: "ready"; data: User }
  | { kind: "failed"; error: string };

function render(req: Request): string {
  switch (req.kind) {
    case "loading":
      return "Loading…";
    case "ready":
      return req.data.name;
    case "failed":
      return req.error;
    default: {
      const _exhaustive: never = req;
      throw new Error(`Unhandled request: ${JSON.stringify(_exhaustive)}`);
    }
  }
}
```

## Simplest total type

Keep `T[]` when every operation handles the empty case:

```ts
const total = (prices: number[]) => prices.reduce((sum, p) => sum + p, 0);
```

Strengthen when the loose type forces a lie:

```ts
// Don't: the `!` hides a crash on an empty list.
function newest(events: Event[]): Event {
  return events[0]!;
}

// Do: make the input non-empty, or make the result honest.
type NonEmpty<T> = [T, ...T[]];

function newest(events: NonEmpty<Event>): Event {
  return events[0];
}

function newestOrNone(events: Event[]): Event | undefined {
  return events[0];
}
```

Narrow a plain array once, where it arrives:

```ts
const isNonEmpty = <T>(xs: T[]): xs is NonEmpty<T> => xs.length > 0;
```

## Branded types

Use a brand only where IDs of the same primitive get swapped.

```ts
type UserId = string & { readonly __brand: "UserId" };

function parseUserId(input: string): UserId {
  if (!/^usr_[a-z0-9]+$/.test(input)) throw new Error(`Invalid user id: ${input}`);
  return input as UserId; // The only `as`: the check above proved it.
}

function loadUser(id: UserId) { /* trusts id */ }
```

## Derived types

```ts
// Don't: a second copy of a shape that already exists.
type CreateUserInput = { name: string; email: string };
async function createUser(input: CreateUserInput) { /* ... */ }

// Do: derive from the source of truth.
type CreateUserInput = Pick<User, "name" | "email">;
type CreatedUser = Awaited<ReturnType<typeof createUser>>;
```

## `as const` instead of `enum`

```ts
// Don't
enum Role { Admin = "admin", Member = "member" }

// Do
const ROLES = ["admin", "member"] as const;
type Role = (typeof ROLES)[number]; // "admin" | "member"

const isRole = (value: string): value is Role => ROLES.includes(value as Role);
```

## Boundary validation with a schema

Use the schema library the repository already has. The schema is the single source of truth for both the check and the type.

```ts
import { z } from "zod";

const UserSchema = z.object({
  id: z.string(),
  name: z.string(),
  role: z.enum(["admin", "member"]),
});
type User = z.infer<typeof UserSchema>;

async function fetchUser(id: string): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  return UserSchema.parse(await response.json());
}
```

Use `safeParse` when invalid input is an expected branch rather than a bug.

If the type must come first (for example it is generated), annotate the schema with it so the compiler rejects a schema that proves less: `const UserSchema: z.ZodType<User> = z.object({ ... })`.

## Boundary validation without a schema

A guard must check every field it claims.

```ts
// Don't: claims User but checks only one field.
function isUser(value: unknown): value is User {
  return typeof value === "object" && value !== null && "id" in value;
}

// Do
function isUser(value: unknown): value is User {
  return (
    typeof value === "object" &&
    value !== null &&
    "id" in value && typeof value.id === "string" &&
    "name" in value && typeof value.name === "string"
  );
}
```

## Removing an `as`

Find why the compiler cannot infer the type, then fix that cause:

- If the union has no discriminant, add one.
- If the source type is too wide, such as `Record<string, unknown>`, parse it at the boundary.
- If the value comes from outside the program, validate it with the schema or a guard.
- If the type is genuinely inexpressible, use `satisfies` or a verified brand.

## `satisfies`

```ts
type Theme = { mode: "light" | "dark"; columns: number };

// Don't: `as` accepts the missing `columns` and widens `mode` to the union.
const theme = { mode: "dark" } as Theme;

// Do: a missing or misspelled key is a compile error, and `mode` stays "dark".
const theme = { mode: "dark", columns: 3 } satisfies Theme;
```

## Options objects

```ts
// Don't: swapping the two strings still compiles.
function sendInvite(email: string, teamId: string, role: Role) { /* ... */ }

// Do
function sendInvite({ email, teamId, role }: { email: string; teamId: string; role: Role }) { /* ... */ }
```
