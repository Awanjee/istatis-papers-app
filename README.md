# Arco Papers App

Flutter front-end for the Arco Papers assistant.

## Run

- Install deps: `flutter pub get`
- Start the app:
  - `flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000`

## Notes

- The backend should expose `POST /chat` returning JSON `{ "response": "...", "session_id": "..." }`.
