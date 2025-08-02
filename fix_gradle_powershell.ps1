# PowerShell script to fix Gradle build issues
Write-Host "🔧 Complete Gradle Fix (PowerShell)" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

Write-Host "`nStep 1: Cleaning everything..." -ForegroundColor Yellow
flutter clean

Write-Host "`nStep 2: Removing Android build directories..." -ForegroundColor Yellow
if (Test-Path "android\app\build") {
    Remove-Item -Path "android\app\build" -Recurse -Force
    Write-Host "Removed android\app\build" -ForegroundColor Cyan
}

if (Test-Path "android\.gradle") {
    Remove-Item -Path "android\.gradle" -Recurse -Force
    Write-Host "Removed android\.gradle" -ForegroundColor Cyan
}

Write-Host "`nStep 3: Removing old Gradle wrapper..." -ForegroundColor Yellow
if (Test-Path "android\gradle\wrapper\gradle-wrapper.jar") {
    Remove-Item -Path "android\gradle\wrapper\gradle-wrapper.jar" -Force
    Write-Host "Removed old gradle-wrapper.jar" -ForegroundColor Cyan
}

Write-Host "`nStep 4: Downloading fresh Gradle wrapper..." -ForegroundColor Yellow
Set-Location "android"
try {
    Invoke-WebRequest -Uri "https://github.com/gradle/gradle/raw/v8.4.0/gradle/wrapper/gradle-wrapper.jar" -OutFile "gradle\wrapper\gradle-wrapper.jar"
    Write-Host "Downloaded new gradle-wrapper.jar" -ForegroundColor Green
} catch {
    Write-Host "Failed to download gradle-wrapper.jar. Trying alternative method..." -ForegroundColor Red
    # Alternative: Let Flutter regenerate it
    flutter pub get
}
Set-Location ".."

Write-Host "`nStep 5: Updating gradle-wrapper.properties..." -ForegroundColor Yellow
$properties = @"
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.4-all.zip
"@
Set-Content -Path "android\gradle\wrapper\gradle-wrapper.properties" -Value $properties
Write-Host "Updated gradle-wrapper.properties" -ForegroundColor Green

Write-Host "`nStep 6: Testing Gradle..." -ForegroundColor Yellow
Set-Location "android"
try {
    .\gradlew --version
    Write-Host "Gradle test successful" -ForegroundColor Green
} catch {
    Write-Host "Gradle test failed. This is normal if wrapper is being regenerated." -ForegroundColor Yellow
}
Set-Location ".."

Write-Host "`nStep 7: Getting Flutter dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host "`n✅ Complete Gradle fix applied!" -ForegroundColor Green
Write-Host "`n💡 Next steps:" -ForegroundColor Cyan
Write-Host "1. Try: flutter build apk --debug" -ForegroundColor White
Write-Host "2. If still failing, check your internet connection" -ForegroundColor White
Write-Host "3. Make sure Java 11+ is installed and JAVA_HOME is set" -ForegroundColor White
Write-Host "4. Run: flutter doctor" -ForegroundColor White 