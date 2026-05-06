# Arco Papers App

Flutter web application for the Arco Papers AI platform.
Cross-platform — deployable to web, Android, and iOS.

🌐 **Live:** https://arco-papers-app-6b721.web.app  
🔗 **Backend:** https://github.com/Awanjee/arco-papers-api

## Demo

▶️ [Watch 2-minute demo](https://www.loom.com/share/516dc81b811446ebbfbe28b6fa49836c)

---

## Features

- AI-powered sales assistant with multi-turn memory
- Product catalogue with category filters and pricing tiers
- Suggestion chips for common queries
- Real-time loading states and error handling

## Tech Stack

- Flutter 3.x (Web + Android + iOS)
- Provider — state management
- Dio — HTTP client
- Google Fonts — typography

## Setup

```bash
flutter pub get
flutter run -d chrome
```

Requires backend running at `localhost:8000`  
or update `lib/services/api_service.dart` with
your deployed backend URL.

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