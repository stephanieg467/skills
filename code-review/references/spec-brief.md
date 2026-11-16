# Spec Review Brief

Compare the diff against the spec in your prompt. Report:

1. Requirements the spec asked for that are missing or only partly implemented.
2. Requirements that look implemented but behave wrongly.
3. Behaviour in the diff that nobody asked for (scope creep).
4. Breaking changes that the spec does not call out.

Quote the spec line for each finding.

If a post-implementation report is supplied:

- Treat its claims (tests run, journeys passed, decisions) as claims to verify against the diff, not as facts. Report any claim the diff contradicts or you could not confirm.
- Treat its "Deviations from the plan" as intentional. Flag a deviation only if it breaks an acceptance criterion.
