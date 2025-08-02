# Fix Kotlin and Gradle Issues
Write-Host "Fixing Kotlin and Gradle Issues" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green

# Clean Flutter project
Write-Host "Cleaning Flutter project..." -ForegroundColor Yellow
flutter clean

# Remove build directories
Write-Host "Removing build directories..." -ForegroundColor Yellow
if (Test-Path "build") { Remove-Item -Path "build" -Recurse -Force }
if (Test-Path ".dart_tool") { Remove-Item -Path ".dart_tool" -Recurse -Force }
if (Test-Path "android\.gradle") { Remove-Item -Path "android\.gradle" -Recurse -Force }
if (Test-Path "android\build") { Remove-Item -Path "android\build" -Recurse -Force }

# Remove old gradle wrapper JAR
Write-Host "Removing old gradle-wrapper.jar..." -ForegroundColor Yellow
if (Test-Path "android\gradle\wrapper\gradle-wrapper.jar") {
    Remove-Item -Path "android\gradle\wrapper\gradle-wrapper.jar" -Force
}

# Download correct gradle-wrapper.jar for Gradle 8.8
Write-Host "Downloading gradle-wrapper.jar for Gradle 8.8..." -ForegroundColor Yellow
$wrapperUrl = "https://github.com/gradle/gradle/raw/v8.8.0/gradle/wrapper/gradle-wrapper.jar"
$wrapperPath = "android\gradle\wrapper\gradle-wrapper.jar"

# Create directory if it doesn't exist
if (-not (Test-Path "android\gradle\wrapper")) {
    New-Item -ItemType Directory -Path "android\gradle\wrapper" -Force
}

# Download the file
try {
    Invoke-WebRequest -Uri $wrapperUrl -OutFile $wrapperPath
    Write-Host "Downloaded gradle-wrapper.jar successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to download gradle-wrapper.jar" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Clear Gradle caches
Write-Host "Clearing Gradle caches..." -ForegroundColor Yellow
if (Test-Path "$env:USERPROFILE\.gradle\caches") {
    Remove-Item -Path "$env:USERPROFILE\.gradle\caches" -Recurse -Force -ErrorAction SilentlyContinue
}

# Get Flutter dependencies
Write-Host "Getting Flutter dependencies..." -ForegroundColor Yellow
flutter pub get

# Test the build
Write-Host "Testing build..." -ForegroundColor Yellow
flutter build apk --debug

Write-Host "Kotlin and Gradle fix completed!" -ForegroundColor Green 