# Simple Gradle Fix
Write-Host "Fixing Gradle Wrapper..." -ForegroundColor Green

# Clean everything first
flutter clean
Remove-Item -Path "android\.gradle" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "android\app\build" -Recurse -Force -ErrorAction SilentlyContinue

# Remove old wrapper JAR if it exists
if (Test-Path "android\gradle\wrapper\gradle-wrapper.jar") {
    Remove-Item -Path "android\gradle\wrapper\gradle-wrapper.jar" -Force
    Write-Host "Removed old gradle-wrapper.jar" -ForegroundColor Cyan
}

# Download correct wrapper JAR
try {
    Invoke-WebRequest -Uri "https://github.com/gradle/gradle/raw/v8.4.0/gradle/wrapper/gradle-wrapper.jar" -OutFile "android\gradle\wrapper\gradle-wrapper.jar" -UseBasicParsing
    Write-Host "Downloaded new gradle-wrapper.jar" -ForegroundColor Green
} catch {
    Write-Host "Download failed. Letting Flutter regenerate..." -ForegroundColor Yellow
}

# Test and build
flutter pub get
flutter build apk --debug

Write-Host "Gradle fix completed!" -ForegroundColor Green 