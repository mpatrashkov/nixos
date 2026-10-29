---
name: code-style
description: Readability-first style for writing, editing, refactoring, or reviewing code.
---

# Code style

- No one-line conditionals or loops, even for early returns. Use braces where supported; one statement per line.
- Separate logical blocks with blank lines; keep related statements together.
- Avoid dense expressions, nested ternaries, and clever chains. Use clear steps and meaningful intermediate names; keep simple idioms concise.
- Prefer guard clauses over deep nesting and explicit control flow over hidden side effects.
- Wrap long expressions and argument lists for readability. Keep functions focused.
- Follow project instructions and required formatters. Preserve behavior in style-only edits; do not reformat unrelated or generated code.
