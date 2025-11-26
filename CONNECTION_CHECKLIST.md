# Connection Checklist - Backend & Frontend

Use this checklist to ensure everything is properly connected.

## ✅ Backend Setup

- [ ] Node.js installed (check with `node --version`)
- [ ] MongoDB installed and running
- [ ] Backend dependencies installed (`cd backend && npm install`)
- [ ] `.env` file created in `backend/` folder
- [ ] MongoDB connection string configured in `.env`
- [ ] Backend server starts successfully (`npm run dev` in backend folder)
- [ ] Health check works: `http://localhost:3000/health`

## ✅ Frontend Setup

- [ ] Flutter dependencies installed (`flutter pub get`)
- [ ] API constants configured correctly (`lib/core/constants/api_constants.dart`)
- [ ] For Android Emulator: Using `10.0.2.2:3000` ✓ (already configured)
- [ ] For iOS Simulator: Using `localhost:3000` ✓ (already configured)
- [ ] For Physical Device: Updated with your computer's IP address

## ✅ API Endpoints Verification

All endpoints match between frontend and backend:

| Frontend Constant | Backend Route | Status |
|------------------|---------------|--------|
| `/auth/register` | `POST /api/auth/register` | ✅ |
| `/auth/login` | `POST /api/auth/login` | ✅ |
| `/auth/me` | `GET /api/auth/me` | ✅ |
| `/appointments` | `POST /api/appointments` | ✅ |
| `/appointments/mine` | `GET /api/appointments/mine` | ✅ |
| `/chat/conversations` | `GET /api/chat/conversations` | ✅ |
| `/chat/conversations/:id/messages` | `GET /api/chat/conversations/:id/messages` | ✅ |
| `/documents/upload` | `POST /api/documents/upload` | ✅ |
| `/documents/mine` | `GET /api/documents/mine` | ✅ |
| `/lawyers` | `GET /api/lawyers` | ✅ |
| `/templates` | `GET /api/templates` | ✅ |
| `/notifications` | `GET /api/notifications` | ✅ |
| `/admin/stats` | `GET /api/admin/stats` | ✅ |
| `/admin/users` | `GET /api/admin/users` | ✅ |

## 🔧 Quick Start Commands

### Start Backend:
```bash
cd backend
npm run dev
```

### Start Frontend:
```bash
flutter run
```

### Test Backend Health:
Open browser: `http://localhost:3000/health`

## 🐛 Common Issues & Solutions

### Issue: "Cannot connect to backend"
**Solution:**
1. Ensure backend is running (`npm run dev` in backend folder)
2. Check MongoDB is running
3. Verify `.env` file exists and has correct configuration
4. For physical device: Update IP address in `api_constants.dart`

### Issue: "MongoDB connection error"
**Solution:**
1. Start MongoDB service
2. Check `MONGODB_URI` in `.env` file
3. For MongoDB Atlas: Whitelist your IP address

### Issue: "CORS errors"
**Solution:**
1. Set `CORS_ORIGIN=*` in backend `.env` file
2. Restart backend server

### Issue: "Socket.IO connection fails"
**Solution:**
1. Ensure backend is running
2. Check `wsUrl` in `api_constants.dart` matches `baseUrl` (same IP/port)
3. Verify JWT token is being sent correctly

## 📝 Environment Configuration

### Backend `.env` file should contain:
```env
PORT=3000
MONGODB_URI=mongodb://localhost:27017/nepaladvocate
JWT_SECRET=your-secret-key-here
JWT_EXPIRES_IN=7d
CORS_ORIGIN=*
```

### Frontend `api_constants.dart`:
- Android Emulator: `http://10.0.2.2:3000/api` ✓
- iOS Simulator: `http://localhost:3000/api` (update if needed)
- Physical Device: `http://YOUR_IP:3000/api` (update required)

## 🚀 Testing Connection

1. **Start Backend:**
   ```bash
   cd backend
   npm run dev
   ```

2. **Test Health Endpoint:**
   - Open: `http://localhost:3000/health`
   - Should return: `{"status":"OK","message":"NepalAdvocate API is running"}`

3. **Start Flutter App:**
   ```bash
   flutter run
   ```

4. **Test Registration/Login:**
   - Try registering a new user
   - Check backend console for API logs
   - Check Flutter console for responses

## ✨ Success Indicators

- ✅ Backend server shows: "Server running on port 3000"
- ✅ Backend shows: "MongoDB Connected: ..."
- ✅ Health endpoint returns success
- ✅ Flutter app can register/login users
- ✅ Backend console shows API requests
- ✅ No CORS errors in browser/Flutter console

