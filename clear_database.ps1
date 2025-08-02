# Clear Database and Test Fixes
Write-Host "Clearing database and testing fixes..." -ForegroundColor Green

# Stop the app if running
Get-Process -Name "flutter" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# Clean Flutter
flutter clean

# Remove database file
$dbPath = "build\app\intermediates\flutter\debug\flutter_assets\mtc_nanna.db"
if (Test-Path $dbPath) {
    Remove-Item -Path $dbPath -Force
    Write-Host "Removed database file" -ForegroundColor Cyan
}

# Get dependencies
flutter pub get

# Build and test
flutter build apk --debug

Write-Host "Database cleared and app rebuilt!" -ForegroundColor Green
Write-Host "Now test the form submission - it should work without the HashMap error." -ForegroundColor Yellow 