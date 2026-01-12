# Vercel Deployment Guide for SmartAjo

This guide provides step-by-step instructions for deploying SmartAjo to Vercel and configuring environment variables correctly.

## The Problem

When deploying to Vercel, you may encounter this error:

```
Payment error: Error: Paystack public key not configured. Please set VITE_PAYSTACK_PUBLIC_KEY in your .env file.
```

This occurs because Vite environment variables must be configured **at build time** on Vercel, not just in local `.env` files.

## Understanding Vite Environment Variables

Vite uses a special approach to environment variables:

1. **Build-time variables**: Variables prefixed with `VITE_` are embedded into the frontend code during the build process
2. **Not runtime**: Unlike server-side Node.js apps, frontend variables cannot be changed after the build
3. **Security**: Only `VITE_` prefixed variables are exposed to the browser (this is a security feature)

## Quick Fix for Vercel

### Step 1: Access Vercel Project Settings

1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Select your project (smart-ajo)
3. Click on **Settings** tab
4. Navigate to **Environment Variables** section

### Step 2: Add Required Environment Variables

Add the following environment variables in Vercel:

#### Required Variables

| Variable Name | Value | Environment |
|--------------|-------|-------------|
| `VITE_SUPABASE_URL` | `https://your-project.supabase.co` | Production, Preview, Development |
| `VITE_SUPABASE_ANON_KEY` | Your Supabase anon key | Production, Preview, Development |
| `VITE_PAYSTACK_PUBLIC_KEY` | `pk_test_...` or `pk_live_...` | Production, Preview, Development |
| `VITE_APP_NAME` | `Ajo Secure` | Production, Preview, Development |
| `VITE_APP_URL` | `https://your-app.vercel.app` | Production, Preview, Development |

#### Optional Feature Flags

| Variable Name | Value | Environment |
|--------------|-------|-------------|
| `VITE_ENABLE_KYC` | `true` | Production, Preview, Development |
| `VITE_ENABLE_BVN_VERIFICATION` | `true` | Production, Preview, Development |
| `VITE_ENABLE_EMAIL_VERIFICATION` | `true` | Production, Preview, Development |
| `VITE_ENABLE_PHONE_VERIFICATION` | `true` | Production, Preview, Development |

### Step 3: Get Your Paystack Public Key

1. Visit [Paystack Dashboard](https://dashboard.paystack.com/)
2. Navigate to **Settings** → **API Keys & Webhooks**
3. Copy your **Public Key**:
   - Test mode: starts with `pk_test_`
   - Live mode: starts with `pk_live_`

**Important**: 
- Use `pk_test_` keys for development/staging
- Use `pk_live_` keys ONLY for production
- Never use live keys in development

### Step 4: Configure in Vercel

For each environment variable:

1. Click **Add New** in the Environment Variables section
2. Enter the **Variable Name** (e.g., `VITE_PAYSTACK_PUBLIC_KEY`)
3. Enter the **Value** (e.g., `pk_test_your_actual_key_here`)
4. Select which environments to apply to:
   - ✅ **Production** - for your main domain
   - ✅ **Preview** - for pull request previews
   - ✅ **Development** - for local development (optional, since you have `.env.development`)
5. Click **Save**

### Step 5: Redeploy Your Application

After adding environment variables, you must redeploy:

#### Option A: Automatic Redeploy (Recommended)
1. Go to **Deployments** tab
2. Find the latest deployment
3. Click the **...** menu
4. Select **Redeploy**
5. Check **Use existing Build Cache** (optional, for faster builds)
6. Click **Redeploy**

#### Option B: Trigger via Git
```bash
git commit --allow-empty -m "Trigger Vercel rebuild with env vars"
git push
```

## Vercel-Specific Configuration

### vercel.json Configuration

The project includes a `vercel.json` file that handles:
- Single Page Application (SPA) routing
- Security headers
- Asset caching

**Do not modify** this file unless you understand the implications.

### Build Settings

If you need to customize build settings in Vercel:

1. Go to **Settings** → **General**
2. Verify build settings:
   - **Framework Preset**: Vite
   - **Build Command**: `npm run build`
   - **Output Directory**: `dist`
   - **Install Command**: `npm install`

These should be auto-detected, but verify if builds fail.

## Verification Steps

After deployment, verify everything works:

### 1. Check Build Logs

1. Go to **Deployments** tab
2. Click on the latest deployment
3. Check the build logs for:
   ```
   ✓ built in [time]
   ```
4. Ensure no environment variable warnings

### 2. Test Payment Initialization

1. Open your deployed application
2. Navigate to **Create Group** page
3. Fill in group details
4. Click the payment button
5. **Should see**: Paystack payment modal opens
6. **Should NOT see**: "Paystack public key not configured" error

### 3. Check Browser Console

Open browser developer tools (F12) and check console:
- No errors about missing environment variables
- No errors about Paystack configuration

### 4. Test Different Environments

Test in multiple environments:
- **Production**: Your main domain
- **Preview**: Any pull request preview
- **Local**: Your local development with `.env.development`

## Troubleshooting

### Issue 1: "Paystack public key not configured" Still Appears

**Cause**: Environment variable not set or build cache issue

**Solutions**:

1. **Verify the variable exists**:
   - Go to **Settings** → **Environment Variables**
   - Look for `VITE_PAYSTACK_PUBLIC_KEY`
   - Ensure it has a value (not empty)

2. **Check the variable name**:
   - Must be exactly: `VITE_PAYSTACK_PUBLIC_KEY`
   - Case-sensitive
   - Must start with `VITE_`

3. **Clear build cache and redeploy**:
   - Go to **Deployments**
   - Click latest deployment **...** menu
   - Select **Redeploy**
   - **Uncheck** "Use existing Build Cache"
   - Click **Redeploy**

4. **Check for typos**:
   ```
   ❌ PAYSTACK_PUBLIC_KEY          (missing VITE_ prefix)
   ❌ VITE_PAYSTACK_PUBLICKEY      (missing underscore)
   ❌ Vite_Paystack_Public_Key     (wrong case)
   ✅ VITE_PAYSTACK_PUBLIC_KEY     (correct)
   ```

### Issue 2: Different Environments Have Different Keys

**Cause**: Need different keys for production vs preview

**Solution**:

1. Set environment-specific variables:
   ```
   VITE_PAYSTACK_PUBLIC_KEY = pk_test_xxx  (Preview, Development)
   VITE_PAYSTACK_PUBLIC_KEY = pk_live_xxx  (Production only)
   ```

2. In Vercel, when adding the variable:
   - For test key: Check **Preview** and **Development**
   - For live key: Check **Production** only

### Issue 3: Variable Not Available in Browser

**Cause**: Variable doesn't have `VITE_` prefix

**Solution**: All frontend variables MUST start with `VITE_`:
```bash
# ❌ Won't work (no VITE_ prefix)
PAYSTACK_PUBLIC_KEY=pk_test_xxx

# ✅ Will work
VITE_PAYSTACK_PUBLIC_KEY=pk_test_xxx
```

### Issue 4: Build Succeeds but Runtime Error

**Cause**: Variable was added after the build

**Solution**: 
- Adding environment variables requires a rebuild
- Simply redeploying the same commit with new variables triggers a rebuild
- Follow Step 5 above to redeploy

### Issue 5: Works Locally but Not on Vercel

**Cause**: Local `.env.development` file not synced to Vercel

**Solution**:
- `.env.development` is **not** deployed to Vercel (it's gitignored)
- You MUST set variables in Vercel dashboard separately
- Local and Vercel environments are independent

## Security Best Practices

### ✅ DO:
- Use `pk_test_` keys for development and staging
- Use `pk_live_` keys only for production
- Keep test and live keys separate
- Set environment-specific keys in Vercel
- Use the `VITE_` prefix for all frontend variables

### ❌ DON'T:
- Never commit `.env.development` or `.env.production` to Git
- Never put secret keys (starting with `sk_`) in frontend variables
- Never use live keys in development
- Never share your secret keys publicly
- Don't forget to redeploy after adding variables

## Environment Variable Checklist

Use this checklist when deploying to Vercel:

- [ ] Obtained Paystack public key from dashboard
- [ ] Added `VITE_PAYSTACK_PUBLIC_KEY` to Vercel environment variables
- [ ] Added `VITE_SUPABASE_URL` to Vercel environment variables
- [ ] Added `VITE_SUPABASE_ANON_KEY` to Vercel environment variables
- [ ] Added `VITE_APP_URL` with correct domain to Vercel
- [ ] Verified all variable names start with `VITE_`
- [ ] Selected correct environments (Production/Preview/Development)
- [ ] Triggered a redeploy after adding variables
- [ ] Tested payment initialization on deployed site
- [ ] Verified no console errors in browser
- [ ] Confirmed Paystack modal opens correctly

## Alternative: Using Vercel CLI

If you prefer using the command line:

### Install Vercel CLI
```bash
npm install -g vercel
```

### Login to Vercel
```bash
vercel login
```

### Link Your Project
```bash
vercel link
```

### Add Environment Variables
```bash
# Add a single variable
vercel env add VITE_PAYSTACK_PUBLIC_KEY

# You'll be prompted to enter the value
# and select which environments to apply to
```

### Deploy
```bash
# Deploy to preview
vercel

# Deploy to production
vercel --prod
```

## Quick Reference

### Vercel Dashboard URLs
- **Main Dashboard**: https://vercel.com/dashboard
- **Project Settings**: https://vercel.com/[username]/smart-ajo/settings
- **Environment Variables**: https://vercel.com/[username]/smart-ajo/settings/environment-variables
- **Deployments**: https://vercel.com/[username]/smart-ajo/deployments

### Essential Vercel Commands
```bash
# Deploy to preview
vercel

# Deploy to production
vercel --prod

# Pull environment variables to local
vercel env pull

# List all environment variables
vercel env ls
```

## Related Documentation

- [Vercel Environment Variables Guide](https://vercel.com/docs/projects/environment-variables)
- [Vite Environment Variables](https://vitejs.dev/guide/env-and-mode.html)
- [ENVIRONMENT_SETUP.md](./ENVIRONMENT_SETUP.md) - General environment setup
- [PAYSTACK_CONFIGURATION.md](./PAYSTACK_CONFIGURATION.md) - Paystack configuration guide
- [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) - Complete deployment guide

## Support

If you continue to experience issues:

1. **Check Vercel Status**: https://www.vercel-status.com/
2. **Vercel Support**: https://vercel.com/support
3. **Paystack Support**: support@paystack.com
4. **Review Build Logs**: Check deployment logs in Vercel dashboard

## Summary

The key points to remember:

1. ✅ Vite variables need `VITE_` prefix
2. ✅ Variables must be set in Vercel dashboard
3. ✅ Variables are build-time, not runtime
4. ✅ Must redeploy after adding variables
5. ✅ Local `.env` files are NOT used by Vercel

Following this guide will resolve the "Paystack public key not configured" error on Vercel deployments.
