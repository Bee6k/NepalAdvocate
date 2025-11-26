# NepalAdvocate - Backend & Frontend Connection Guide

This guide will help you connect the Flutter frontend with the Node.js backend.

## Prerequisites

1. **Node.js** (v14 or higher) - [Download](https://nodejs.org/)
2. **MongoDB** - [Download](https://www.mongodb.com/try/download/community) or use MongoDB Atlas
3. **Flutter SDK** - Already installed ✓
4. **Android Studio** or **VS Code** - For development

## Backend Setup

### Step 1: Install Backend Dependencies

```bash
cd backend
npm install
```

### Step 2: Configure Environment Variables

Create a `.env` file in the `backend` folder:

```env
# Server Configuration
PORT=3000
NODE_ENV=development

# Database Configuration
# For local MongoDB:
MONGODB_URI=mongodb://localhost:27017/nepaladvocate
# OR for MongoDB Atlas:
# MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/nepaladvocate

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-in-production-please-use-a-strong-random-string
JWT_EXPIRES_IN=7d

# File Upload Configuration
UPLOAD_DIR=./uploads

# CORS Configuration
# Use * for development (allows all origins)
# For production, specify your app's domain
CORS_ORIGIN=*
```

### Step 3: Start MongoDB

**Option A: Local MongoDB**
- Start MongoDB service on your system
- On Windows: MongoDB should start automatically if installed as a service
- On Mac/Linux: `sudo systemctl start mongod` or `brew services start mongodb-community`

**Option B: MongoDB Atlas (Cloud)**
- Create a free account at [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
- Create a cluster and get your connection string
- Update `MONGODB_URI` in `.env` file

### Step 4: Start the Backend Server

```bash
# Development mode (with auto-reload)
npm run dev

# OR Production mode
npm start
```

The server should start on `http://localhost:3000`

You should see:
```
Server running on port 3000
Environment: development
MongoDB Connected: ...
```

## Frontend Setup

### Step 1: Verify API Configuration

The Flutter app is already configured to connect to:
- **Android Emulator**: `http://10.0.2.2:3000/api`
- **iOS Simulator**: `http://localhost:3000/api`
- **Physical Device**: You need to update the IP address

### Step 2: Update API URL for Physical Device

If testing on a physical device, update `lib/core/constants/api_constants.dart`:

```dart
// Find your computer's IP address:
// Windows: ipconfig
// Mac/Linux: ifconfig

static const String baseUrl = 'http://YOUR_COMPUTER_IP:3000/api';
static const String wsUrl = 'http://YOUR_COMPUTER_IP:3000';
```

**Example:**
```dart
static const String baseUrl = 'http://192.168.1.100:3000/api';
static const String wsUrl = 'http://192.168.1.100:3000';
```

### Step 3: Run the Flutter App

```bash
# Make sure you're in the project root (not backend folder)
flutter run
```

## Testing the Connection

### 1. Test Backend Health

Open your browser and visit:
```
http://localhost:3000/health
```

You should see:
```json
{
  "status": "OK",
  "message": "NepalAdvocate API is running"
}
```

### 2. Test from Flutter App

1. Start the backend server
2. Start the Flutter app
3. Try to register a new user or login
4. Check the backend console for API requests

## Troubleshooting

### Backend Issues

**Problem: MongoDB connection error**
- Solution: Make sure MongoDB is running
- Check `MONGODB_URI` in `.env` file
- For MongoDB Atlas, ensure your IP is whitelisted

**Problem: Port 3000 already in use**
- Solution: Change `PORT` in `.env` file or stop the process using port 3000
- Update Flutter `api_constants.dart` accordingly

**Problem: CORS errors**
- Solution: Ensure `CORS_ORIGIN=*` in `.env` for development
- Check that the backend server is running

### Frontend Issues

**Problem: Connection refused / Network error**
- **Android Emulator**: Use `10.0.2.2` (already configured)
- **iOS Simulator**: Use `localhost` (already configured)
- **Physical Device**: 
  1. Find your computer's IP: `ipconfig` (Windows) or `ifconfig` (Mac/Linux)
  2. Update `api_constants.dart` with your IP
  3. Ensure phone and computer are on the same WiFi network
  4. Disable firewall temporarily or allow port 3000

**Problem: Socket.IO connection fails**
- Ensure backend is running
- Check WebSocket URL matches HTTP URL (same IP/port)
- Verify JWT token is being sent correctly

### Common Fixes

1. **Clear Flutter build cache:**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Restart backend server** after changing `.env`

3. **Check backend logs** for detailed error messages

4. **Verify all dependencies installed:**
   ```bash
   # Backend
   cd backend
   npm install
   
   # Frontend
   flutter pub get
   ```

## API Endpoints Reference

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user (requires auth)

### Appointments
- `POST /api/appointments` - Create appointment
- `GET /api/appointments/mine` - Get user's appointments
- `GET /api/appointments/:id` - Get single appointment
- `PATCH /api/appointments/:id/confirm` - Confirm appointment
- `PATCH /api/appointments/:id/propose` - Propose new time

### Chat
- `GET /api/chat/conversations` - Get conversations
- `GET /api/chat/conversations/:id/messages` - Get messages

### Documents
- `POST /api/documents/upload` - Upload document
- `GET /api/documents/mine` - Get user's documents

### Lawyers
- `GET /api/lawyers` - Get all lawyers
- `GET /api/lawyers/:id` - Get lawyer details

### Templates
- `GET /api/templates` - Get all templates
- `GET /api/templates/:id` - Get template details

## Next Steps

1. ✅ Backend server running on port 3000
2. ✅ MongoDB connected
3. ✅ Flutter app configured
4. 🚀 Start developing!

## Development Tips

- Use `npm run dev` for backend (auto-reload on changes)
- Use Flutter hot reload for frontend
- Check browser console and Flutter debug console for errors
- Use Postman or similar tool to test API endpoints directly

