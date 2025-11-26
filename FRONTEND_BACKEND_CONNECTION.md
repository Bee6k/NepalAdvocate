# Frontend-Backend Connection Guide

## ✅ Connection Status

Your Flutter frontend is now connected to the Render backend!

**Backend URL:** `https://backend-vts8.onrender.com`

## Changes Made

### 1. API Configuration (`lib/core/constants/api_constants.dart`)
- ✅ Updated `baseUrl` to: `https://backend-vts8.onrender.com/api`
- ✅ Updated `wsUrl` to: `https://backend-vts8.onrender.com` (for Socket.IO)

### 2. API Client Timeouts (`lib/core/utils/api_client.dart`)
- ✅ Increased `connectTimeout` to 30 seconds (for production)
- ✅ Increased `receiveTimeout` to 30 seconds (for production)
- ✅ Added `sendTimeout` of 30 seconds

## Backend Configuration Required

Make sure your Render backend has these environment variables set:

1. **CORS_ORIGIN** - Set to allow your Flutter app
   - For testing: `*` (allows all origins)
   - For production: Set to your app's domain(s)

2. **MONGODB_URI** - Your MongoDB connection string
   - Already configured: `mongodb+srv://sujalkunwar_db_user:SyGo6Czt6he5Ib1n@cluster0.gsilwxh.mongodb.net/nepaladvocate?retryWrites=true&w=majority`

3. **JWT_SECRET** - Strong random string for JWT signing

4. **JWT_EXPIRES_IN** - Token expiration (e.g., `7d`)

5. **NODE_ENV** - Set to `production`

## Testing the Connection

### 1. Test Backend Health
Open in browser: `https://backend-vts8.onrender.com/health`

Expected response:
```json
{
  "status": "OK",
  "message": "NepalAdvocate API is running"
}
```

### 2. Test from Flutter App
1. Run your Flutter app: `flutter run`
2. Try to register a new user or login
3. Check the app logs for any connection errors

### 3. Test Socket.IO Connection
1. Login to the app
2. Open a chat conversation
3. Check console logs for: `ChatService: Socket connected`

## Common Issues & Solutions

### Issue: "Connection timeout" or "Network error"
**Solution:**
- Check if backend is running: Visit `https://backend-vts8.onrender.com/health`
- Render free tier may spin down after inactivity - first request may take 30-60 seconds
- Wait for backend to wake up, then try again

### Issue: "CORS error"
**Solution:**
- In Render dashboard → Environment tab
- Set `CORS_ORIGIN` to `*` (for testing) or your app's domain
- Redeploy the backend

### Issue: "Socket.IO connection fails"
**Solution:**
- Ensure you're logged in (Socket.IO requires authentication token)
- Check that `wsUrl` uses `https://` (not `http://`)
- Verify backend Socket.IO is configured correctly

### Issue: "401 Unauthorized"
**Solution:**
- Token may have expired - try logging out and logging in again
- Check that JWT_SECRET is set correctly in Render
- Verify token is being sent in Authorization header

### Issue: "File upload fails"
**Solution:**
- Render uses ephemeral filesystem - files are lost on restart
- For production, consider using cloud storage (AWS S3, Cloudinary)
- Check file size limits (backend allows up to 10MB for documents)

## Switching Between Local and Production

### For Production (Current):
```dart
static const String baseUrl = 'https://backend-vts8.onrender.com/api';
static const String wsUrl = 'https://backend-vts8.onrender.com';
```

### For Local Development:
```dart
static const String baseUrl = 'http://10.0.2.2:3000/api'; // Android emulator
static const String wsUrl = 'http://10.0.2.2:3000';
// For physical device: 'http://192.168.x.x:3000/api'
```

## Next Steps

1. ✅ Test user registration and login
2. ✅ Test creating appointments
3. ✅ Test chat functionality
4. ✅ Test file uploads
5. ⚠️ Consider migrating file storage to cloud storage (AWS S3, Cloudinary) for production
6. ⚠️ Update CORS_ORIGIN in Render to your production domain (instead of `*`)

## Backend URLs Reference

- **API Base:** `https://backend-vts8.onrender.com/api`
- **Health Check:** `https://backend-vts8.onrender.com/health`
- **WebSocket:** `https://backend-vts8.onrender.com` (Socket.IO)
- **Admin Panel:** `https://backend-vts8.onrender.com/admin`

## Support

If you encounter issues:
1. Check Render logs: Render Dashboard → Your Service → Logs
2. Check Flutter console logs
3. Test backend health endpoint in browser
4. Verify environment variables in Render dashboard

