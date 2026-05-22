# Arco Papers App

Flutter web application for the Arco Papers AI platform.
Cross-platform — deployable to web, Android, and iOS.

🌐 **Live:** https://arco-papers-app-6b721.web.app  
🔗 **Backend:** https://github.com/Awanjee/arco-papers-api

## Demo

▶️ [Watch 2-minute demo](https://www.loom.com/share/516dc81b811446ebbfbe28b6fa49836c)

---

## Features

- Supabase email/password auth (login, signup, auth gate)
- AI-powered sales assistant with multi-turn memory
- Product catalogue with category filters and pricing tiers
- Quote requests (guest-friendly; email pre-filled when logged in)
- Protected API: quote history and orders (Bearer JWT)
- Suggestion chips for common queries
- Real-time loading states and error handling

## Tech Stack

- Flutter 3.x (Web + Android + iOS)
- Supabase Auth (`supabase_flutter`)
- Provider — state management
- Dio — HTTP client
- Google Fonts — typography

## Setup

```bash
flutter pub get
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Use the **anon** public key from Supabase (never the service role key).

Requires backend at `https://arco-papers-api.onrender.com` or local
`localhost:8000` (toggle `_baseUrl` in `lib/services/api_service.dart`).

### Supabase dashboard

1. Authentication → Providers → Email → enabled  
2. Add site URL: `https://arco-papers-app-6b721.web.app` and `http://localhost:*`  
3. For local dev, you may disable email confirmation or confirm via inbox  

### Firebase deploy

```bash
flutter build web \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
firebase deploy --only hosting
```

## Structure
lib/
├── main.dart
├── models/
│   ├── message.dart
│   └── product.dart
├── data/
│   └── products_data.dart
├── services/
│   └── api_service.dart
├── providers/
│   └── chat_provider.dart
├── screens/
│   ├── home_screen.dart
│   └── catalogue_screen.dart
└── widgets/
├── chat_bubble.dart
├── chat_input.dart
└── suggestion_chips.dart

## Author

**Muhammad Usama Awan** — github.com/Awanjee