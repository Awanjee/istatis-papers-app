param(
    [string]$msg = "deploy: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
)

Set-Location $PSScriptRoot

Write-Host "Building Flutter web..." -ForegroundColor Cyan

flutter build web --release `
    --dart-define=SUPABASE_URL=https://nsdjwgqqpskuwnhddqfk.supabase.co `
    --dart-define=SUPABASE_ANON_KEY=sb_publishable_Ou5djg0V1TQrQVJToxoC6g_GqSvkXVt `
    --dart-define=API_URL=https://arco-papers-api.onrender.com

if ($LASTEXITCODE -ne 0) {
    Write-Host "Flutter build failed. Fix errors above and retry." -ForegroundColor Red
    exit 1
}

Write-Host "Committing and pushing..." -ForegroundColor Cyan
git add .
git commit -m $msg
git push

Write-Host "Deploying to Firebase..." -ForegroundColor Cyan
firebase deploy --only hosting

if ($LASTEXITCODE -ne 0) {
    Write-Host "Firebase deploy failed. Are you logged in? Run: firebase login" -ForegroundColor Red
    exit 1
}

Write-Host "Done. Live at https://arco-papers-app-6b721.web.app" -ForegroundColor Green
