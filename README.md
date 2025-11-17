# NepalAdvocate - Lawyer Booking & Counseling App

A complete mobile application for connecting clients with lawyers, featuring appointment scheduling, real-time chat, document management, and more.

## Project Structure

```
NepalAdvocate/
├── backend/              # Node.js + Express + MongoDB backend
│   ├── config/           # Database, JWT configuration
│   ├── controllers/     # Route controllers
│   ├── middlewares/     # Auth, upload middlewares
│   ├── models/          # Mongoose schemas
│   ├── routes/          # API routes
│   ├── utils/           # Utility functions
│   └── server.js        # Express server entry point
├── flutter_app/          # Flutter mobile application
│   ├── lib/
│   │   ├── core/        # Theme, constants, utilities
│   │   ├── models/      # Data models
│   │   ├── services/    # API services
│   │   ├── controllers/ # Riverpod state management
│   │   ├── views/       # Screen widgets
│   │   └── widgets/     # Reusable components
│   └── android/         # Android configuration
└── UX_DESIGN_SPEC.md    # Complete UX design specification

```

## Tech Stack

### Backend
- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose
- **Authentication**: JWT (JSON Web Tokens)
- **Real-time**: Socket.IO
- **File Upload**: Multer
- **Security**: Helmet, CORS, Rate Limiting

### Frontend
- **Framework**: Flutter (Android-only)
- **State Management**: Riverpod
- **HTTP Client**: Dio
- **WebSocket**: Socket.IO Client
- **Storage**: Flutter Secure Storage
- **UI**: Material Design 3, Custom Dark Theme

## Features

### Authentication & Authorization
- ✅ User registration (Client/Lawyer)
- ✅ JWT-based authentication
- ✅ Role-based access control (Client, Lawyer, Admin)
- ✅ Persistent login
- ✅ Secure password hashing (bcrypt)

### Appointment Management
- ✅ Create appointment requests
- ✅ Propose alternative times
- ✅ Mutual confirmation system
- ✅ Appointment status tracking
- ✅ Appointment history

### Real-time Communication
- ✅ Socket.IO-based chat
- ✅ Message history
- ✅ Typing indicators
- ✅ Real-time notifications

### Document Management
- ✅ File upload (images, PDFs, documents)
- ✅ Document categorization
- ✅ Document sharing
- ✅ Download functionality

### Lawyer Features
- ✅ Lawyer profiles with specialization
- ✅ Search and filter lawyers
- ✅ Lawyer verification (Admin)
- ✅ Rating and reviews system

### Admin Features
- ✅ User management
- ✅ Lawyer verification
- ✅ Legal template management
- ✅ Platform statistics
- ✅ System administration

## Getting Started

### Prerequisites
- Node.js (v16+)
- MongoDB (local or cloud instance)
- Flutter SDK (3.0+)
- Android Studio / Android SDK

### Backend Setup

1. Navigate to backend directory:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Create `.env` file:
```env
PORT=3000
MONGODB_URI=mongodb://localhost:27017/nepaladvocate
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_EXPIRES_IN=7d
NODE_ENV=development
UPLOAD_DIR=./uploads
CORS_ORIGIN=*
```

4. Start MongoDB (if running locally)

5. Run the server:
```bash
npm run dev
```

The API will be available at `http://localhost:3000`

### Flutter App Setup

1. Navigate to Flutter app directory:
```bash
cd flutter_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Update API configuration in `lib/core/constants/api_constants.dart`:
```dart
static const String baseUrl = 'http://10.0.2.2:3000/api'; // Emulator
// or 'http://YOUR_IP:3000/api' for physical device
```

4. Run the app:
```bash
flutter run
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user

### Appointments
- `POST /api/appointments` - Create appointment
- `PATCH /api/appointments/:id/propose` - Propose time
- `PATCH /api/appointments/:id/confirm` - Confirm appointment
- `GET /api/appointments/mine` - Get user's appointments
- `GET /api/appointments/:id` - Get appointment details

### Chat
- `GET /api/chat/conversations` - Get conversations
- `GET /api/chat/conversations/:id/messages` - Get messages

### Documents
- `POST /api/documents/upload` - Upload document
- `GET /api/documents/mine` - Get user's documents
- `GET /api/documents/:id` - Get document details
- `GET /api/documents/:id/download` - Download document
- `DELETE /api/documents/:id` - Delete document

### Lawyers
- `GET /api/lawyers` - Get all lawyers
- `GET /api/lawyers/:id` - Get lawyer by ID
- `PATCH /api/lawyers/profile` - Update lawyer profile

### Templates
- `GET /api/templates` - Get all templates
- `GET /api/templates/:id` - Get template by ID
- `POST /api/templates` - Create template (Admin)
- `PATCH /api/templates/:id` - Update template (Admin)
- `DELETE /api/templates/:id` - Delete template (Admin)

### Notifications
- `GET /api/notifications` - Get notifications
- `PATCH /api/notifications/:id/read` - Mark as read
- `PATCH /api/notifications/read-all` - Mark all as read

### Admin
- `GET /api/admin/stats` - Get statistics
- `GET /api/admin/users` - Get all users
- `PATCH /api/admin/users/:id/status` - Update user status
- `PATCH /api/admin/lawyers/:id/verify` - Verify lawyer

## Socket.IO Events

### Client → Server
- `joinConversation` - Join conversation room
- `leaveConversation` - Leave conversation room
- `sendMessage` - Send message
- `typing` - Typing indicator

### Server → Client
- `newMessage` - New message received
- `notification` - New notification
- `appointment:{userId}` - Appointment update
- `document:{userId}` - Document update
- `userTyping` - User typing indicator

## Database Schema

### Collections
- **Users**: User accounts with roles
- **LawyerProfiles**: Extended lawyer information
- **Appointments**: Appointment records
- **Conversations**: Chat conversations
- **Messages**: Chat messages
- **Documents**: Document metadata
- **LegalTemplates**: Legal document templates
- **Notifications**: User notifications

See individual model files in `backend/models/` for detailed schemas.

## Design System

The app follows a comprehensive design system documented in `UX_DESIGN_SPEC.md`:

- **Color Palette**: Electric Cyan, Royal Purple, Neon Blue on dark backgrounds
- **Typography**: Poppins for headings, Inter for body
- **Components**: Buttons, inputs, cards, navigation
- **Accessibility**: WCAG AA/AAA compliant, color-blind friendly
- **Spacing**: 4px grid system

## Security Features

- JWT token authentication
- Password hashing with bcrypt
- Rate limiting on API endpoints
- Helmet.js security headers
- Input validation and sanitization
- Role-based access control
- Secure file upload validation

## Development Notes

### Backend
- Uses Express.js with modular route structure
- Mongoose for MongoDB ODM
- Socket.IO for real-time features
- Multer for file uploads
- Environment-based configuration

### Flutter
- Riverpod for state management
- Clean architecture with separation of concerns
- Reusable widget components
- Error handling and validation
- Persistent storage for auth tokens

## Testing

### Backend Testing
Use Postman collection (see `postman_collection.json`) or test endpoints manually.

### Flutter Testing
```bash
cd flutter_app
flutter test
```

## Deployment Considerations

### Backend
- Use environment variables for production
- Set secure JWT secret
- Configure CORS for production domain
- Use HTTPS for WebSocket connections
- Set up MongoDB Atlas or production MongoDB
- Configure file storage (consider cloud storage)

### Flutter
- Update API URLs for production
- Generate release build:
```bash
flutter build apk --release
```

## Contributing

1. Follow the existing code structure
2. Maintain code style consistency
3. Add appropriate error handling
4. Update documentation as needed
5. Test thoroughly before submitting

## License

This project is for educational/academic purposes.

## Support

For issues or questions, please refer to the documentation or create an issue in the repository.

## Acknowledgments

- Design system inspired by modern legal-tech applications
- Built with accessibility and user experience in mind
- Follows Flutter and Node.js best practices

