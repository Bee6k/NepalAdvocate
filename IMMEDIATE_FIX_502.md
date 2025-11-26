# 🚨 IMMEDIATE FIX for 502 Error

## The Problem

You're getting a **502 Bad Gateway** error, which means Render's load balancer can't reach your backend. The backend is likely **crashing during startup**.

## Most Likely Cause: MongoDB Connection Failed

Based on the error, your backend is probably failing to connect to MongoDB and crashing.

## ⚡ Quick Fix (Do This Now)

### Step 1: Check Render Logs (CRITICAL)

1. Go to: https://dashboard.render.com
2. Click on your backend service (`backend-vts8`)
3. Click **"Logs"** tab
4. **Look for these errors:**
   - ❌ "MongoDB Connection Failed"
   - ❌ "Error: ..."
   - ❌ "MONGODB_URI is not set"

### Step 2: Fix MongoDB Connection

**If you see "MongoDB Connection Failed" or "MONGODB_URI is not set":**

1. **Go to Render Dashboard → Environment tab**
2. **Add/Update MONGODB_URI:**
   ```
   Key: MONGODB_URI
   Value: mongodb+srv://sujalkunwar_db_user:SyGo6Czt6he5Ib1n@cluster0.gsilwxh.mongodb.net/nepaladvocate?retryWrites=true&w=majority
   ```
3. **Click "Save Changes"**
4. **Wait 2-5 minutes for redeploy**

### Step 3: Fix MongoDB Atlas Network Access

1. Go to: https://cloud.mongodb.com
2. Click **"Network Access"** (left menu)
3. Click **"Add IP Address"**
4. Enter: `0.0.0.0/0` (allows all IPs)
5. Click **"Confirm"**
6. **Wait 2-3 minutes** for changes to propagate

### Step 4: Verify All Environment Variables

In Render Dashboard → Environment tab, make sure you have:

```
NODE_ENV=production
MONGODB_URI=mongodb+srv://sujalkunwar_db_user:SyGo6Czt6he5Ib1n@cluster0.gsilwxh.mongodb.net/nepaladvocate?retryWrites=true&w=majority
JWT_SECRET=<your-secret-key>
JWT_EXPIRES_IN=7d
CORS_ORIGIN=*
```

### Step 5: Test Backend

After waiting 2-5 minutes:

1. Open: `https://backend-vts8.onrender.com/health`
2. Should see: `{"status":"OK","message":"NepalAdvocate API is running"}`
3. If still 502, check Render logs again

## What to Look For in Logs

### ✅ Good Logs (Backend Working):
```
Server running on port 10000
Environment: production
MongoDB Connected: cluster0-shard-00-XX.gsilwxh.mongodb.net
```

### ❌ Bad Logs (Backend Crashing):
```
❌ MongoDB Connection Failed:
   Error: ...
```
**Fix:** Check MONGODB_URI and MongoDB Atlas Network Access

```
❌ MONGODB_URI is not set in environment variables
```
**Fix:** Add MONGODB_URI in Render Environment tab

```
Process exited with code 1
```
**Fix:** Check the error message above this line

## If Backend Keeps Crashing

1. **Check Render Logs** for the exact error
2. **Verify MONGODB_URI** is correct (includes `/nepaladvocate`)
3. **Check MongoDB Atlas** Network Access allows `0.0.0.0/0`
4. **Try Manual Deploy:**
   - Render Dashboard → Manual Deploy → Clear build cache & deploy

## Test Locally First

Before deploying, test locally:

```bash
cd backend
# Make sure .env file exists with MONGODB_URI
npm run test-connection
```

If this works locally but fails on Render, it's an environment variable issue.

## Still Not Working?

1. **Share Render Logs** - Copy the error messages
2. **Check Service Status** - Is it suspended?
3. **Verify Billing** - Is there a payment issue?

## Summary

**Most likely fix:**
1. Add `MONGODB_URI` to Render Environment variables
2. Add `0.0.0.0/0` to MongoDB Atlas Network Access
3. Wait 2-5 minutes for redeploy
4. Test: `https://backend-vts8.onrender.com/health`

The improved error handling will now show better messages in the app, but you need to fix the backend first!

