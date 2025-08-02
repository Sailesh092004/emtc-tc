# Quick Fix Commands for Gradle Issue

## Run these commands one by one in PowerShell:

### 1. Clean everything
```powershell
flutter clean
```

### 2. Remove Android build artifacts
```powershell
Remove-Item -Path "android\app\build" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "android\.gradle" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "android\gradle\wrapper\gradle-wrapper.jar" -Force -ErrorAction SilentlyContinue
```

### 3. Download fresh gradle-wrapper.jar
```powershell
Invoke-WebRequest -Uri "https://github.com/gradle/gradle/raw/v8.4.0/gradle/wrapper/gradle-wrapper.jar" -OutFile "android\gradle\wrapper\gradle-wrapper.jar" -UseBasicParsing
```

### 4. Update gradle-wrapper.properties
```powershell
$properties = @"
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.4-all.zip
"@
Set-Content -Path "android\gradle\wrapper\gradle-wrapper.properties" -Value $properties -Force
```

### 5. Test Gradle
```powershell
cd android
.\gradlew --version
cd ..
```

### 6. Get Flutter dependencies
```powershell
flutter pub get
```

### 7. Test build
```powershell
flutter build apk --debug
```

## Alternative: Use the script
```powershell
.\force_gradle_fix.ps1
```

## Why this works:
- Removes the old `gradle-wrapper.jar` that's hardcoded to Gradle 7.6.3
- Downloads the correct JAR file for Gradle 8.4
- Updates the properties file to match
- Cleans all cached build artifacts 