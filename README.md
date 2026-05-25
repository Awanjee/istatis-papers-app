# arco-papers-app

Flutter client for the Arco Papers AI platform. Web-first UI for staff and customers: AI chat, product catalogue, and quote requests against the Python FastAPI backend.

## What this does

- **Sign in / sign up** — Supabase Auth (email/password).
- **AI assistant** — Chat tab calls `POST /chat` on the deployed API with a per-session `session_id`.
- **Product catalogue** — Local product data and navigation (`catalogue_screen.dart`).
- **Request a quote** — Form posts to `POST /quote`; authenticated users can load quote history and create orders via protected endpoints.

## Stack

| Layer | Technology |
|--------|------------|
| UI | Flutter (Dart 3.10+) |
| State | **Provider** + `ChangeNotifier` (`AuthProvider`, `ChatProvider`) |
| HTTP | Dio |
| Auth | `supabase_flutter` |
| Backend | [arco-papers-api](https://github.com/Awanjee/arco-papers-api) on Render |

## Project structure

```
arco_papers_app/lib/
├── main.dart
├── config/supabase_config.dart
├── providers/
│   ├── auth_provider.dart
│   └── chat_provider.dart
├── services/api_service.dart
├── screens/
│   ├── home_screen.dart      # Bottom nav: Chat | Catalogue | Quote
│   ├── catalogue_screen.dart
│   ├── quote_screen.dart
│   └── auth/
├── models/
├── widgets/
└── theme/app_theme.dart
```

## Prerequisites

- Flutter SDK (see `pubspec.yaml` for Dart `^3.10.8`)
- Supabase project (same as backend)
- Running or deployed `arco-papers-api`

## Configuration

Supabase is injected at build/run time (not committed):

```powershell
flutter run -d chrome `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

API base URL is in `lib/services/api_service.dart`:

- Production: `https://arco-papers-api.onrender.com`
- Local: uncomment `http://127.0.0.1:8000` when running Uvicorn locally

Protected routes (`/quotes/history`, `/orders`) send the Supabase access token in the `Authorization: Bearer` header.

## Local run

```powershell
cd arco_papers_app
flutter pub get
flutter run -d chrome --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

For full flows (quote history, orders), run the backend locally or point at Render and ensure `SUPABASE_JWT_SECRET` is set on the API.

## Features by tab

| Tab | Screen | Backend |
|-----|--------|---------|
| Chat | `HomeScreen` → chat tab | `POST /chat` |
| Catalogue | `CatalogueScreen` | Mostly local `products_data.dart` |
| Quote | `QuoteScreen` | `POST /quote`, `GET /quotes/history`, `POST /orders` |

## Planned / not yet in app

- Dedicated payment-status dashboard
- WhatsApp message history in UI
- Public marketing landing at `/` separate from authenticated portal

## Related

- Backend: [arco-papers-api](https://github.com/Awanjee/arco-papers-api)
