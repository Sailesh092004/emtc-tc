# Robust Fix for Kotlin and Gradle Issues
Write-Host "Robust Fix for Kotlin and Gradle Issues" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green

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

# Kill any Java/Gradle processes that might be holding files
Write-Host "Stopping any Java/Gradle processes..." -ForegroundColor Yellow
Get-Process -Name "java" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Get-Process -Name "gradle" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# Wait a moment for processes to fully stop
Start-Sleep -Seconds 2

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

# Alternative approach: Let Flutter regenerate the wrapper
Write-Host "Using Flutter to regenerate Gradle wrapper..." -ForegroundColor Yellow

# First, try to remove the wrapper JAR with retry
$maxRetries = 3
$retryCount = 0
$wrapperPath = "android\gradle\wrapper\gradle-wrapper.jar"

while ($retryCount -lt $maxRetries) {
    if (Test-Path $wrapperPath) {
        try {
            Remove-Item -Path $wrapperPath -Force -ErrorAction Stop
            Write-Host "Removed old gradle-wrapper.jar" -ForegroundColor Green
            break
        } catch {
            $retryCount++
            Write-Host "Attempt ${retryCount}: Could not remove gradle-wrapper.jar, waiting..." -ForegroundColor Yellow
            Start-Sleep -Seconds 3
        }
    } else {
        Write-Host "No gradle-wrapper.jar found" -ForegroundColor Yellow
        break
    }
}

# If we couldn't remove it, try downloading with a different name first
if (Test-Path $wrapperPath) {
    Write-Host "Trying alternative download method..." -ForegroundColor Yellow
    $tempPath = "android\gradle\wrapper\gradle-wrapper-new.jar"
    
    try {
        $wrapperUrl = "https://github.com/gradle/gradle/raw/v8.8.0/gradle/wrapper/gradle-wrapper.jar"
        Invoke-WebRequest -Uri $wrapperUrl -OutFile $tempPath
        
        # Try to replace the old file
        try {
            Remove-Item -Path $wrapperPath -Force -ErrorAction Stop
            Move-Item -Path $tempPath -Destination $wrapperPath
            Write-Host "Successfully replaced gradle-wrapper.jar" -ForegroundColor Green
        } catch {
            Write-Host "Could not replace file, but downloaded new version" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Failed to download gradle-wrapper.jar" -ForegroundColor Red
        Write-Host "Will let Flutter handle this..." -ForegroundColor Yellow
    }
} else {
    # Download directly if no existing file
    Write-Host "Downloading gradle-wrapper.jar for Gradle 8.8..." -ForegroundColor Yellow
    $wrapperUrl = "https://github.com/gradle/gradle/raw/v8.8.0/gradle/wrapper/gradle-wrapper.jar"
    
    # Create directory if it doesn't exist
    if (-not (Test-Path "android\gradle\wrapper")) {
        New-Item -ItemType Directory -Path "android\gradle\wrapper" -Force
    }
    
    try {
        Invoke-WebRequest -Uri $wrapperUrl -OutFile $wrapperPath
        Write-Host "Downloaded gradle-wrapper.jar successfully" -ForegroundColor Green
    } catch {
        Write-Host "Failed to download gradle-wrapper.jar" -ForegroundColor Red
        Write-Host "Will let Flutter handle this..." -ForegroundColor Yellow
    }
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