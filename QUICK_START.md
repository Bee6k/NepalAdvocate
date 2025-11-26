# 🚀 Quick Start Guide - NepalAdvocate

Get your backend and frontend connected in 5 minutes!

## Step 1: Start MongoDB

**Windows:**
- MongoDB should start automatically if installed as a service
- Or start manually from Services

**Mac/Linux:**
```bash
sudo systemctl start mongod
# OR
brew services start mongodb-community
```

**Cloud (MongoDB Atlas):**
- Use your Atlas connection string in `.env` file

## Step 2: Start Backend

```bash
cd backend
npm run dev
```

You should see:
```
Server running on port 3000
MongoDB Connected: ...
```

## Step 3: Start Frontend

In a new terminal:
```bash
flutter run
```

## Step 4: Test Connection

1. Open browser: `http://localhost:3000/health`
2. Should see: `{"status":"OK","message":"NepalAdvocate API is running"}`
3. Try registering a user in the Flutter app
4. Check backend console for API logs

## ✅ That's it!

Your backend and frontend are now connected!

## 📱 Testing on Physical Device

If testing on a physical device:

1. Find your computer's IP address:
   - Windows: `ipconfig` → Look for IPv4 Address
   - Mac/Linux: `ifconfig` → Look for inet address

2. Update `lib/core/constants/api_constants.dart`:
   ```dart
   static const String baseUrl = 'http://YOUR_IP:3000/api';
   static const String wsUrl = 'http://YOUR_IP:3000';
   ```

3. Ensure phone and computer are on the same WiFi network

## 🐛 Troubleshooting

**Backend won't start:**
- Check MongoDB is running
- Check port 3000 is not in use
- Verify `.env` file exists in `backend/` folder

**Can't connect from Flutter:**
- Android Emulator: Already configured ✓
- iOS Simulator: Use `localhost` ✓
- Physical Device: Update IP address (see above)

**CORS errors:**
- Set `CORS_ORIGIN=*` in backend `.env` file
- Restart backend server

For more details, see `SETUP.md` and `CONNECTION_CHECKLIST.md`

