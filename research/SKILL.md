---
name: research
description: Investigate a question against high-trust primary sources and capture the findings as a Markdown file in the repo. Use when the user wants a topic researched, docs or API facts gathered, or reading legwork delegated to a background agent.
---

Hand the research to the `researcher` subagent and run it in the background, so you keep working while it reads.

Its brief is the only context it gets, so include:

- The question, and the decision the answer feeds.
- What is already known or ruled out.
- The output file path. Save it where the repo already keeps such notes; if there is no convention, pick somewhere sensible.

When it finishes, tell the user the file path, the summary, and any contradictions or missing evidence it flagged. Don't redo its research.
