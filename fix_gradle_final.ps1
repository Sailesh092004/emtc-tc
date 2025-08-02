# Final Gradle Fix - Complete Reset
Write-Host "Final Gradle Fix - Complete Reset" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

# Stop any running processes
Write-Host "Stopping any running processes..." -ForegroundColor Yellow
Get-Process -Name "java" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Get-Process -Name "gradle" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# Clean Flutter
Write-Host "Cleaning Flutter project..." -ForegroundColor Yellow
flutter clean

# Remove all build directories
Write-Host "Removing all build directories..." -ForegroundColor Yellow
$directories = @("build", ".dart_tool", "android\build", "android\.gradle")
foreach ($dir in $directories) {
    if (Test-Path $dir) {
        try {
            Remove-Item -Path $dir -Recurse -Force -ErrorAction Stop
            Write-Host "Removed $dir" -ForegroundColor Green
        } catch {
            Write-Host "Could not remove $dir (may be in use)" -ForegroundColor Yellow
        }
    }
}

# Remove old Gradle wrapper completely
Write-Host "Removing old Gradle wrapper..." -ForegroundColor Yellow
if (Test-Path "android\gradle\wrapper") {
    try {
        Remove-Item -Path "android\gradle\wrapper" -Recurse -Force -ErrorAction Stop
        Write-Host "Removed old gradle wrapper directory" -ForegroundColor Green
    } catch {
        Write-Host "Could not remove gradle wrapper directory" -ForegroundColor Yellow
    }
}

# Create fresh gradle wrapper directory
Write-Host "Creating fresh gradle wrapper directory..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path "android\gradle\wrapper" -Force

# Create gradle-wrapper.properties
Write-Host "Creating gradle-wrapper.properties..." -ForegroundColor Yellow
$properties = @"
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.8-all.zip
"@
Set-Content -Path "android\gradle\wrapper\gradle-wrapper.properties" -Value $properties

# Download fresh gradle-wrapper.jar
Write-Host "Downloading fresh gradle-wrapper.jar..." -ForegroundColor Yellow
try {
    $wrapperUrl = "https://github.com/gradle/gradle/raw/v8.8.0/gradle/wrapper/gradle-wrapper.jar"
    Invoke-WebRequest -Uri $wrapperUrl -OutFile "android\gradle\wrapper\gradle-wrapper.jar" -UseBasicParsing
    Write-Host "Downloaded gradle-wrapper.jar successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to download gradle-wrapper.jar" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
}

# Clear Gradle caches
Write-Host "Clearing Gradle caches..." -ForegroundColor Yellow
if (Test-Path "$env:USERPROFILE\.gradle\caches") {
    try {
        Remove-Item -Path "$env:USERPROFILE\.gradle\caches" -Recurse -Force -ErrorAction Stop
        Write-Host "Cleared Gradle caches" -ForegroundColor Green
    } catch {
        Write-Host "Could not clear all Gradle caches" -ForegroundColor Yellow
    }
}

# Get Flutter dependencies
Write-Host "Getting Flutter dependencies..." -ForegroundColor Yellow
flutter pub get

# Test Gradle wrapper
Write-Host "Testing Gradle wrapper..." -ForegroundColor Yellow
Set-Location "android"
try {
    .\gradlew --version
    Write-Host "Gradle wrapper test successful" -ForegroundColor Green
} catch {
    Write-Host "Gradle wrapper test failed" -ForegroundColor Red
}
Set-Location ".."

# Test the build
Write-Host "Testing build..." -ForegroundColor Yellow
flutter build apk --debug

Write-Host "Final Gradle fix completed!" -ForegroundColor Green 