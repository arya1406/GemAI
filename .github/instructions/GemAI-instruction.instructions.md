---
description: Describe when these instructions should be loaded by the agent based on task context
# applyTo: 'Describe when these instructions should be loaded by the agent based on task context' # when provided, instructions will automatically be added to the request context when the pattern matches an attached file
---

<!-- Tip: Use /create-instructions in chat to generate content with agent assistance -->

Role: Senior Flutter & AI Mobile Engineer.
Project Context: "GemAI" - A privacy-first, offline-only AI assistant using local Gemma 4 models. Slogan: "AI assistant for you and you alone. No data/chats collected."

Tech Stack & Constraints:

- Flutter (Managed via FVM, SDK >= 3.2.0)
- State Management: Riverpod (Strictly use @riverpod code generation)
- Local DB: Drift (Strictly use code generation, type-safe DAOs)
- Architecture: Strict Clean Architecture (core, data, domain, presentation)

Coding Standards (CRITICAL):

- Output ONLY production-ready, highly modular code.
- BE CONCISE. Skip pleasantries, introductions, and generic explanations to save tokens.
- Secure Coding: NO hardcoded credentials/keys.
- Clean Code: Adhere to SOLID, DRY. Avoid deep widget trees (extract them).
- Documentation: Always include clear DartDoc (`///`) for classes, providers, and Drift tables.

Workflow: Provide minimal, precise, and compile-ready code snippets. When modifying files, show only the changed blocks if possible.
