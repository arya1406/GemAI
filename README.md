<div align="center">

# ✦ GemAI

### _AI assistant for you and you alone._

**No chats collected. No data sent. Just you.**

<br/>

[![Flutter](https://img.shields.io/badge/Flutter-3.2%2B-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Gemma](https://img.shields.io/badge/Gemma-3%201B%20INT4-4285F4?style=flat-square&logo=google&logoColor=white)](https://ai.google.dev/gemma)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=flat-square)](https://flutter.dev)

</div>

---

## What is GemAI?

GemAI is a **privacy-first, offline AI assistant** built with Flutter. It runs Google's Gemma model entirely on your device — no internet required, no servers involved, no data ever leaving your hands. Everything stays local. Everything stays yours.

Think of it as a personal AI that genuinely respects you.

---

## Features

| Feature                  | Details                                                               |
| ------------------------ | --------------------------------------------------------------------- |
| **On-Device AI**         | Powered by Gemma 3 1B-IT (INT4) via MediaPipe — runs fully offline    |
| **Private by Design**    | Zero telemetry, zero data collection, zero cloud dependency           |
| **Voice Input**          | Speak naturally — real-time speech-to-text transcription              |
| **Image Input**          | Pick photos from your gallery or camera and chat about them           |
| **Markdown Responses**   | AI replies render with rich formatting — bold, lists, and code blocks |
| **Conversation History** | Chats are stored locally with Drift (SQLite) — searchable, persistent |
| **Online Fallback**      | Optionally switch to Gemini API when you need more capability         |
| **Onboarding Flow**      | Smooth first-launch experience with model setup guidance              |
| **Theme Support**        | Light, Dark, and System-adaptive themes                               |

---

## Architecture

GemAI is built on **Clean Architecture** principles with a strict separation of concerns:

```
lib/
├── core/          # Shared utilities, DB, error handling, constants
├── data/          # Repositories, data sources (local & remote)
├── domain/        # Entities, use cases, repository interfaces
└── presentation/  # Screens, widgets, providers (Riverpod)
```

**Tech Stack:**

- **UI & Framework** — Flutter (FVM managed, SDK ≥ 3.2.0)
- **State Management** — Riverpod 3.x
- **Local Database** — Drift (type-safe SQLite with code generation)
- **On-Device AI** — `flutter_gemma` (MediaPipe GenAI)
- **Online AI** — Gemini API via `google_generative_ai`
- **Voice** — `speech_to_text`
- **Media** — `image_picker`

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.2.0 (or use [FVM](https://fvm.app))
- Android device/emulator (API 24+) or iOS device (iOS 16+)
- The Gemma 3 1B-IT INT4 model file (`.task`) placed in `assets/models/`

### Setup

```bash
# Clone the repo
git clone https://github.com/arya1406/GemAI.git
cd GemAI

# Install dependencies
flutter pub get

# Run code generation (Drift)
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

> **Note:** The model file (`gemma3-1b-it-int4.task`) is not included in the repo due to its size. Download it from [Google AI Edge](https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference) and place it in `assets/models/`.

---

## The Goal

Most AI assistants treat your conversations as a resource — something to train on, analyse, and store. GemAI exists to flip that model entirely.

The aim is simple: **powerful AI, zero compromise on privacy.** Every feature decision is filtered through this lens — if it requires sending your data somewhere, it doesn't ship by default.

---

## Roadmap

These are the areas being actively explored for future releases:

- [ ] **Multi-model support** — swap between different on-device models
- [ ] **RAG (Retrieval-Augmented Generation)** — chat with your own documents and notes
- [ ] **Conversation search** — full-text search across local chat history
- [ ] **Export & backup** — encrypted local export of conversations
- [ ] **Custom system prompts** — set your own AI persona and instructions
- [ ] **iOS optimisations** — Core ML acceleration for faster inference
- [ ] **Widget & notification support** — quick-access AI from your home screen

---

## Contributing

Contributions are welcome. If you find a bug, have a feature idea, or want to improve the codebase — open an issue or a pull request. Please keep changes focused and consistent with the clean architecture pattern already in place.

---

## License

MIT — see [LICENSE](LICENSE) for details.

---

<div align="center">

_Built with care. Designed for privacy._
**GemAI — yours, entirely.**

</div>
