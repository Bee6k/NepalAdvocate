# Flutter Installation Script for Windows
# Run this script as Administrator or in PowerShell

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Flutter Installation Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Flutter is already installed
$flutterPath = "C:\src\flutter\bin\flutter.exe"
if (Test-Path $flutterPath) {
    Write-Host "Flutter is already installed at C:\src\flutter" -ForegroundColor Green
    Write-Host "Adding to PATH..." -ForegroundColor Yellow
    
    # Add to PATH for current session
    $env:Path += ";C:\src\flutter\bin"
    
    Write-Host "Testing Flutter..." -ForegroundColor Yellow
    & $flutterPath --version
    
    Write-Host ""
    Write-Host "Flutter is ready! Run: flutter pub get" -ForegroundColor Green
    exit 0
}

# Create directory
Write-Host "Creating C:\src directory..." -ForegroundColor Yellow
if (-not (Test-Path "C:\src")) {
    New-Item -ItemType Directory -Path "C:\src" -Force | Out-Null
}

# Download Flutter
Write-Host ""
Write-Host "Downloading Flutter SDK (this may take a few minutes)..." -ForegroundColor Yellow
Write-Host "Please wait..." -ForegroundColor Yellow

$flutterZip = "$env:TEMP\flutter.zip"
$flutterUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip"

try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $flutterUrl -OutFile $flutterZip -UseBasicParsing
    Write-Host "Download complete!" -ForegroundColor Green
} catch {
    Write-Host "Download failed. Please download manually from:" -ForegroundColor Red
    Write-Host "https://docs.flutter.dev/get-started/install/windows" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Extract Flutter
Write-Host ""
Write-Host "Extracting Flutter SDK..." -ForegroundColor Yellow
try {
    Expand-Archive -Path $flutterZip -DestinationPath "C:\src" -Force
    Write-Host "Extraction complete!" -ForegroundColor Green
} catch {
    Write-Host "Extraction failed: $_" -ForegroundColor Red
    exit 1
}

# Clean up
Remove-Item $flutterZip -Force

# Add to PATH for current session
$env:Path += ";C:\src\flutter\bin"

# Add to system PATH permanently
Write-Host ""
Write-Host "Adding Flutter to system PATH..." -ForegroundColor Yellow
try {
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*C:\src\flutter\bin*") {
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;C:\src\flutter\bin", "User")
        Write-Host "PATH updated successfully!" -ForegroundColor Green
    } else {
        Write-Host "Flutter already in PATH" -ForegroundColor Green
    }
} catch {
    Write-Host "Could not update PATH automatically. Please add C:\src\flutter\bin manually." -ForegroundColor Yellow
    Write-Host "See FLUTTER_SETUP_WINDOWS.md for instructions" -ForegroundColor Yellow
}

# Verify installation
Write-Host ""
Write-Host "Verifying installation..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

$flutterExe = "C:\src\flutter\bin\flutter.exe"
if (Test-Path $flutterExe) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Flutter installed successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    
    & $flutterExe --version
    
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Close and reopen your terminal" -ForegroundColor White
    Write-Host "2. Run: cd flutter_app" -ForegroundColor White
    Write-Host "3. Run: flutter pub get" -ForegroundColor White
    Write-Host "4. Run: flutter run" -ForegroundColor White
} else {
    Write-Host "Installation verification failed. Please check manually." -ForegroundColor Red
}

