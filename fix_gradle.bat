@echo off
echo 🔧 Fixing Gradle Build Issues
echo =============================

echo.
echo Step 1: Cleaning Flutter project...
flutter clean

echo.
echo Step 2: Cleaning Android build...
if exist "android\app\build" (
    rmdir /s /q "android\app\build"
)

if exist "android\.gradle" (
    rmdir /s /q "android\.gradle"
)

echo.
echo Step 3: Updating Gradle wrapper...
cd android
gradlew wrapper --gradle-version 8.4
cd ..

echo.
echo Step 4: Getting Flutter dependencies...
flutter pub get

echo.
echo Step 5: Testing Android build...
flutter build apk --debug

echo.
echo ✅ Gradle build issues should be fixed!
echo.
echo 💡 If you still have issues:
echo 1. Make sure you have Java 11+ installed
echo 2. Set JAVA_HOME environment variable
echo 3. Run: flutter doctor
echo 4. Check your internet connection for Gradle downloads 