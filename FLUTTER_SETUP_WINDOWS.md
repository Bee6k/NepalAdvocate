# Flutter Setup Guide for Windows

## Error: Flutter command not recognized

If you see the error `flutter : The term 'flutter' is not recognized`, Flutter is either not installed or not added to your system PATH.

## Solution: Install Flutter on Windows

### Step 1: Download Flutter SDK

1. Go to [https://docs.flutter.dev/get-started/install/windows](https://docs.flutter.dev/get-started/install/windows)
2. Download the latest stable Flutter SDK (ZIP file)
3. Extract the ZIP file to a location like:
   - `C:\src\flutter` (recommended)
   - Or `C:\Users\YourUsername\flutter`

**Important:** Do NOT install Flutter in:
- A path with spaces (e.g., `C:\Program Files\flutter`)
- A path with special characters
- A path that requires admin privileges

### Step 2: Add Flutter to PATH

#### Option A: Using System Environment Variables (Recommended)

1. Press `Win + R` and type `sysdm.cpl`, then press Enter
2. Click the **Advanced** tab
3. Click **Environment Variables**
4. Under **User variables**, find `Path` and click **Edit**
5. Click **New** and add: `C:\src\flutter\bin` (or your Flutter installation path)
6. Click **OK** on all dialogs
7. **Restart your terminal/PowerShell** for changes to take effect

#### Option B: Using PowerShell (Temporary - Current Session Only)

```powershell
$env:Path += ";C:\src\flutter\bin"
```

### Step 3: Verify Installation

Open a **new** PowerShell/Command Prompt window and run:

```powershell
flutter --version
```

You should see Flutter version information. If you still get an error, restart your computer.

### Step 4: Run Flutter Doctor

Check if everything is set up correctly:

```powershell
flutter doctor
```

This will show what's installed and what's missing.

### Step 5: Install Required Dependencies

Based on `flutter doctor` output, you may need:

1. **Android Studio** (for Android development):
   - Download from [https://developer.android.com/studio](https://developer.android.com/studio)
   - Install Android SDK, Android SDK Platform-Tools, and Android Emulator

2. **Android SDK Command-line Tools**:
   - Open Android Studio → SDK Manager → SDK Tools
   - Install "Android SDK Command-line Tools"

3. **Accept Android Licenses**:
   ```powershell
   flutter doctor --android-licenses
   ```
   Press `y` to accept all licenses

### Step 6: Install Flutter Dependencies

Once Flutter is recognized, navigate to your project and install dependencies:

```powershell
cd C:\Users\acer\Desktop\NepalAdvoczte\flutter_app
flutter pub get
```

## Quick Fix: Using Flutter from Full Path

If you don't want to add Flutter to PATH right now, you can use the full path:

```powershell
C:\src\flutter\bin\flutter.exe pub get
```

(Replace `C:\src\flutter` with your actual Flutter installation path)

## Alternative: Use Git to Clone Flutter

If you have Git installed:

```powershell
cd C:\src
git clone https://github.com/flutter/flutter.git -b stable
```

Then add `C:\src\flutter\bin` to PATH as described above.

## Verify Everything Works

After setup, run these commands:

```powershell
# Check Flutter version
flutter --version

# Check Flutter setup
flutter doctor

# Install project dependencies
cd C:\Users\acer\Desktop\NepalAdvoczte\flutter_app
flutter pub get

# Check if you can run Flutter
flutter devices
```

## Common Issues

### Issue: "flutter: command not found" after adding to PATH
- **Solution**: Restart your terminal/PowerShell completely
- If still not working, restart your computer

### Issue: "Android toolchain - develop for Android devices" shows errors
- **Solution**: Install Android Studio and Android SDK
- Run `flutter doctor --android-licenses` to accept licenses

### Issue: "Visual Studio - develop for Windows" shows errors
- **Solution**: This is optional for Android-only development
- You can ignore this if you're only building for Android

## Next Steps After Flutter Installation

1. ✅ Flutter installed and in PATH
2. ✅ Run `flutter doctor` and fix any issues
3. ✅ Navigate to project: `cd flutter_app`
4. ✅ Run `flutter pub get`
5. ✅ Run `flutter run` to test the app

## Need Help?

- Flutter Documentation: [https://docs.flutter.dev](https://docs.flutter.dev)
- Flutter Community: [https://flutter.dev/community](https://flutter.dev/community)

