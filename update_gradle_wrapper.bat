@echo off
echo 🔄 Updating Gradle Wrapper
echo ==========================

echo.
echo Step 1: Removing old Gradle wrapper files...
if exist "android\gradle\wrapper\gradle-wrapper.jar" (
    del "android\gradle\wrapper\gradle-wrapper.jar"
)

echo.
echo Step 2: Downloading new Gradle wrapper...
cd android
gradlew wrapper --gradle-version 8.4 --distribution-type all
cd ..

echo.
echo Step 3: Verifying Gradle wrapper...
cd android
gradlew --version
cd ..

echo.
echo Step 4: Cleaning project...
flutter clean

echo.
echo Step 5: Getting dependencies...
flutter pub get

echo.
echo ✅ Gradle wrapper updated successfully!
echo.
echo 💡 If you still see errors:
echo 1. Delete the entire android\.gradle folder
echo 2. Run: flutter clean
echo 3. Run: flutter pub get
echo 4. Try: flutter build apk --debug 