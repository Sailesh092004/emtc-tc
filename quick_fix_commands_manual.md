# Quick Gradle Fix - Manual Commands

Run these commands one by one in PowerShell:

## 1. Clean Flutter Project
```powershell
flutter clean
```

## 2. Remove Build Directories
```powershell
if (Test-Path "build") { Remove-Item -Path "build" -Recurse -Force }
if (Test-Path ".dart_tool") { Remove-Item -Path ".dart_tool" -Recurse -Force }
if (Test-Path "android\.gradle") { Remove-Item -Path "android\.gradle" -Recurse -Force }
if (Test-Path "android\build") { Remove-Item -Path "android\build" -Recurse -Force }
```

## 3. Remove Old Gradle Wrapper
```powershell
if (Test-Path "android\gradle\wrapper\gradle-wrapper.jar") {
    Remove-Item -Path "android\gradle\wrapper\gradle-wrapper.jar" -Force
}
```

## 4. Create Directory (if needed)
```powershell
if (-not (Test-Path "android\gradle\wrapper")) {
    New-Item -ItemType Directory -Path "android\gradle\wrapper" -Force
}
```

## 5. Download Correct Gradle Wrapper
```powershell
Invoke-WebRequest -Uri "https://github.com/gradle/gradle/raw/v8.4.0/gradle/wrapper/gradle-wrapper.jar" -OutFile "android\gradle\wrapper\gradle-wrapper.jar"
```

## 6. Get Dependencies
```powershell
flutter pub get
```

## 7. Test Build
```powershell
flutter build apk --debug
```

## Alternative: Run the Script
Or simply run the PowerShell script:
```powershell
.\quick_gradle_fix.ps1
``` 