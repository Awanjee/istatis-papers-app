@echo off
cd /d "%~dp0"
echo Building Flutter web for production...
flutter build web ^
  --dart-define=SUPABASE_URL=https://nsdjwgqqpskuwnhddqfk.supabase.co ^
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_Ou5djg0V1TQrQVJToxoC6g_GqSvkXVt ^
  --dart-define=API_URL=https://istatis-papers-api.onrender.com

if errorlevel 1 (
  echo.
  echo ERROR: Flutter build failed. Fix errors above then retry.
  pause
  exit /b 1
)

echo.
echo Build complete. Deploying to Firebase...
firebase deploy

if errorlevel 1 (
  echo.
  echo ERROR: Firebase deploy failed. Are you logged in? Run: firebase login
  pause
  exit /b 1
)

echo.
echo Done. Live at https://arco-papers-app-6b721.web.app
pause
