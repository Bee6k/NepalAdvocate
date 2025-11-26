# Quick Fix Guide - Connection Issues

## Immediate Steps to Fix Connection

### Step 1: Verify Render Backend is Running

1. Open browser: `https://backend-vts8.onrender.com/health`
2. If you see `{"status":"OK","message":"NepalAdvocate API is running"}`, backend is OK ✅
3. If you see error or timeout:
   - Wait 30-60 seconds (Render free tier spins down)
   - Check Render Dashboard → Logs for errors
   - Verify service is not suspended

### Step 2: Check Render Environment Variables

Go to Render Dashboard → Your Service → Environment tab:

**Required Variables:**
```
NODE_ENV=production
MONGODB_URI=mongodb+srv://sujalkunwar_db_user:SyGo6Czt6he5Ib1n@cluster0.gsilwxh.mongodb.net/nepaladvocate?retryWrites=true&w=majority
JWT_SECRET=<your-secret-key>
JWT_EXPIRES_IN=7d
CORS_ORIGIN=*
```

**If MONGODB_URI is missing or wrong:**
1. Copy the connection string above
2. Paste it in Render Environment variables
3. Click "Save Changes"
4. Wait for redeploy (2-5 minutes)

### Step 3: Check MongoDB Atlas Network Access

1. Go to [MongoDB Atlas](https://cloud.mongodb.com)
2. Click "Network Access" in left menu
3. Click "Add IP Address"
4. Add `0.0.0.0/0` (allows all IPs - for testing)
5. Click "Confirm"

**Important:** This allows connections from anywhere. For production, restrict to Render IPs.

### Step 4: Verify Frontend Configuration

Check `lib/core/constants/api_constants.dart`:

```dart
static const String baseUrl = 'https://backend-vts8.onrender.com/api';
static const String wsUrl = 'https://backend-vts8.onrender.com';
```

If different, update and rebuild app.

### Step 5: Test Connection Locally

```bash
cd backend
npm run test-connection
```

This will test:
- Environment variables are set
- MongoDB connection works
- Database is accessible

### Step 6: Check Render Logs

1. Go to Render Dashboard
2. Open your backend service
3. Click "Logs" tab
4. Look for:
   - ✅ "Server running on port..."
   - ✅ "MongoDB Connected:..."
   - ❌ Any red error messages

## Common Fixes

### Fix 1: Backend Spinning Up Slowly

**Problem:** First request takes 30-60 seconds

**Solution:**
- This is normal for Render free tier
- Wait and try again
- Consider upgrading to Starter plan for always-on service

### Fix 2: MongoDB Connection Failed

**Problem:** Backend logs show "MongoDB Connection Failed"

**Solutions:**
1. **Check MONGODB_URI in Render:**
   - Go to Environment tab
   - Verify MONGODB_URI is set correctly
   - Should include: `/nepaladvocate?retryWrites=true&w=majority`

2. **Check MongoDB Atlas Network Access:**
   - Add `0.0.0.0/0` to allowed IPs
   - Wait 2-3 minutes for changes to propagate

3. **Verify MongoDB User:**
   - Username: `sujalkunwar_db_user`
   - Password: `SyGo6Czt6he5Ib1n`
   - User has read/write permissions

### Fix 3: Frontend Can't Connect

**Problem:** App shows "Network error" or "Connection failed"

**Solutions:**
1. **Verify API URL:**
   - Check `lib/core/constants/api_constants.dart`
   - Ensure using `https://backend-vts8.onrender.com/api`

2. **Check CORS:**
   - In Render, set `CORS_ORIGIN=*`
   - Redeploy backend

3. **Check Backend Health:**
   - Open: `https://backend-vts8.onrender.com/health`
   - Should return JSON response

### Fix 4: Socket.IO Not Working

**Problem:** Chat/real-time features not working

**Solutions:**
1. **Check WebSocket URL:**
   - Should be `https://backend-vts8.onrender.com` (not `http://`)

2. **Verify User is Logged In:**
   - Socket.IO requires authentication token
   - Login first, then try chat

3. **Check Backend Logs:**
   - Look for Socket.IO connection errors
   - Verify Socket.IO is configured in backend

## Verification Checklist

Run through this checklist:

- [ ] Backend health check works: `https://backend-vts8.onrender.com/health`
- [ ] Render logs show "MongoDB Connected"
- [ ] Render Environment variables are all set
- [ ] MongoDB Atlas Network Access allows `0.0.0.0/0`
- [ ] Frontend `api_constants.dart` has correct URLs
- [ ] Flutter app rebuilt after URL changes
- [ ] No errors in Render logs
- [ ] No errors in Flutter console

## Still Not Working?

1. **Check Render Logs** - Most detailed error info
2. **Test MongoDB Locally** - Run `npm run test-connection` in backend folder
3. **Verify Environment Variables** - All required vars set in Render
4. **Check Network** - Device/emulator has internet connection
5. **Wait for Backend** - Free tier may take 30-60s to wake up

## Need More Help?

See `TROUBLESHOOTING.md` for detailed troubleshooting steps.

