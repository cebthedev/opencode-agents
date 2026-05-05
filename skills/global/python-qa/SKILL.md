---
name: python-qa
description: Evaluates Python code quality using Ruff, Black, and Pylint via uv. Use this when asked to lint, format, or check code standards.
---

When the user asks you to lint, format, or check the code, use your Bash tool to execute the following commands using Astral's `uvx` command runner. 

Follow these steps sequentially:

1. **Format Code (Black):** Run `uvx black .`
2. **Fast Linting & Auto-fixes (Ruff):** Run `uvx ruff check . --fix`
3. **Deep Static Analysis (Pylint):** Run `uvx pylint $(find . -name "*.py")` (or target the specific module directory).

Analyze the output from these commands. If there are remaining errors that Ruff couldn't auto-fix or Pylint warnings, explain them to the user and offer to patch the code to resolve them.
