# Troubleshooting Guide - Frontend-Backend Connection

## Quick Diagnostic Steps

### 1. Test Backend Health

**Option A: Browser**
Open: `https://backend-vts8.onrender.com/health`

Expected response:
```json
{
  "status": "OK",
  "message": "NepalAdvocate API is running"
}
```

**Option B: Command Line**
```bash
# Windows PowerShell
Invoke-WebRequest -Uri "https://backend-vts8.onrender.com/health"

# Or use curl if available
curl https://backend-vts8.onrender.com/health
```

**Option C: Test Script**
```bash
cd backend
npm run test-connection
```

### 2. Check Render Dashboard

1. Go to [Render Dashboard](https://dashboard.render.com)
2. Open your backend service
3. Check **Logs** tab for errors
4. Check **Environment** tab for environment variables

### 3. Test MongoDB Connection

Run the test script locally:
```bash
cd backend
# Make sure .env file exists with MONGODB_URI
npm run test-connection
```

## Common Issues & Solutions

### Issue 1: Backend Not Responding / Connection Timeout

**Symptoms:**
- "Connection timeout" error
- "Connection closed unexpectedly"
- Backend health check fails

**Possible Causes:**
1. **Render Free Tier Spinning Down**
   - Free tier services spin down after 15 minutes of inactivity
   - First request after spin-down takes 30-60 seconds

**Solutions:**
- Wait 30-60 seconds and try again
- Consider upgrading to Starter plan ($7/month) for always-on service
- Use a service like [UptimeRobot](https://uptimerobot.com) to ping your backend every 5 minutes

2. **Backend Deployment Failed**
   - Check Render logs for build/deployment errors
   - Verify environment variables are set correctly

**Solutions:**
- Check Render dashboard → Logs
- Verify all required environment variables are set
- Check build logs for npm install errors

### Issue 2: MongoDB Connection Failed

**Symptoms:**
- Backend starts but shows "MongoDB Connection Failed"
- Error in Render logs about MongoDB

**Possible Causes:**
1. **MONGODB_URI Not Set**
   - Environment variable missing in Render

**Solution:**
- Go to Render Dashboard → Environment tab
- Add `MONGODB_URI` with value:
  ```
  mongodb+srv://sujalkunwar_db_user:SyGo6Czt6he5Ib1n@cluster0.gsilwxh.mongodb.net/nepaladvocate?retryWrites=true&w=majority
  ```

2. **MongoDB Atlas IP Whitelist**
   - Render IPs not allowed

**Solution:**
- Go to MongoDB Atlas → Network Access
- Add IP: `0.0.0.0/0` (allows all IPs - for testing)
- Or add specific Render IP ranges

3. **Wrong Connection String Format**
   - Missing database name or query parameters

**Solution:**
- Verify connection string includes database name: `/nepaladvocate`
- Include query parameters: `?retryWrites=true&w=majority`

4. **Authentication Failed**
   - Wrong username/password

**Solution:**
- Verify MongoDB Atlas user credentials
- Check username: `sujalkunwar_db_user`
- Reset password if needed

### Issue 3: Frontend Can't Connect to Backend

**Symptoms:**
- App shows "Network error" or "Connection failed"
- Login/registration fails
- API requests timeout

**Possible Causes:**
1. **Wrong API URL**
   - Frontend still pointing to localhost

**Solution:**
- Check `lib/core/constants/api_constants.dart`
- Verify `baseUrl` is: `https://backend-vts8.onrender.com/api`
- Verify `wsUrl` is: `https://backend-vts8.onrender.com`

2. **CORS Error**
   - Backend rejecting frontend requests

**Solution:**
- Check Render Environment variables
- Set `CORS_ORIGIN` to `*` (for testing) or your app domain
- Redeploy backend after changing CORS_ORIGIN

3. **Backend Spinning Up**
   - First request after inactivity takes time

**Solution:**
- Wait 30-60 seconds
- Try again
- Check backend logs in Render dashboard

### Issue 4: Socket.IO Connection Fails

**Symptoms:**
- Chat not working
- Real-time features not working
- Socket connection errors in console

**Possible Causes:**
1. **Wrong WebSocket URL**
   - Using `http://` instead of `https://`

**Solution:**
- Check `lib/core/constants/api_constants.dart`
- Ensure `wsUrl` uses `https://backend-vts8.onrender.com`

2. **No Authentication Token**
   - Socket.IO requires JWT token

**Solution:**
- Ensure user is logged in before connecting socket
- Check that token is being sent in auth handshake

3. **Backend Socket.IO Not Configured**
   - Backend not handling WebSocket connections

**Solution:**
- Check backend logs for Socket.IO errors
- Verify backend `server.js` has Socket.IO setup

## Step-by-Step Diagnostic

### Step 1: Verify Backend is Running
```bash
# Test health endpoint
curl https://backend-vts8.onrender.com/health
# Should return: {"status":"OK","message":"NepalAdvocate API is running"}
```

### Step 2: Check Backend Logs
1. Go to Render Dashboard
2. Open your backend service
3. Click "Logs" tab
4. Look for:
   - ✅ "Server running on port..."
   - ✅ "MongoDB Connected:..."
   - ❌ Any error messages

### Step 3: Verify Environment Variables
In Render Dashboard → Environment tab, verify:
- ✅ `NODE_ENV` = `production`
- ✅ `MONGODB_URI` = (your connection string)
- ✅ `JWT_SECRET` = (set)
- ✅ `CORS_ORIGIN` = `*` or your domain
- ✅ `JWT_EXPIRES_IN` = `7d`

### Step 4: Test MongoDB Connection Locally
```bash
cd backend
# Create .env file if not exists
npm run test-connection
```

### Step 5: Test Frontend Connection
1. Run Flutter app: `flutter run`
2. Check console logs for:
   - "🔧 Initializing API Client..."
   - "📍 Base URL: https://backend-vts8.onrender.com/api"
   - Any error messages

### Step 6: Test API Endpoint
Try registering a new user or logging in. Check:
- Flutter console logs
- Render backend logs
- Network tab (if using browser dev tools)

## Environment Variables Checklist

### Required in Render:
- [ ] `NODE_ENV` = `production`
- [ ] `MONGODB_URI` = `mongodb+srv://...`
- [ ] `JWT_SECRET` = (strong random string)
- [ ] `JWT_EXPIRES_IN` = `7d`
- [ ] `CORS_ORIGIN` = `*` (or your domain)

### Optional:
- [ ] `UPLOAD_DIR` = `./uploads`
- [ ] `PORT` = (Render sets automatically)

## MongoDB Atlas Checklist

- [ ] Database user created: `sujalkunwar_db_user`
- [ ] User has read/write permissions
- [ ] Network Access allows Render IPs (`0.0.0.0/0` for testing)
- [ ] Connection string includes database name: `/nepaladvocate`
- [ ] Connection string includes query params: `?retryWrites=true&w=majority`

## Frontend Configuration Checklist

- [ ] `lib/core/constants/api_constants.dart`:
  - [ ] `baseUrl` = `https://backend-vts8.onrender.com/api`
  - [ ] `wsUrl` = `https://backend-vts8.onrender.com`
- [ ] API client initialized in `main.dart`
- [ ] No hardcoded localhost URLs

## Still Having Issues?

1. **Check Render Logs**: Most detailed error information
2. **Check Flutter Console**: Look for API errors
3. **Test Backend Health**: Verify backend is reachable
4. **Test MongoDB**: Use `npm run test-connection`
5. **Check Network**: Ensure device/emulator has internet

## Getting Help

If issues persist:
1. Check Render service logs
2. Check MongoDB Atlas logs
3. Check Flutter console output
4. Verify all environment variables
5. Test backend health endpoint manually

