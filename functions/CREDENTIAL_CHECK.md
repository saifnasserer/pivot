# 🔑 Credential Verification Needed

## Current Status

✅ Secrets are configured (version 2)  
✅ Functions have access to secrets  
❌ Backblaze is rejecting the credentials with "bad_auth_token"

## Issue: Application Key Appears Truncated

The application key you provided:

```
K003BVVBrdwOzxSRp5Ncv+lvuMmvreU
```

**This looks incomplete!** Backblaze application keys are typically **40-60 characters** long and look like:

```
K003BVVBrdwOzxSRp5Ncv+lvuMmvreU1234567890abcdefg
```

## ⚠️ Please Verify in Backblaze Console

1. Go to: https://secure.backblaze.com/app_keys.htm
2. Find the "pivot" key
3. Click **"Show"** or the eye icon
4. You should see the **FULL application key**

**Make sure to copy the ENTIRE key**, not just the first part!

## What the Full Key Should Look Like

```
keyID: 003a81351b57fa10000000001 ✅ (This looks correct - 25 characters)
applicationKey: K003BVVBrdwOzxSRp5Ncv+lvuMmvreU????????????????
                                                    ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑
                                                    Missing characters?
```

Typical B2 application keys are 40-60 characters with:

- Letters (uppercase and lowercase)
- Numbers
- Special characters like `+` and `/`

## Quick Test

Once you have the FULL application key:

### Update the Secret

```bash
firebase functions:secrets:set B2_APPLICATION_KEY
# Paste the COMPLETE application key
```

### Redeploy

```bash
firebase deploy --only functions:generate_upload_url
```

### Test Locally First

```bash
cd functions
export BACKBLAZE_KEY_ID="003a81351b57fa10000000001"
export BACKBLAZE_APPLICATION_KEY="<PASTE_FULL_KEY_HERE>"
python3 test_backblaze.py
```

If the local test passes, then deploy to Firebase.

---

**Please provide the COMPLETE application key from Backblaze console.**
