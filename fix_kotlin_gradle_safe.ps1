# Safe Fix for Kotlin and Gradle Issues
Write-Host "Safe Fix for Kotlin and Gradle Issues" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green

# Clean Flutter project
Write-Host "Cleaning Flutter project..." -ForegroundColor Yellow
flutter clean

# Stop any running Gradle daemons
Write-Host "Stopping Gradle daemons..." -ForegroundColor Yellow
try {
    & "$env:USERPROFILE\.gradle\wrapper\dists\gradle-*\*\bin\gradle.bat" --stop 2>$null
} catch {
    Write-Host "No Gradle daemons to stop" -ForegroundColor Yellow
}

# Remove build directories with error handling
Write-Host "Removing build directories..." -ForegroundColor Yellow
$directories = @("build", ".dart_tool", "android\build")
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

# Try to remove android\.gradle with retry
Write-Host "Removing android\.gradle..." -ForegroundColor Yellow
if (Test-Path "android\.gradle") {
    try {
        Remove-Item -Path "android\.gradle" -Recurse -Force -ErrorAction Stop
        Write-Host "Removed android\.gradle" -ForegroundColor Green
    } catch {
        Write-Host "Could not remove android\.gradle (files in use)" -ForegroundColor Yellow
        Write-Host "This is normal if Gradle is running" -ForegroundColor Yellow
    }
}

# Remove old gradle wrapper JAR
Write-Host "Removing old gradle-wrapper.jar..." -ForegroundColor Yellow
if (Test-Path "android\gradle\wrapper\gradle-wrapper.jar") {
    try {
        Remove-Item -Path "android\gradle\wrapper\gradle-wrapper.jar" -Force -ErrorAction Stop
        Write-Host "Removed old gradle-wrapper.jar" -ForegroundColor Green
    } catch {
        Write-Host "Could not remove old gradle-wrapper.jar" -ForegroundColor Yellow
    }
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

# Clear Gradle caches with error handling
Write-Host "Clearing Gradle caches..." -ForegroundColor Yellow
if (Test-Path "$env:USERPROFILE\.gradle\caches") {
    try {
        Remove-Item -Path "$env:USERPROFILE\.gradle\caches" -Recurse -Force -ErrorAction Stop
        Write-Host "Cleared Gradle caches" -ForegroundColor Green
    } catch {
        Write-Host "Could not clear all Gradle caches (some files in use)" -ForegroundColor Yellow
    }
}

# Get Flutter dependencies
Write-Host "Getting Flutter dependencies..." -ForegroundColor Yellow
flutter pub get

# Test the build
Write-Host "Testing build..." -ForegroundColor Yellow
flutter build apk --debug

Write-Host "Kotlin and Gradle fix completed!" -ForegroundColor Green 