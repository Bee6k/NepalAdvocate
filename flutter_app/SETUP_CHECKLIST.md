# NepalAdvocate Flutter App - Setup Checklist

## Pre-requisites
- [ ] Flutter SDK installed (3.0+)
- [ ] Android Studio installed
- [ ] Android SDK configured
- [ ] Android device/emulator ready

## Initial Setup

### 1. Install Dependencies
```bash
cd flutter_app
flutter pub get
```

### 2. Android Configuration
- [x] AndroidManifest.xml configured
- [x] build.gradle configured
- [x] MainActivity.kt created
- [x] Internet permission added
- [x] WebView support enabled
- [x] MultiDex enabled

### 3. API Configuration
Update `lib/core/constants/api_constants.dart`:
- [ ] Set `baseUrl` to your backend URL
  - Emulator: `http://10.0.2.2:3000/api`
  - Physical device: `http://YOUR_IP:3000/api`
- [ ] Set `wsUrl` to your WebSocket URL
  - Emulator: `http://10.0.2.2:3000`
  - Physical device: `http://YOUR_IP:3000`

### 4. WebView URLs (Optional)
Update `lib/views/webview/terms_privacy_screen.dart`:
- [ ] Set Terms of Service URL
- [ ] Set Privacy Policy URL
- [ ] Set About page URL

## Running the App

### Development
```bash
flutter run
```

### Build APK
```bash
flutter build apk --release
```

## Verification Checklist

### Authentication
- [ ] Can register as Client
- [ ] Can register as Lawyer
- [ ] Can login
- [ ] Persistent login works
- [ ] Logout works

### Appointments
- [ ] Can create appointment request
- [ ] Can view appointments
- [ ] Can propose time (Lawyer)
- [ ] Can confirm appointment
- [ ] Both parties confirmation works

### Chat
- [ ] Can open chat
- [ ] Can send messages
- [ ] Real-time messages work
- [ ] Message history loads

### Documents
- [ ] Can upload document
- [ ] Can view document list
- [ ] Upload progress shows
- [ ] Can delete document

### WebView Features
- [ ] Legal templates display in WebView
- [ ] Terms/Privacy pages load
- [ ] Navigation controls work
- [ ] Error handling works
- [ ] Loading indicators show

### Dashboards
- [ ] Client dashboard loads
- [ ] Lawyer dashboard loads
- [ ] Admin dashboard loads
- [ ] Quick actions work

## Troubleshooting

### WebView Issues
- Check internet permission in AndroidManifest.xml
- Verify URL is accessible
- Check network connectivity
- Ensure `usesCleartextTraffic="true"` for HTTP URLs

### API Connection Issues
- Verify backend is running
- Check API URL in api_constants.dart
- Verify network connectivity
- Check firewall settings

### Build Issues
- Run `flutter clean`
- Run `flutter pub get`
- Delete `build/` folder
- Restart IDE

## Next Steps
1. Test all features
2. Update Terms/Privacy URLs
3. Configure production API URLs
4. Test on physical device
5. Build release APK

