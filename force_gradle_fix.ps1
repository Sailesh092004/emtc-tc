# Force fix for Gradle wrapper issues
Write-Host "🔧 Force Fixing Gradle Wrapper" -ForegroundColor Red
Write-Host "===============================" -ForegroundColor Red

Write-Host "`nStep 1: Stopping any running Gradle processes..." -ForegroundColor Yellow
Get-Process -Name "java" -ErrorAction SilentlyContinue | Where-Object {$_.ProcessName -eq "java"} | Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host "`nStep 2: Cleaning everything..." -ForegroundColor Yellow
flutter clean

Write-Host "`nStep 3: Removing ALL Android build artifacts..." -ForegroundColor Yellow
$pathsToRemove = @(
    "android\app\build",
    "android\.gradle", 
    "android\gradle\wrapper\gradle-wrapper.jar",
    "build",
    ".dart_tool"
)

foreach ($path in $pathsToRemove) {
    if (Test-Path $path) {
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Removed: $path" -ForegroundColor Cyan
    }
}

Write-Host "`nStep 4: Creating fresh gradle-wrapper.properties..." -ForegroundColor Yellow
$properties = @"
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.4-all.zip
"@

# Ensure the directory exists
if (!(Test-Path "android\gradle\wrapper")) {
    New-Item -ItemType Directory -Path "android\gradle\wrapper" -Force
}

Set-Content -Path "android\gradle\wrapper\gradle-wrapper.properties" -Value $properties -Force
Write-Host "Created fresh gradle-wrapper.properties" -ForegroundColor Green

Write-Host "`nStep 5: Downloading fresh gradle-wrapper.jar..." -ForegroundColor Yellow
try {
    $jarUrl = "https://github.com/gradle/gradle/raw/v8.4.0/gradle/wrapper/gradle-wrapper.jar"
    $jarPath = "android\gradle\wrapper\gradle-wrapper.jar"
    
    Write-Host "Downloading from: $jarUrl" -ForegroundColor Cyan
    Invoke-WebRequest -Uri $jarUrl -OutFile $jarPath -UseBasicParsing
    
    if (Test-Path $jarPath) {
        $fileSize = (Get-Item $jarPath).Length
        Write-Host "Downloaded gradle-wrapper.jar ($fileSize bytes)" -ForegroundColor Green
    } else {
        throw "File not found after download"
    }
} catch {
    Write-Host "Failed to download gradle-wrapper.jar: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Trying alternative method..." -ForegroundColor Yellow
}

Write-Host "`nStep 6: Testing Gradle wrapper..." -ForegroundColor Yellow
Set-Location "android"
try {
    $result = .\gradlew --version 2>&1
    Write-Host "Gradle version output:" -ForegroundColor Green
    Write-Host $result -ForegroundColor White
} catch {
    Write-Host "Gradle test failed: $($_.Exception.Message)" -ForegroundColor Red
}
Set-Location ".."

Write-Host "`nStep 7: Getting Flutter dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host "`nStep 8: Testing Android build..." -ForegroundColor Yellow
try {
    flutter build apk --debug
    Write-Host "✅ Build successful!" -ForegroundColor Green
} catch {
    Write-Host "❌ Build failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🎯 Force fix completed!" -ForegroundColor Green
Write-Host "`n💡 If still failing:" -ForegroundColor Cyan
Write-Host "1. Check your internet connection" -ForegroundColor White
Write-Host "2. Make sure Java 11+ is installed" -ForegroundColor White
Write-Host "3. Set JAVA_HOME environment variable" -ForegroundColor White
Write-Host "4. Run: flutter doctor" -ForegroundColor White
Write-Host "5. Try: flutter build apk --debug" -ForegroundColor White 