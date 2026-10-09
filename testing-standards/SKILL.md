---
name: testing-standards
description: Standards for writing meaningful, reliable, fast tests in any framework. Use whenever writing, adding, changing, reviewing, deleting, or debugging tests, including test-only helpers, mocks, and fixtures, even when the user never mentions testing standards. Also use when tests are slow, flaky, intermittent, hanging, or timing out locally or in CI, and when deciding whether a change needs a test at all.
---

# Testing Standards

A test earns its place only when it can catch a realistic regression that would otherwise slip through. This skill decides whether to write a test, how to write it, and how to keep it fast without weakening it. It does not require test-first development; when the user wants red-green-refactor, use the `tdd` skill for the loop and this skill for test quality.

## Decide whether a test is worth writing

- Before writing a test, name the realistic bug it would catch. If you cannot name one, do not write the test and say why.
- Config-only or one-line changes usually need no new test. Say so explicitly rather than adding one.
- Test application behavior, business rules, and trust boundaries.
- Do not write tests that mirror the implementation or data. Examples: asserting config, YAML, or constant values; asserting that a method returns the literal it hardcodes; asserting the contents of a file the test just read. A test that must be edited every time the code changes is not a test.
- Prefer the smallest test level that still covers the real risk.
- If the real risk can only be covered by a heavier test (kernel, functional, end-to-end) that is not practical, do not substitute a shallow unit test. List the manual smoke check instead.
- When reviewing or cleaning up, deleting low-value tests is a valid and encouraged outcome.

## Keep tests and production code separate

- Do not put functions that only tests use in production code. Keep test-specific code in the relevant test files or folders.
- Avoid unnecessary fixtures, abstractions, and dependencies.
- Do not use mock call-count expectations (`toHaveBeenCalledTimes(1)`, `expects($this->once())`) unless the number of calls is itself the behavior under test, such as preventing a duplicate charge.
- Do not mock away the input handling or business logic the test is meant to cover.

## Writing Good Tests

### Test State, Not Interactions

Assert on the *outcome* of an operation, not on which methods were called internally. Tests that verify method call sequences break when you refactor, even if the behavior is unchanged.

```typescript
// Good: Tests what the function does (state-based)
it('returns tasks sorted by creation date, newest first', async () => {
  const tasks = await listTasks({ sortBy: 'createdAt', sortOrder: 'desc' });
  expect(tasks[0].createdAt.getTime())
    .toBeGreaterThan(tasks[1].createdAt.getTime());
});

// Bad: Tests how the function works internally (interaction-based)
it('calls db.query with ORDER BY created_at DESC', async () => {
  await listTasks({ sortBy: 'createdAt', sortOrder: 'desc' });
  expect(db.query).toHaveBeenCalledWith(
    expect.stringContaining('ORDER BY created_at DESC')
  );
});
```

Test through the public API. Do not test private methods directly.

### DAMP Over DRY in Tests

In production code, DRY (Don't Repeat Yourself) is usually right. In tests, **DAMP (Descriptive And Meaningful Phrases)** is better. A test should read like a specification — each test should tell a complete story without requiring the reader to trace through shared helpers.

```typescript
// DAMP: Each test is self-contained and readable
it('rejects tasks with empty titles', () => {
  const input = { title: '', assignee: 'user-1' };
  expect(() => createTask(input)).toThrow('Title is required');
});

it('trims whitespace from titles', () => {
  const input = { title: '  Buy groceries  ', assignee: 'user-1' };
  const task = createTask(input);
  expect(task.title).toBe('Buy groceries');
});

// Over-DRY: Shared setup obscures what each test actually verifies
// (Don't do this just to avoid repeating the input shape)
```

Duplication in tests is acceptable when it makes each test independently understandable.

Use `beforeEach` to reset shared state (fresh mocks, stores, DOM) so every test starts clean. Use it rather than `beforeAll` or `before` for anything a test can mutate. Keep the scenario-specific inputs inside each test.

### Prefer Real Implementations Over Mocks

Use the simplest test double that gets the job done. The more your tests use real code, the more confidence they provide.

```
Preference order (most to least preferred):
1. Real implementation  → Highest confidence, catches real bugs
2. Fake                 → In-memory version of a dependency (e.g., fake DB)
3. Stub                 → Returns canned data, no behavior
4. Mock (interaction)   → Verifies method calls — use sparingly
```

**Use mocks only when:** the real implementation is too slow, non-deterministic, or has side effects you can't control (external APIs, email sending). Over-mocking creates tests that pass while production breaks.

### Use the Arrange-Act-Assert Pattern

```typescript
it('marks overdue tasks when deadline has passed', () => {
  // Arrange: Set up the test scenario
  const task = createTask({
    title: 'Test',
    deadline: new Date('2025-01-01'),
  });

  // Act: Perform the action being tested
  const result = checkOverdue(task, new Date('2025-01-02'));

  // Assert: Verify the outcome
  expect(result.isOverdue).toBe(true);
});
```

Keep test logic flat and deterministic. Do not branch with `if` inside a test, and do not nest callbacks when `await` will do.

### One Assertion Per Concept

Multiple `expect` calls are fine when they verify one concept.

```typescript
// Good: Each test verifies one behavior
it('rejects empty titles', () => { ... });
it('trims whitespace from titles', () => { ... });
it('enforces maximum title length', () => { ... });

// Bad: Everything in one test
it('validates titles correctly', () => {
  expect(() => createTask({ title: '' })).toThrow();
  expect(createTask({ title: '  hello  ' }).title).toBe('hello');
  expect(() => createTask({ title: 'a'.repeat(256) })).toThrow();
});
```

Cover the edge cases and error paths of the behavior under test: empty strings, `null`, `undefined`, zero, negative numbers, and the catch or error branches.

### Name Tests Descriptively

Group tests in `describe` blocks by method or feature.

```typescript
// Good: Reads like a specification
describe('TaskService.completeTask', () => {
  it('sets status to completed and records timestamp', ...);
  it('throws NotFoundError for non-existent task', ...);
  it('is idempotent — completing an already-completed task is a no-op', ...);
  it('sends notification to task assignee', ...);
});

// Bad: Vague names
describe('TaskService', () => {
  it('works', ...);
  it('handles errors', ...);
  it('test 3', ...);
});
```

## Test Anti-Patterns to Avoid

| Anti-Pattern | Problem | Fix |
|---|---|---|
| Testing implementation details | Tests break when refactoring even if behavior is unchanged | Test inputs and outputs, not internal structure |
| Flaky tests (timing, order-dependent) | Erode trust in the test suite | Use deterministic assertions, isolate test state |
| Testing framework code | Wastes time testing third-party behavior | Only test YOUR code; not path resolution, parsing, plugin discovery, or that `Array.map` works |
| Snapshot abuse | Large snapshots nobody reviews, break on any change | Use snapshots sparingly and review every change |
| No test isolation | Tests pass individually but fail together | Each test sets up and tears down its own state; never rely on execution order |
| Shared mutable state | A `let` changed by one test leaks into the next | Reassign it in `beforeEach` |
| Mocking everything | Tests pass but production breaks | Prefer real implementations > fakes > stubs > mocks. Mock only at boundaries where real deps are slow or non-deterministic |
| No assertions | The test always passes | Every test asserts an observable outcome |
| Committed `.skip` or `.only` | Silently drops coverage | Fix or delete the test instead |
| Giant test files | Hard to navigate and slow to run | Keep test files focused; split by feature area. Do not split an existing file as part of an unrelated change |

## Choose input interactions by intent

1. Read the test, the component, and the relevant input handlers before choosing an input helper.
2. Name what the test protects: the final value and what happens after it, or the entry process itself.
3. If only the final value matters, and the actual control and installed library support paste, enter the whole value at once.
4. If the test protects individual keystrokes, keyboard events, input restrictions, masking or formatting during entry, debounce behavior, or intermediate validation states, keep typing.
5. Check number, date, masked, and other specialized inputs explicitly. Do not generalize from text inputs, or from one numeric value to negative and decimal values; run the existing assertions for each kind of value.
6. Preserve tab, blur, submit, and native validation steps where they exist.
7. Do not replace realistic interactions with direct value assignment or low-level events when that bypasses the behavior under test.

React Testing Library with `@testing-library/user-event`:

```tsx
// Final value matters: the test asserts the submitted payment payload.
await user.clear(tipInput);   // focuses and empties the field
await user.paste("15.00");    // pastes into whichever element has focus

// Entry matters: the test asserts formatting as each digit arrives.
await user.type(cardInput, "42424");
expect(cardInput).toHaveValue("4242 4");
```

## Keep tests fast without weakening them

- A slow unit test is usually testing too much. Reduce the work, not the coverage.
- Avoid character-by-character entry, repeated setup, real-time sleeps, and redundant polling when they are not part of the behavior under test.
- Await every user interaction and every piece of asynchronous work.
- Wait for observable outcomes with the existing test tools (`findBy*`, `waitFor`, the framework's equivalents), not arbitrary delays.
- Keep actions outside retrying assertion callbacks. A `waitFor` that contains a click or a submit may repeat that side effect on every retry.
- Use fake timers only when time-dependent behavior is under test and you understand how they integrate with the framework and the interaction library. They are not a blanket speed fix.
- Preserve meaningful inputs and assertions when optimizing. A faster test that covers less is a regression.

## Diagnose a slow, flaky, or timing-out test

1. Run the relevant tests before the change with verbose per-test timings (Jest `--verbose`, Vitest `--reporter=verbose`, or the framework's equivalent) and record them.
2. Find the cause. Distinguish expensive interaction work from unresolved promises, incorrect waits, timers, and leaked work from earlier tests.
3. Treat that cause. Do not raise the timeout, skip the test, remove coverage, mock away the cause, or add a dependency to hide slow execution.
4. Run the same tests after the change. Use the existing assertions as the regression check; do not add tests whose only purpose is to prove the choice of input helper.
5. Report timings as observations from that run, not as guarantees.
6. If the failure only happens in CI, reproduce it under a comparable CPU constraint (for example `taskset -c 0` on Linux) or name the CI run that still needs to pass. Do not claim CI is fixed unless that check actually ran.

A genuinely long operation may justify a larger timeout, but only with evidence and an explicit reason in the report.

## Gotchas

- `user.paste(text)` takes no target element. It pastes into the focused element. `user.clear(field)` focuses and empties the field, so call it first; otherwise the value lands in whatever had focus last. `user.type(field, text)` clicks the field itself, so a mechanical swap from type to paste can silently fill the wrong field.
- Preserve pasted values exactly. A PayHQ payload test pastes `" Ada "` with surrounding spaces because it verifies trimming; "cleaning" the value would delete that coverage.
- In the PayHQ case, a payload test hit Jest's 5-second timeout intermittently in GitHub CI because it typed seven values character by character while asserting only the final payload. Switching to `clear` plus `paste` kept every assertion and passed under the same CPU constraint. The fix was scoped to that test; the other `user.type` calls in the file were not swapped blindly.
- `type="number"` inputs need their own check. In `PaymentMethodForm.test.tsx`, pasting `"5"`, `"15.00"`, and `"-5"` into the tip field was safe only after confirming the component had no keyboard or paste handlers, Formik ran with `validateOnChange={false}`, and the existing assertions passed for the decimal and negative values too.
- Keep setup steps that exist for a reason. One existing tip test removes the input's `min` attribute before entering `"-5"` and then tabs to blur. The optimization kept both steps exactly. Never add or remove attributes just to make an optimization pass.
- One local run proves little. Across all 24 `PaymentMethodForm` tests the suite went from 3.511s to 3.240s, yet one individual test got slower.
