@echo off
echo 🧹 Flutter Project Cleanup Script
echo ================================

echo.
echo Cleaning Flutter project...

if exist "build" (
    echo Removing build directory...
    rmdir /s /q "build"
)

if exist ".dart_tool" (
    echo Removing .dart_tool directory...
    rmdir /s /q ".dart_tool"
)

if exist ".flutter-plugins" (
    echo Removing .flutter-plugins file...
    del ".flutter-plugins"
)

if exist ".flutter-plugins-dependencies" (
    echo Removing .flutter-plugins-dependencies file...
    del ".flutter-plugins-dependencies"
)

if exist "android\app\build" (
    echo Removing Android build directory...
    rmdir /s /q "android\app\build"
)

echo.
echo ✅ Project cleaned successfully!
echo.
echo 💡 Next steps:
echo 1. Run: flutter pub get
echo 2. Run: flutter run
echo.
echo 💡 Tips for faster builds:
echo - Use: flutter run --release
echo - Use: flutter build apk --split-per-abi
echo - Remove unused dependencies from pubspec.yaml
echo - Run: flutter doctor to check for issues 