# Codemagic iOS Build Setup for IntentOS Mobile

## 🚀 Quick Start - Install on iPhone WITHOUT Mac

### The Magic Happens Here:
Codemagic builds your app on their servers (macOS in the cloud) and sends it to your iPhone via TestFlight.

---

## 📋 Prerequisites

1. **Apple Developer Account** ($99/year)
2. **GitHub Account** (already have it)
3. **Codemagic Account** (free, sign up with GitHub)

---

## ✅ Step-by-Step Setup

### Step 1: Create Apple Developer Account
1. Go to [developer.apple.com](https://developer.apple.com)
2. Sign in with Apple ID (or create new Apple ID)
3. Enroll in Apple Developer Program ($99/year)
4. Accept agreements

### Step 2: Create App in App Store Connect
1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Sign in with Apple ID
3. Click **"My Apps"** → **"+"** → **"New App"**
4. Fill in:
   - Platform: **iOS**
   - Name: **IntentOS Mobile**
   - Bundle ID: **com.intentos.mobile**
   - SKU: **intentos.mobile**
   - User Access: **None**
5. Click **"Create"**
6. Fill in app details:
   - Description
   - Screenshots (at least 2)
   - Support URL
   - Privacy Policy URL (can use simple placeholder)
7. **Note the App ID** (you'll need this)

### Step 3: Add TestFlight Testers
1. In App Store Connect, go to **TestFlight** tab
2. Click **"Testers and Groups"** → **"+"**
3. Enter your email address
4. Set maximum testers (at least 2)
5. Click **"Create"**
6. You'll get invitation email

### Step 4: Set Up Codemagic

**4a. Create Codemagic Account:**
1. Go to [codemagic.io](https://codemagic.io)
2. Click **"Sign up"**
3. Sign in with **GitHub**
4. Grant access to your repositories

**4b. Add Your Repository:**
1. In Codemagic dashboard, click **"Add application"**
2. Find **`-IntentOSMobile`** repository
3. Click **"Add"**
4. Select **iOS** as platform

**4c. Configure Code Signing (EASIEST METHOD):**
1. Go to **App Settings → Code Signing**
2. Under **iOS signing**, click **"Fetch from App Store Connect"**
3. Sign in with your **Apple ID**
4. Select your **Team**
5. Select certificate type: **"Automatic"**
6. Codemagic handles everything! ✅

### Step 5: Set Environment Variables

In Codemagic **App Settings → Environment variables**, add:

```
APP_STORE_APP_ID = (your app ID from Step 2)
BUILD_EMAIL = your.email@gmail.com
```

### Step 6: Start First Build

1. In Codemagic, click **"Start new build"**
2. Select branch: **main**
3. Click **"Build"**
4. Watch the build log in real-time!

**Build typically takes 5-10 minutes** ⏳

### Step 7: Install on iPhone via TestFlight

**Once build completes:**
1. Open **TestFlight app** on your iPhone
2. Tap **Your Email** (top right)
3. Look for **"IntentOS Mobile"**
4. Tap **"Install"**
5. Wait for download
6. App opens! 🎉

---

## 🎯 How It Works

```
You push code to GitHub
        ↓
Codemagic webhook triggered
        ↓
Codemagic Mac server clones repo
        ↓
Compiles with Xcode (in cloud)
        ↓
Runs tests
        ↓
Creates IPA file
        ↓
Signs with your certificate
        ↓
Uploads to TestFlight
        ↓
TestFlight sends notification to your iPhone
        ↓
You tap "Install" in TestFlight
        ↓
App runs on your iPhone! 📱
```

**NO MAC REQUIRED!** Everything happens in the cloud. ☁️

---

## 🔑 Code Signing Explained

### Option 1: Automatic Signing (RECOMMENDED)
- Codemagic signs in with your Apple ID
- Fetches certificates from Apple
- Handles expiration automatically
- **EASIEST - USE THIS**

### Option 2: Manual Certificates
- You download `.cer` and `.mobileprovision` files
- Upload to Codemagic
- More work, same result

---

## 📱 Testing the App

**Once installed on iPhone:**

1. **Grant Permissions** (system will ask):
   - Microphone access
   - Screen recording (iOS 17+)

2. **Test Features:**
   - Tap "Talk" → Say something
   - Tap "Share Full Screen" → Select screen
   - Tap "Send to IntentOS"
   - See AI response

3. **Use Mock Mode:**
   - App runs in mock mode by default
   - No backend needed to test
   - Connect real backend later

---

## 🚀 Subsequent Builds

**After first setup:**

1. Make code changes on your computer
2. Push to GitHub: `git push origin main`
3. Codemagic auto-builds (webhook)
4. ~10 minutes later → TestFlight notification
5. Install new version on iPhone

**That's it!** No Mac needed ever! 🎊

---

## 🆘 Troubleshooting

### Build Failed - Code Signing
**Error:** "Code signing failed"
**Fix:** 
- Re-check Apple ID sign-in
- Verify team selection
- Check if certificate expired in App Store Connect

### Build Failed - Bundle ID
**Error:** "Bundle ID mismatch"
**Fix:**
- Ensure `com.intentos.mobile` matches App Store Connect
- Update in Codemagic if needed

### TestFlight Notification Not Received
**Fix:**
- Check spam folder
- Verify email in App Store Connect
- Check TestFlight app (might be there without email)

### Build Takes Forever
**Normal:** First build = 10-15 minutes
**Subsequent:** 5-10 minutes

---

## 📊 Monitor Builds

In Codemagic Dashboard:
- ✅ View real-time build logs
- ✅ Download IPA files
- ✅ View test results
- ✅ Track deployment status
- ✅ Set up Slack notifications

---

## 🔐 Security Notes

- ✅ Certificates stored securely in Codemagic
- ✅ Only Codemagic accesses your certificates
- ✅ You never expose private keys
- ✅ TestFlight is Apple's testing platform (trusted)

---

## 🎯 What's Next?

1. **Make changes to code** (any computer, any OS)
2. **Commit and push to GitHub**
3. **Codemagic builds automatically**
4. **Install on iPhone via TestFlight**
5. **Repeat!** ♻️

---

## 📚 Useful Links

- Codemagic Docs: https://docs.codemagic.io/
- App Store Connect: https://appstoreconnect.apple.com/
- Apple Developer: https://developer.apple.com/
- TestFlight Guide: https://developer.apple.com/testflight/

---

## ✨ You Now Have:

✅ Professional CI/CD pipeline  
✅ Automatic builds on every code push  
✅ Automatic TestFlight deployment  
✅ Easy installation on iPhone  
✅ NO MAC REQUIRED  
✅ Professional iOS app! 🚀
