# NepalAdvocate Flutter App

Flutter mobile application for NepalAdvocate - Lawyer Booking & Counseling App.

## Features

- ✅ JWT-based authentication with persistent login
- ✅ Role-based dashboards (Client, Lawyer, Admin)
- ✅ Appointment booking and management
- ✅ Real-time chat using Socket.IO
- ✅ Document upload and management
- ✅ Lawyer search and profiles
- ✅ Legal templates with WebView viewer
- ✅ WebView integration for web content
- ✅ Notifications
- ✅ Dark mode elegant UI

## Project Structure

```
lib/
├── core/
│   ├── constants/      # App constants, API endpoints
│   ├── theme/          # App theme, colors, typography
│   └── utils/          # Utilities (API client, storage)
├── models/             # Data models
├── services/           # API services
├── controllers/        # Riverpod state management
├── views/              # Screen widgets
│   ├── auth/          # Authentication screens
│   ├── dashboards/     # Role-specific dashboards
│   ├── appointments/   # Appointment screens
│   ├── chat/           # Chat screens
│   ├── documents/      # Document screens
│   ├── lawyers/        # Lawyer screens
│   └── settings/       # Settings screens
└── widgets/            # Reusable widgets
    └── common/         # Common UI components
```

## Setup

1. Install Flutter dependencies:
```bash
cd flutter_app
flutter pub get
```

2. Update API base URL in `lib/core/constants/api_constants.dart`:
```dart
static const String baseUrl = 'http://YOUR_IP:3000/api';
static const String wsUrl = 'http://YOUR_IP:3000';
```

3. Run the app:
```bash
flutter run
```

## Configuration

### Android Setup
- Minimum SDK: 21 (Android 5.0)
- Target SDK: 34
- Permissions: Internet, Storage, Camera (for document uploads)
- WebView: Configured and ready (supports HTTP/HTTPS)
- MultiDex: Enabled for better compatibility

### API Configuration
Update `ApiConstants` with your backend URL:
- For Android Emulator: `http://10.0.2.2:3000`
- For Physical Device: `http://YOUR_COMPUTER_IP:3000`

## Key Features Implementation

### Authentication
- JWT token stored securely using `flutter_secure_storage`
- Persistent login on app restart
- Role-based navigation

### State Management
- Riverpod for state management
- Controllers for each feature module
- AsyncValue for loading/error states

### Real-time Chat
- Socket.IO client integration
- Message history via REST API
- Real-time message updates

### Document Upload
- File picker integration
- Multipart upload with progress
- Document listing and management

## Dependencies

- `flutter_riverpod`: State management
- `dio`: HTTP client
- `socket_io_client`: WebSocket client
- `flutter_secure_storage`: Secure token storage
- `file_picker`: File selection
- `webview_flutter`: WebView for displaying web content
- `google_fonts`: Custom typography
- `intl`: Date/time formatting

## Building for Production

1. Update API URLs for production
2. Generate release build:
```bash
flutter build apk --release
```

## Notes

- The app is Android-only as specified
- Dark mode is the default theme
- All screens follow the design system specified in UX_DESIGN_SPEC.md
- Error handling and validation are implemented throughout

