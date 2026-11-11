# Drupal testing

Drupal mechanics for the rules in SKILL.md. The cost rules in "Match the test's structure to its cost" apply to every kernel, functional, and FunctionalJavascript test.

Contents:
- What each level costs
- Choose the level
- Write functional tests as one journey
- Kernel test mechanics
- Class requirements and namespaces
- Running tests
- Gotchas
- Worked example: ABC-718

## What each level costs

| Level | Base class | Setup paid by every test method and every data-provider case |
|---|---|---|
| Unit | `UnitTestCase` | None. Milliseconds. |
| Kernel | `KernelTestBase` | Fresh database plus install of the listed modules, in a separate PHP process. Seconds. |
| Functional | `BrowserTestBase` | Full site install plus a web server request per page. Tens of seconds, more with Commerce. |
| FunctionalJavascript | `WebDriverTestBase` | Functional cost plus a real browser. The slowest level. |

Drupal reinstalls for each test method; `setUpBeforeClass()` cannot share an installed site. So only the number of methods and provider cases controls suite time, not how much each method asserts.

## Choose the level

Go as low on the ladder as the risk allows: unit, then kernel, then functional, then FunctionalJavascript.

- Use a unit test for pure PHP logic with no container: calculators, parsers, value objects. Do not unit-test container-heavy code by mocking services; the mocks break on every refactor and prove little.
- Use a kernel test as the default for Drupal code: services, entities, entity queries, hooks, event subscribers, plugins, access checkers, form validate and submit handlers, controllers, and config schema.
- In a kernel test, use `\Drupal\Tests\HttpKernelUiHelperTrait` to send GET requests through real routing and assert redirects, status codes, and rendered output without a site install. Read the trait in the project's core version for its limits; it has no logged-in user, so set the current user with `UserCreationTrait`.
- Use a functional test only for the business-critical happy path through the real UI, such as checkout or paying an invoice: a multi-request flow with real sessions, forms, and redirects. Keep the functional suite thin.
- Use a FunctionalJavascript test only when that critical path depends on JavaScript, such as AJAX form updates or modal dialogs.
- Do not write Build tests unless the task is about Composer or codebase layout. Do not write Nightwatch tests; core is moving to Playwright.

## Write functional tests as one journey

1. Write one test method per critical journey, not one method per scenario.
2. Create every precondition through the API in `setUp()` or at the top of the method: `Node::create([...])->save()`, `$this->drupalCreateUser([...])`. Do not create a node through `/node/add` unless creating the node is the step under test.
3. Walk the journey in order, asserting at each step: the validation error, the corrected submit, the decline, the recovery, the success, then revisiting earlier steps.
4. Order the steps so each one leaves the state the next one needs, instead of building a fresh fixture per scenario.
5. Pass a message to assertions where a failure would be ambiguous in a long method, such as `$this->assertSame('draft', $state, 'Declined payment leaves the order in draft.')`.
6. Keep `protected static $modules` to what the journey needs, set `protected $defaultTheme = 'stark';`, and do not switch to the `standard` profile.

## Kernel test mechanics

- List every module the test needs in `protected static $modules`, including dependencies. Kernel tests do not resolve module dependencies.
- Install what the test touches in `setUp()`: `$this->installEntitySchema('node')`, `$this->installConfig(['my_module'])`, `$this->installSchema('module', ['table'])`. Kernel tests install no config and create no entity tables on their own. A "table does not exist" error almost always means one of these calls is missing.
- Prefer a contrib kernel base class when it exists, such as `OrderKernelTestBase` for Commerce, over hand-installing the same schema.
- If `setUp()` installs more than a couple of modules or builds fixtures, do not use `@dataProvider` or `#[TestWith]`. Loop over a case table inside one method, create fresh entities per case, and name the case in each assertion message.
- Use a data provider only when `setUp()` is light and the cases are many.

## Class requirements and namespaces

- Put tests under `tests/src/{Unit,Kernel,Functional,FunctionalJavascript}/` with namespace `Drupal\Tests\<module>\{Type}`. The capitalisation of `FunctionalJavascript` matters; a wrong namespace means the runner never discovers the test.
- On Drupal 11.3 and later, add `#[RunTestsInSeparateProcesses]` (`use PHPUnit\Framework\Attributes\RunTestsInSeparateProcesses;`) to every kernel, functional, and FunctionalJavascript class. Omitting it is deprecated in 11.3 and throws in 12.0. On 10.x the base classes already run each test in a separate process, so the attribute is optional. Unit tests never need it.
- Functional and FunctionalJavascript tests must set `protected $defaultTheme`.

## Running tests

Prefix commands with `lando` or `ddev` when the project uses them.

```bash
vendor/bin/phpunit -c web/core web/modules/custom/my_module
vendor/bin/phpunit -c web/core --filter testMethodName web/modules/custom/my_module
```

Kernel and functional tests need `SIMPLETEST_DB`, and functional tests also need `SIMPLETEST_BASE_URL`. Check the project's `phpunit.xml` before assuming they are set; without them PHPUnit fails or skips the tests.

## Gotchas

- Functional tests run two Drupal instances that share a database but not memory: the PHPUnit process and the web server. State set in the test process, such as a registered service or a static cache, is invisible to the site, and vice versa. After a browser request, reload entities with `$storage->resetCache([$id])` before asserting on them. If a cache clear or container rebuild is needed, add a comment saying why.
- In FunctionalJavascript tests, always assert the result of `waitForElement()` and similar waits: `$this->assertNotEmpty($this->assertSession()->waitForElement('css', '#title'));`. They return `NULL` on timeout, so an unasserted wait passes even when the element never appears.
- In kernel tests, the first user created gets uid 1, which bypasses permission checks. Create a throwaway user first when testing access.
- Bug fixes and behavior changes almost always need a test. Look for the existing test and extend it before adding a new class.

## Worked example: ABC-718

Branch ABC-718 of `canadian-hearing-services` added invoice checkout tests that the tech lead flagged: about 7 extra minutes per deploy and a 4x slower suite.

What was written: 22 Drupal setups.
- `Functional/InvoiceCheckoutTest`: 10 methods on `CommerceBrowserTestBase`, each reinstalling Commerce, a gateway, a checkout flow, six fields, a profile, and a payment method, then logging in.
- `Kernel/InvoiceCheckoutAccessTest`: one method with an 8-case data provider, so 8 kernel installs.
- `Kernel/InvoiceCheckoutFlowTest`: 2 methods plus a 2-case provider, so 4 kernel installs.

Target shape, not yet built or measured: about 3 setups with the same coverage.
- One functional journey: open `/invoice/add`, submit empty and see the required-field error, fill the details, pay with a declining method and see the error, fix the method and pay, land on `/complete`, then revisit each earlier step and stay on `/complete`.
- One kernel access method looping over the 8 access cases, plus the case that standard `/checkout` refuses an invoice.
- One kernel flow method covering step redirects, the invalid-step exception, and the controller's canonical redirects through `HttpKernelUiHelperTrait`.
- The two locked-invoice resume tests (success and decline) are single GET requests, so they move into the kernel flow method. If the trait cannot drive the payment step, they become one more step of the journey instead.
- Deleted: `testInvoiceRouteAccess`, which repeated the kernel access matrix, and `testOwnerCanPayStaffCreatedInvoice`, which ran the same payment path as the journey.
