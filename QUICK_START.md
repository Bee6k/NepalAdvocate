# Quick Start Guide - NepalAdvocate

## Prerequisites Check

Before starting, ensure you have:

- [ ] Flutter SDK installed and in PATH
- [ ] Android Studio installed
- [ ] Android SDK configured
- [ ] Node.js installed (for backend)
- [ ] MongoDB installed/running (for backend)

## Step-by-Step Setup

### 1. Install Flutter (If Not Installed)

**Windows:**
```powershell
# Download Flutter from https://docs.flutter.dev/get-started/install/windows
# Extract to C:\src\flutter
# Add C:\src\flutter\bin to PATH
# Restart terminal
flutter --version  # Verify installation
```

**See FLUTTER_SETUP_WINDOWS.md for detailed instructions**

### 2. Setup Backend

```bash
cd backend
npm install
# Create .env file (copy from .env.example)
# Update MONGODB_URI and JWT_SECRET
npm run dev
```

Backend will run on `http://localhost:3000`

### 3. Setup Flutter App

```bash
cd flutter_app
flutter pub get
```

### 4. Configure API URLs

Edit `flutter_app/lib/core/constants/api_constants.dart`:

```dart
// For Android Emulator:
static const String baseUrl = 'http://10.0.2.2:3000/api';
static const String wsUrl = 'http://10.0.2.2:3000';

// For Physical Device (replace with your computer's IP):
static const String baseUrl = 'http://192.168.1.100:3000/api';
static const String wsUrl = 'http://192.168.1.100:3000';
```

### 5. Run the App

```bash
cd flutter_app
flutter run
```

Or use Android Studio:
1. Open `flutter_app` folder in Android Studio
2. Click "Run" button

## Troubleshooting

### Flutter Command Not Found
- See `FLUTTER_SETUP_WINDOWS.md`
- Ensure Flutter is in PATH
- Restart terminal/computer

### Backend Connection Issues
- Verify backend is running: `http://localhost:3000/health`
- Check API URL in `api_constants.dart`
- For physical device, use computer's IP address
- Check firewall settings

### Build Errors
```bash
cd flutter_app
flutter clean
flutter pub get
flutter run
```

## Testing Checklist

- [ ] Backend starts successfully
- [ ] Flutter app builds without errors
- [ ] Can register/login
- [ ] Can view dashboard
- [ ] WebView displays templates
- [ ] Can create appointments
- [ ] Chat works

## Need Help?

- Check `SETUP_CHECKLIST.md` for detailed verification
- See `FLUTTER_SETUP_WINDOWS.md` for Flutter installation
- Check backend `README.md` for backend setup

