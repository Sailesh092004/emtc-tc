# Flutter Project Optimization Script
# This script helps clean up and optimize Flutter projects for faster builds

Write-Host "🧹 Flutter Project Optimization Script" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

# Function to check if Flutter is installed
function Test-Flutter {
    try {
        $flutterVersion = flutter --version
        Write-Host "✅ Flutter is installed" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ Flutter is not installed or not in PATH" -ForegroundColor Red
        return $false
    }
}

# Function to clean Flutter project
function Clean-FlutterProject {
    Write-Host "`n🧹 Cleaning Flutter project..." -ForegroundColor Yellow
    
    # Remove build directories
    if (Test-Path "build") {
        Write-Host "Removing build directory..." -ForegroundColor Cyan
        Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    if (Test-Path ".dart_tool") {
        Write-Host "Removing .dart_tool directory..." -ForegroundColor Cyan
        Remove-Item -Path ".dart_tool" -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    if (Test-Path ".flutter-plugins") {
        Write-Host "Removing .flutter-plugins file..." -ForegroundColor Cyan
        Remove-Item -Path ".flutter-plugins" -Force -ErrorAction SilentlyContinue
    }
    
    if (Test-Path ".flutter-plugins-dependencies") {
        Write-Host "Removing .flutter-plugins-dependencies file..." -ForegroundColor Cyan
        Remove-Item -Path ".flutter-plugins-dependencies" -Force -ErrorAction SilentlyContinue
    }
    
    # Clean Android build
    if (Test-Path "android/app/build") {
        Write-Host "Removing Android build directory..." -ForegroundColor Cyan
        Remove-Item -Path "android/app/build" -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Clean iOS build
    if (Test-Path "ios/Pods") {
        Write-Host "Removing iOS Pods directory..." -ForegroundColor Cyan
        Remove-Item -Path "ios/Pods" -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    Write-Host "✅ Project cleaned successfully" -ForegroundColor Green
}

# Function to get dependencies
function Get-FlutterDependencies {
    Write-Host "`n📦 Getting Flutter dependencies..." -ForegroundColor Yellow
    flutter pub get
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Dependencies installed successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
    }
}

# Function to analyze project
function Analyze-FlutterProject {
    Write-Host "`n🔍 Analyzing Flutter project..." -ForegroundColor Yellow
    flutter analyze
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Project analysis completed" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Project analysis found issues" -ForegroundColor Yellow
    }
}

# Function to show optimization tips
function Show-OptimizationTips {
    Write-Host "`n💡 Optimization Tips:" -ForegroundColor Cyan
    Write-Host "==================" -ForegroundColor Cyan
    Write-Host "1. Use 'flutter run --release' for faster builds" -ForegroundColor White
    Write-Host "2. Consider using 'flutter build apk --split-per-abi' for smaller APKs" -ForegroundColor White
    Write-Host "3. Use 'flutter pub deps' to analyze dependency tree" -ForegroundColor White
    Write-Host "4. Consider removing unused dependencies from pubspec.yaml" -ForegroundColor White
    Write-Host "5. Use 'flutter doctor' to check for issues" -ForegroundColor White
    Write-Host "6. Consider using 'flutter build web --web-renderer html' for web builds" -ForegroundColor White
}

# Main execution
if (Test-Flutter) {
    $choice = Read-Host "`nChoose an option:`n1. Clean project only`n2. Clean and get dependencies`n3. Full optimization (Clean + Dependencies + Analyze)`n4. Show optimization tips only`nEnter your choice (1-4):"
    
    switch ($choice) {
        "1" {
            Clean-FlutterProject
        }
        "2" {
            Clean-FlutterProject
            Get-FlutterDependencies
        }
        "3" {
            Clean-FlutterProject
            Get-FlutterDependencies
            Analyze-FlutterProject
        }
        "4" {
            Show-OptimizationTips
        }
        default {
            Write-Host "Invalid choice. Running full optimization..." -ForegroundColor Yellow
            Clean-FlutterProject
            Get-FlutterDependencies
            Analyze-FlutterProject
        }
    }
    
    Show-OptimizationTips
} else {
    Write-Host "Please install Flutter first: https://flutter.dev/docs/get-started/install" -ForegroundColor Red
}

Write-Host "`n🎉 Optimization script completed!" -ForegroundColor Green 