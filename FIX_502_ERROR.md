# Fixing 502 Bad Gateway Error

## What is a 502 Error?

A **502 Bad Gateway** error means Render's load balancer received a request but couldn't get a valid response from your backend service. This usually happens when:

1. **Backend crashed during startup** (most common)
2. **Backend failed to connect to MongoDB**
3. **Backend is still spinning up** (Render free tier)
4. **Backend has a configuration error**

## Immediate Steps to Fix

### Step 1: Check Render Logs

1. Go to [Render Dashboard](https://dashboard.render.com)
2. Open your backend service: `backend-vts8`
3. Click **"Logs"** tab
4. Look for error messages, especially:
   - ❌ "MongoDB Connection Failed"
   - ❌ "Error: ..."
   - ❌ "Process exited with code 1"
   - ✅ "Server running on port..."
   - ✅ "MongoDB Connected:..."

### Step 2: Common Issues & Fixes

#### Issue 1: MongoDB Connection Failed

**Symptoms in logs:**
```
❌ MongoDB Connection Failed:
   Error: ...
```

**Fix:**
1. **Check MONGODB_URI in Render:**
   - Go to Environment tab
   - Verify `MONGODB_URI` is set to:
     ```
     mongodb+srv://sujalkunwar_db_user:SyGo6Czt6he5Ib1n@cluster0.gsilwxh.mongodb.net/nepaladvocate?retryWrites=true&w=majority
     ```
   - Make sure it includes `/nepaladvocate` and query parameters

2. **Check MongoDB Atlas Network Access:**
   - Go to [MongoDB Atlas](https://cloud.mongodb.com)
   - Click "Network Access"
   - Add IP: `0.0.0.0/0` (allows all IPs)
   - Wait 2-3 minutes for changes to propagate

3. **Verify MongoDB User:**
   - Username: `sujalkunwar_db_user`
   - Password: `SyGo6Czt6he5Ib1n`
   - User has read/write permissions

#### Issue 2: Missing Environment Variables

**Symptoms in logs:**
```
❌ MONGODB_URI is not set in environment variables
```

**Fix:**
1. Go to Render Dashboard → Environment tab
2. Add missing variables:
   - `MONGODB_URI` = (your connection string)
   - `JWT_SECRET` = (strong random string)
   - `NODE_ENV` = `production`
   - `CORS_ORIGIN` = `*`
   - `JWT_EXPIRES_IN` = `7d`
3. Click "Save Changes"
4. Wait for redeploy (2-5 minutes)

#### Issue 3: Backend Still Spinning Up

**Symptoms:**
- First request after inactivity
- Takes 30-60 seconds to respond

**Fix:**
- This is normal for Render free tier
- Wait 30-60 seconds and try again
- Consider upgrading to Starter plan ($7/month) for always-on service

#### Issue 4: Backend Crashed

**Symptoms in logs:**
```
Process exited with code 1
```

**Fix:**
1. Check logs for the specific error
2. Fix the error (usually MongoDB connection or missing env vars)
3. Render will automatically restart
4. If it keeps crashing, check the error message

### Step 3: Verify Backend is Running

**Test health endpoint:**
Open in browser: `https://backend-vts8.onrender.com/health`

**Expected response:**
```json
{
  "status": "OK",
  "message": "NepalAdvocate API is running"
}
```

**If you get 502:**
- Backend is not running
- Check Render logs for errors
- Verify environment variables

**If you get timeout:**
- Backend is spinning up
- Wait 30-60 seconds and try again

### Step 4: Manual Restart (if needed)

1. Go to Render Dashboard
2. Open your backend service
3. Click **"Manual Deploy"** → **"Clear build cache & deploy"**
4. Wait for deployment to complete (2-5 minutes)

## Diagnostic Checklist

Run through this checklist:

- [ ] **Render Logs Check:**
  - [ ] No "MongoDB Connection Failed" errors
  - [ ] See "Server running on port..." message
  - [ ] See "MongoDB Connected:..." message
  - [ ] No "Process exited" errors

- [ ] **Environment Variables:**
  - [ ] `MONGODB_URI` is set correctly
  - [ ] `JWT_SECRET` is set
  - [ ] `NODE_ENV` = `production`
  - [ ] `CORS_ORIGIN` = `*` (or your domain)

- [ ] **MongoDB Atlas:**
  - [ ] Network Access allows `0.0.0.0/0` or Render IPs
  - [ ] Database user exists and has permissions
  - [ ] Connection string includes database name

- [ ] **Backend Health:**
  - [ ] `https://backend-vts8.onrender.com/health` returns JSON
  - [ ] Not returning 502 error
  - [ ] Response time is reasonable

## Quick Test Script

Run this locally to test your configuration:

```bash
cd backend
npm run test-connection
```

This will verify:
- Environment variables are set
- MongoDB connection works
- Database is accessible

## Still Getting 502?

1. **Check Render Service Status:**
   - Is the service suspended?
   - Is there a billing issue?
   - Is the service still deploying?

2. **Check Render Logs:**
   - Look for the exact error message
   - Check if MongoDB connection is the issue
   - Verify all environment variables are set

3. **Test MongoDB Connection:**
   ```bash
   cd backend
   npm run test-connection
   ```

4. **Manual Deploy:**
   - Clear build cache
   - Redeploy from Render dashboard

## Prevention

To avoid 502 errors:

1. **Always set all required environment variables** before deploying
2. **Verify MongoDB Atlas Network Access** allows Render IPs
3. **Check Render logs** after deployment to ensure startup succeeded
4. **Consider upgrading** to Starter plan for always-on service (no spin-down)

## Need More Help?

- Check `TROUBLESHOOTING.md` for detailed troubleshooting
- Check `QUICK_FIX_GUIDE.md` for quick fixes
- Review Render logs for specific error messages

