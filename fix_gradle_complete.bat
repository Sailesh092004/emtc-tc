@echo off
echo 🔧 Complete Gradle Fix
echo =====================

echo.
echo Step 1: Cleaning everything...
flutter clean

if exist "android\app\build" (
    rmdir /s /q "android\app\build"
)

if exist "android\.gradle" (
    rmdir /s /q "android\.gradle"
)

echo.
echo Step 2: Removing old Gradle wrapper...
if exist "android\gradle\wrapper\gradle-wrapper.jar" (
    del "android\gradle\wrapper\gradle-wrapper.jar"
)

echo.
echo Step 3: Downloading fresh Gradle wrapper...
cd android
curl -o gradle\wrapper\gradle-wrapper.jar https://github.com/gradle/gradle/raw/v8.4.0/gradle/wrapper/gradle-wrapper.jar
cd ..

echo.
echo Step 4: Updating gradle-wrapper.properties...
echo distributionBase=GRADLE_USER_HOME > android\gradle\wrapper\gradle-wrapper.properties
echo distributionPath=wrapper/dists >> android\gradle\wrapper\gradle-wrapper.properties
echo zipStoreBase=GRADLE_USER_HOME >> android\gradle\wrapper\gradle-wrapper.properties
echo zipStorePath=wrapper/dists >> android\gradle\wrapper\gradle-wrapper.properties
echo distributionUrl=https\://services.gradle.org/distributions/gradle-8.4-all.zip >> android\gradle\wrapper\gradle-wrapper.properties

echo.
echo Step 5: Testing Gradle...
cd android
gradlew --version
cd ..

echo.
echo Step 6: Getting Flutter dependencies...
flutter pub get

echo.
echo ✅ Complete Gradle fix applied!
echo.
echo 💡 Next steps:
echo 1. Try: flutter build apk --debug
echo 2. If still failing, check your internet connection
echo 3. Make sure Java 11+ is installed and JAVA_HOME is set 