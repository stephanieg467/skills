# Stephanie's AI Skills

These are the skills that I created myself and use on a daily basis. Copy and paste them if you must but they are meant to provide inspiration so that you can be inspired by them, and get ideas to create your own.
 
## Application Verification

- `create-verification-skill` discovers how an application runs, generates a project-local `verify-<app>` skill and feature map, and proves one journey end to end. It follows the target repository's skill-location convention and asks when ambiguous.
- `maintain-verification-skill` audits the generated skill against source and live behavior, correcting documentation and harness drift without changing product code.

`plan-implementation` plans relevant runtime journeys. `implement-plan`, `implement-and-review`, and fix-mode `cross-review` run them and retain evidence instead of handing routine smoke checks to you. They ask before creating a missing verification skill. Blocked verification is reported explicitly; read-only reviews remain read-only.

## Acknowledgments
* `create-verification-skill` and `maintain-verification-skill`: Adapted from the [pstack skills](https://github.com/cursor/plugins/tree/2776ddd2355d6d6c8747d3964600f28daf62f049/pstack/skills) by [Lauren Tan (poteto)](https://github.com/poteto), distributed under the MIT license retained in each skill directory.
* `drupal-knowledge`: Inspired by the structure and logic of the [`drupal-expert`](https://github.com/madsnorgaard/drupal-agent-resources/blob/main/.claude/skills/drupal-expert/SKILL.md) skill by [madsnorgaard](https://github.com/madsnorgaard).
* `cross-review`: Inspired by the structure and logic of the [`code-review-and-quality`](https://github.com/addyosmani/agent-skills) skill by [Addy Osmani](https://github.com/addyosmani) and the [`code-review`](https://github.com/mattpocock/skills) skill by [Matt Pocock](https://github.com/mattpocock).
* `implement-plan`: Inspired by the structure and logic of the [`piv-implement`](https://github.com/coleam00/skills) skill by [Cole Medin](https://github.com/coleam00) and the [`incremental-implementation`](https://github.com/addyosmani/agent-skills) skill by [Addy Osmani](https://github.com/addyosmani).
* `testing-standards` (`references/drupal.md`): Drupal mechanics adapted from a `drupal-automated-testing` skill based on guidance by phenaproxima ([Drupal core issue #3581672](https://www.drupal.org/project/drupal/issues/3581672)), with its test-level and data-provider advice replaced by cost-aware guidance.
