---
name: testing-standards
description: Standards for writing meaningful, reliable, fast tests in any framework, including Drupal (PHPUnit unit, kernel, functional, FunctionalJavascript), e2e, and browser tests. Use whenever writing, adding, changing, reviewing, consolidating, deleting, or debugging tests, including test-only helpers, mocks, and fixtures, even when the user never mentions testing standards. Also use when tests or the test suite are slow, flaky, intermittent, hanging, timing out, or adding too much CI or deploy time, and when deciding whether a change needs a test at all or which test level to use.
---

# Testing Standards

A test earns its place only when it can catch a realistic regression that would otherwise slip through, at a cost the suite can afford. This skill decides whether to write a test, at which level, how to structure it, and how to keep it fast without weakening it. It does not require test-first development; when the user wants red-green-refactor, use the `tdd` skill for the loop and this skill for test quality.

## References

- `references/drupal.md`: read before writing, reviewing, or speeding up any Drupal test (unit, kernel, functional, FunctionalJavascript).
- `references/ui-input-interactions.md`: read before choosing between typing, pasting, or setting values in UI component tests (for example React Testing Library with `user-event`).

## Decide whether a test is worth writing

- Before writing a test, name the realistic bug it would catch. If you cannot name one, do not write the test and say why.
- Config-only or one-line changes usually need no new test. Say so explicitly rather than adding one.
- Test application behavior, business rules, and trust boundaries.
- Do not write tests that mirror the implementation or data. Examples: asserting config, YAML, or constant values; asserting that a method returns the literal it hardcodes; asserting the contents of a file the test just read. A test that must be edited every time the code changes is not a test.
- Do not cover the same behavior twice. If a lower-level test already covers a rule, a higher-level test must not re-check it.
- If the real risk can only be covered by a heavier test that is not practical, do not substitute a shallow unit test. Use the project's verification skill to exercise the real user journey when feasible; otherwise report the coverage gap and unmet prerequisite explicitly.
- When reviewing or cleaning up, deleting or merging low-value tests is a valid and encouraged outcome.

## Match the test's structure to its cost

Most testing advice (one behavior per test, many small focused tests, fresh setup per test) assumes tests that run in milliseconds. It does not carry over to tests that boot a framework, install a database, or drive a browser. There, every test method pays the full setup again, so ten tidy methods cost ten setups.

1. Classify each test you write as cheap or expensive. A test is cheap if it runs in milliseconds with no framework boot, database, network, or browser. Every other test is expensive.
2. Put each behavior at the cheapest level that still exercises its real risk. Pure logic goes in unit tests. Services, persistence, access rules, and routing go in integration tests. Only what genuinely needs a browser goes in browser tests.
3. Reserve the most expensive level (functional, end-to-end, browser) for business-critical happy paths, such as checkout, sign-up, or payment: the journeys whose breakage would be an outage. Edge cases, error branches, validation rules, and access matrices belong one level down.
4. In expensive tests, write one test method per journey. Walk the steps in order and assert at each step, instead of splitting each assertion into its own method.
5. Do not use data providers or parameterized cases on expensive tests, because each case re-runs the full setup. Loop over a case table inside one method and put the case name in each assertion message.
6. Build preconditions directly through the API or the database, not the UI. Only the step under test goes through the UI.
7. Before finishing, state how many expensive setups the suite adds (expensive methods plus parameterized cases). If two setups could become one without losing coverage, merge them.

## Writing cheap tests

The rules in this section are for cheap tests. Expensive tests follow "Match the test's structure to its cost" first.

### Test state, not interactions

Assert on the outcome of an operation, not on which methods were called internally. Tests that verify call sequences break on refactors even when behavior is unchanged.

```typescript
// Good: tests what the function does.
it('returns tasks sorted by creation date, newest first', async () => {
  const tasks = await listTasks({ sortBy: 'createdAt', sortOrder: 'desc' });
  expect(tasks[0].createdAt.getTime()).toBeGreaterThan(tasks[1].createdAt.getTime());
});

// Bad: tests how the function works internally.
it('calls db.query with ORDER BY created_at DESC', async () => {
  await listTasks({ sortBy: 'createdAt', sortOrder: 'desc' });
  expect(db.query).toHaveBeenCalledWith(expect.stringContaining('ORDER BY created_at DESC'));
});
```

Test through the public API. Do not test private methods directly.

### DAMP over DRY

A test should read like a specification: each test tells a complete story without the reader tracing shared helpers. Duplication is acceptable when it keeps each test independently understandable. Keep the scenario-specific inputs inside each test.

Use `beforeEach` to reset shared state (fresh mocks, stores, DOM) so every test starts clean. Use it rather than `beforeAll` for anything a test can mutate.

### One behavior per test

Multiple assertions are fine when they verify one behavior. Separate behaviors get separate tests, because a cheap test costs nothing to split and a focused failure is easier to read.

```typescript
it('rejects empty titles', () => { ... });
it('trims whitespace from titles', () => { ... });
it('enforces maximum title length', () => { ... });
```

Cover the edge cases and error paths of the behavior under test: empty strings, `null`, `undefined`, zero, negative numbers, and the error branches. Cheap tests are where edge cases belong.

### Name tests descriptively

Group tests by method or feature, and name each one after the behavior it protects (`throws NotFoundError for non-existent task`), never `works` or `test 3`.

## Rules for every test

- Do not put functions that only tests use in production code. Keep test-specific code in the relevant test files or folders.
- Avoid unnecessary fixtures, abstractions, and dependencies.
- Prefer real implementations over test doubles: real, then fake, then stub, then mock. Mock only where the real dependency is slow, non-deterministic, or has side effects you cannot control (external APIs, email, payment gateways).
- Do not mock away the input handling or business logic the test is meant to cover.
- Do not use mock call-count expectations (`toHaveBeenCalledTimes(1)`, `expects($this->once())`) unless the number of calls is itself the behavior, such as preventing a duplicate charge.
- Keep test logic flat and deterministic. Do not branch with `if` inside a test, and do not nest callbacks when `await` will do. Looping over a fixed case table is fine.
- Arrange, act, then assert. Every test asserts an observable outcome.

## Test anti-patterns to avoid

| Anti-pattern | Problem | Fix |
|---|---|---|
| One expensive test per assertion | Setup cost multiplies; the suite gets slow with no extra coverage | One method per journey; push edge cases down a level |
| Parameterized expensive tests | Each case repeats the full setup | Loop over cases inside one method |
| Same behavior covered at several levels | Pays twice for one guarantee | Keep it at the cheapest level that covers the risk |
| Building preconditions through the UI | Slow and couples unrelated tests to the form | Create them through the API; only the step under test uses the UI |
| Testing implementation details | Breaks on refactors with unchanged behavior | Test inputs and outputs |
| Flaky tests (timing, order-dependent) | Erode trust in the suite | Deterministic assertions, isolated state |
| Testing framework code | Wastes time on third-party behavior | Only test your code; not path resolution, parsing, plugin discovery, or `Array.map` |
| Snapshot abuse | Large snapshots nobody reviews | Use sparingly and review every change |
| Shared mutable state between cheap tests | A `let` changed by one test leaks into the next | Reassign it in `beforeEach` |
| No assertions | The test always passes | Assert an observable outcome |
| Committed `.skip` or `.only` | Silently drops coverage | Fix or delete the test |

## Keep tests fast without weakening them

- A slow cheap test is usually testing too much. Reduce the work, not the coverage.
- A slow suite of expensive tests is usually paying for too many setups. Merge methods and move behaviors down a level before tuning individual tests.
- Avoid repeated setup, real-time sleeps, and redundant polling when they are not part of the behavior under test.
- Await every user interaction and every piece of asynchronous work.
- Wait for observable outcomes with the framework's tools (`findBy*`, `waitFor`, `waitForElement`), not arbitrary delays.
- Keep actions outside retrying assertion callbacks. A `waitFor` that contains a click or a submit may repeat that side effect on every retry.
- Use fake timers only when time-dependent behavior is under test. They are not a blanket speed fix.
- Preserve meaningful inputs and assertions when optimizing. A faster test that covers less is a regression.

## Diagnose a slow, flaky, or timing-out test

1. Run the relevant tests before the change with per-test timings (Jest `--verbose`, Vitest `--reporter=verbose`, PHPUnit `--log-junit`, or the framework's equivalent) and record them.
2. Find the cause. Distinguish setup cost repeated across methods, expensive interaction work, unresolved promises, incorrect waits, timers, and leaked work from earlier tests.
3. Treat that cause. Do not raise the timeout, skip the test, remove coverage, mock away the cause, or add a dependency to hide slow execution.
4. Run the same tests after the change. Use the existing assertions as the regression check.
5. Report timings as observations from that run, not as guarantees.
6. If the failure only happens in CI, reproduce it under a comparable CPU constraint (for example `taskset -c 0` on Linux) or name the CI run that still needs to pass. Do not claim CI is fixed unless that check actually ran.

A genuinely long operation may justify a larger timeout, but only with evidence and an explicit reason in the report.

## Gotchas

- Clean-code testing advice silently assumes millisecond unit tests. Applying "small focused tests" and "use data providers" to Drupal functional and kernel tests is what bloated ABC-718: 10 functional methods and 12 kernel runs added about 7 minutes to every deploy and made the suite 4x slower. See the worked example in `references/drupal.md`.
- A test level is not chosen once per feature. One feature usually needs a thin top-level journey plus most of its rules tested one level down; writing every scenario at the level where the first test landed is the common mistake.
- When asked to "add coverage" for a bug fix, extend the existing journey or case table first. Adding a new expensive method is the last resort.
