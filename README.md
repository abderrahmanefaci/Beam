# Beam - AI-Powered Document Intelligence Platform

Turn any document into an interactive, intelligent experience.

## Project Structure

```
lib/
├── core/                    # Core utilities, constants, theme
│   ├── constants/
│   ├── errors/
│   ├── theme/
│   └── utils/
├── data/                    # Data layer (models, repositories, data sources)
│   ├── models/
│   ├── repositories/
│   └── sources/
├── domain/                  # Domain layer (entities, repositories, usecases)
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── presentation/            # UI layer (screens, widgets, providers)
│   ├── screens/
│   ├── widgets/
│   └── providers/
├── services/                # App services
└── main.dart               # App entry point
```

## Tech Stack

- **Frontend:** Flutter (iOS + Android)
- **Backend:** Supabase (PostgreSQL + Auth + Storage)
- **AI Router:** Supabase Edge Functions (Deno)
- **AI Models:** Gemini Flash 2.0, GPT-4o Mini, Chinese AI (Qwen/DeepSeek)

## Key Features

1. **Built-in Document Scanner** - Multi-page scanning with filters
2. **Universal File Editor** - PDF, DOCX, XLSX, PPTX, MD, TXT, Images
3. **AI Layer** - Summarize, Translate, Extract, Chat, Custom Agent
4. **Tools Tab** - Merge, Split, Compress, Convert, E-Signature
5. **Freemium Model** - 3 AI-unlocked docs free, then paywall

## Development Tasks

| Task | Description | Status |
|------|-------------|--------|
| 1 | Setup & Dependencies | ✅ Complete |
| 2 | Supabase Schema & Auth | ⏳ Pending |
| 3 | Home Screen | ⏳ Pending |
| 4 | Built-in Document Scanner | ⏳ Pending |
| 5 | Document Library | ⏳ Pending |
| 6 | Universal File Editor | ⏳ Pending |
| 7 | AI Overlay & Standard Skills | ⏳ Pending |
| 8 | Custom AI Agent | ⏳ Pending |
| 9 | Tools Tab | ⏳ Pending |
| 10 | E-Signature & Profile | ⏳ Pending |
| 11 | Paywall & Monetization | ⏳ Pending |
| 12 | Polish, Performance & Launch | ⏳ Pending |

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Supabase account
- API keys for AI providers

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure environment variables:
   - Create `.env` file or use `--dart-define`:
   ```bash
   flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Your Supabase anon/public key |
| `GEMINI_API_KEY` | Google AI API key (Edge Function) |
| `OPENAI_API_KEY` | OpenAI API key (Edge Function) |
| `CHINESE_AI_API_KEY` | Qwen/DeepSeek API key (Edge Function) |
| `CLOUDCONVERT_API_KEY` | CloudConvert API key |

## Monetization

- **Free Plan:** 3 AI-unlocked documents, 10 version history per doc
- **Premium Plan:** Unlimited AI (50 credits/month), unlimited version history

## License

Proprietary - All rights reserved

---

**Version:** 1.0.0  
**Last Updated:** 2026
