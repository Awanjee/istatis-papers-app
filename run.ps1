Set-Location $PSScriptRoot

# Replace DEV_EMAIL and DEV_PASSWORD with your Supabase account credentials.
# These pre-fill the login form in dev only — never passed in deploy.ps1.
flutter run -d chrome `
    --dart-define=SUPABASE_URL=https://nsdjwgqqpskuwnhddqfk.supabase.co `
    --dart-define=SUPABASE_ANON_KEY=sb_publishable_Ou5djg0V1TQrQVJToxoC6g_GqSvkXVt `
    --dart-define=API_URL=https://arco-papers-api.onrender.com `
    --dart-define=DEV_EMAIL=a@b.com `
    --dart-define=DEV_PASSWORD=12345678
