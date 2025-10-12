# ⚠️ Backblaze Credential Issue

## Current Problem

**Error:** `bad_auth_token` from Backblaze  
**Meaning:** The credentials are being read from Firebase Secrets, but Backblaze is rejecting them

## What We Need to Verify

### 1. Application Key ID Format

Backblaze Application Key IDs typically look like this:

```
Format: <accountId><keyId>
Example: 005a81351b57fa1000000001
         ^^^^^^^^ Account ID
                 ^^^^^^^^^^^^ Key ID
```

**What you provided:** `a81351b57fa1`

This looks like it might be missing the **Account ID prefix**.

### 2. How to Get the Correct Application Key ID

Go to Backblaze B2 → App Keys:

1. **Click on "Show" next to your Master Application Key**
2. You should see:
   - **keyID:** This is the FULL application key ID (e.g., `005a81351b57fa1000000001`)
   - **applicationKey:** The long secret key

### 3. What to Check

Please verify in your Backblaze console:

**Account Settings:**

- What is your **Account ID**? (found in "My Account" → "Account Info")

**App Keys:**

- What is the **full keyID** for "Master Application Key"?
  (It should be longer than just `a81351b57fa1`)

## Quick Fix Steps

### Option 1: Use Full Application Key ID

If your full keyID is something like `005a81351b57fa1000000001`:

```bash
# Update the secret
firebase functions:secrets:set B2_KEY_ID
# Paste the FULL keyID (e.g., 005a81351b57fa1000000001)

# Redeploy
firebase deploy --only functions:generate_upload_url
```

### Option 2: Create a New Application Key

If you're unsure about the current key:

1. Go to Backblaze B2 → App Keys
2. **Create New Application Key:**
   - Name: `pivot-materials-upload`
   - Bucket: `pivot-materials`
   - Permissions: `readFiles`, `writeFiles`, `deleteFiles`, `listFiles`
3. **IMMEDIATELY copy both:**
   - `keyID` (the full ID, looks like `005...`)
   - `applicationKey` (the long secret)
4. Update Firebase Secrets with the new credentials

### Option 3: Check Account ID

1. Go to Backblaze → My Account
2. Find your **Account ID** (6-digit number like `005abc`)
3. The correct keyID should be: `<accountId><shortKeyId>`
   - Example: `005abc` + `a81351b57fa1` = `005abca81351b57fa1`

## Current Credentials in Firebase

```bash
# Check what's currently stored
firebase functions:secrets:access B2_KEY_ID
firebase functions:secrets:access B2_APPLICATION_KEY
```

## Test Script

After updating credentials, test with this script:

```bash
cd functions
export BACKBLAZE_KEY_ID="<your_full_keyID>"
export BACKBLAZE_APPLICATION_KEY="<your_app_key>"
python3 test_backblaze.py
```

If local tests pass, then:

```bash
firebase functions:secrets:set B2_KEY_ID
firebase functions:secrets:set B2_APPLICATION_KEY
firebase deploy --only functions:generate_upload_url
```

## Most Likely Issue

The keyID `a81351b57fa1` is missing the **Account ID prefix**.

**Please check your Backblaze console and provide the FULL keyID.**

It should look something like:

- `005a81351b57fa1000000001` (longer, starts with your account ID)

Not just:

- `a81351b57fa1` (this is incomplete)
