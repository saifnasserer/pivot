# Backblaze B2 Integration Setup Guide

This guide will help you set up and deploy the Backblaze B2 file upload system for the Pivot educational materials platform.

## 📋 Prerequisites

- ✅ Backblaze B2 account
- ✅ Firebase project with Functions enabled
- ✅ Python 3.12 installed locally
- ✅ Firebase CLI installed (`npm install -g firebase-tools`)

---

## 🔐 Step 1: Configure Backblaze Credentials

### Option A: Local Testing (Environment Variables)

For local testing, set environment variables:

```bash
export BACKBLAZE_KEY_ID="a81351b57fa1"
export BACKBLAZE_APPLICATION_KEY="003603dea751e56adcf1564c322a5a2f8ef093fcfe"
```

### Option B: Firebase Secrets (Production)

For deployed functions, use Firebase Secrets Manager:

```bash
# Set the Backblaze Key ID
firebase functions:secrets:set B2_KEY_ID
# When prompted, paste: a81351b57fa1

# Set the Backblaze Application Key
firebase functions:secrets:set B2_APPLICATION_KEY
# When prompted, paste: 003603dea751e56adcf1564c322a5a2f8ef093fcfe
```

To verify secrets are set:

```bash
firebase functions:secrets:access B2_KEY_ID
firebase functions:secrets:access B2_APPLICATION_KEY
```

---

## 🧪 Step 2: Local Testing

### Install Dependencies

```bash
cd functions
python3 -m pip install -r requirements.txt
```

### Run Test Script

```bash
# Set environment variables first (if not already set)
export BACKBLAZE_KEY_ID="a81351b57fa1"
export BACKBLAZE_APPLICATION_KEY="003603dea751e56adcf1564c322a5a2f8ef093fcfe"

# Run tests
python3 test_backblaze.py
```

Expected output:

```
╔═══════════════════════════════════════════════════════════╗
║         BACKBLAZE B2 INTEGRATION TEST SUITE             ║
║                  Pivot Materials Upload                   ║
╚═══════════════════════════════════════════════════════════╝

============================================================
               TEST 1: Configuration Validation
============================================================

✓ Key ID found: a81351b57f...
✓ Application Key found: 003603dea7...
✓ Configuration is valid
...

🎉 All tests passed! Backend is ready.
```

---

## 🚀 Step 3: Deploy to Firebase

### Deploy Functions

```bash
# Make sure you're in the project root
cd /media/saif/brain/Projects/02-Pivot

# Deploy only the functions
firebase deploy --only functions
```

This will deploy the following endpoints:

- `generate_upload_url` - Generate presigned upload URL
- `confirm_material_upload` - Save material metadata after upload
- `refresh_download_url` - Regenerate expired download URLs
- `delete_material_file` - Delete file from storage

### Monitor Deployment

```bash
# View function logs
firebase functions:log

# Follow logs in real-time
firebase functions:log --only generate_upload_url
```

---

## 🧪 Step 4: Test Deployed Endpoints

### Get Your Function URL

After deployment, Firebase will show URLs like:

```
Function URL (generate_upload_url): https://us-central1-pivot-28563.cloudfunctions.net/generate_upload_url
```

### Test with curl

#### 1. Generate Upload URL

```bash
# First, get a Firebase ID token from your app or using Firebase Auth REST API
# For testing, you can use the Firebase console to get a token

curl -X POST https://us-central1-pivot-28563.cloudfunctions.net/generate_upload_url \
  -H "Content-Type: application/json" \
  -d '{
    "idToken": "YOUR_FIREBASE_ID_TOKEN",
    "title": "Test Material",
    "fileName": "test.pdf",
    "fileSize": 2048,
    "lectureId": "test_lecture_123"
  }'
```

Expected response:

```json
{
  "success": true,
  "uploadUrl": "https://pod-000-1056-11.backblaze.net/...",
  "authorizationToken": "...",
  "filePath": "materials/user_123/Test_Material_abc123.pdf",
  "fileName": "Test_Material_abc123.pdf",
  "contentType": "application/pdf"
}
```

#### 2. Test Download URL Refresh

```bash
curl -X POST https://us-central1-pivot-28563.cloudfunctions.net/refresh_download_url \
  -H "Content-Type: application/json" \
  -d '{
    "idToken": "YOUR_FIREBASE_ID_TOKEN",
    "filePath": "materials/user_123/Test_Material_abc123.pdf"
  }'
```

---

## 📦 API Reference

### 1. `generate_upload_url`

Generate a presigned URL for direct upload to Backblaze.

**Request:**

```json
{
  "idToken": "firebase_id_token",
  "title": "Material Title",
  "fileName": "document.pdf",
  "fileSize": 1024000,
  "lectureId": "lecture123", // For doctor mode
  "subjectId": "subject123", // For assistant mode
  "assistantId": "assistant123" // For assistant mode
}
```

**Response:**

```json
{
  "success": true,
  "uploadUrl": "https://...",
  "authorizationToken": "...",
  "filePath": "materials/user123/file.pdf",
  "fileName": "file.pdf",
  "contentType": "application/pdf",
  "fileSize": 1024000,
  "bucketId": "..."
}
```

---

### 2. `confirm_material_upload`

Confirm successful upload and save metadata to Firestore.

**Request:**

```json
{
  "idToken": "firebase_id_token",
  "title": "Material Title",
  "description": "Optional description",
  "filePath": "materials/user123/file.pdf",
  "fileName": "file.pdf",
  "fileSize": 1024000,
  "contentType": "application/pdf",
  "lectureId": "lecture123"
}
```

**Response:**

```json
{
  "success": true,
  "materialId": "generated_material_id",
  "downloadUrl": "https://..."
}
```

---

### 3. `refresh_download_url`

Regenerate download URL (expires after 24 hours).

**Request:**

```json
{
  "idToken": "firebase_id_token",
  "filePath": "materials/user123/file.pdf"
}
```

**Response:**

```json
{
  "success": true,
  "downloadUrl": "https://..."
}
```

---

### 4. `delete_material_file`

Delete file from Backblaze and Firestore.

**Request:**

```json
{
  "idToken": "firebase_id_token",
  "filePath": "materials/user123/file.pdf",
  "materialId": "material123",
  "lectureId": "lecture123"
}
```

**Response:**

```json
{
  "success": true,
  "message": "Material deleted successfully"
}
```

---

## 🔧 Configuration

### File Restrictions

**Maximum file size:** 20 MB

**Allowed file types:**

- PDF: `.pdf`
- Documents: `.docx`, `.pptx`
- Images: `.jpg`, `.jpeg`, `.png`

**File naming:** User-friendly (based on title + unique ID)

**Download URL expiry:** 24 hours

---

## 🐛 Troubleshooting

### Issue: "B2_KEY_ID not configured"

**Solution:** Make sure you've set Firebase Secrets:

```bash
firebase functions:secrets:set B2_KEY_ID
firebase functions:secrets:set B2_APPLICATION_KEY
```

---

### Issue: "File size exceeds maximum"

**Solution:** The limit is 20 MB. Update `MAX_FILE_SIZE_MB` in `config.py` if needed.

---

### Issue: "File type not allowed"

**Solution:** Check `ALLOWED_EXTENSIONS` in `config.py` to see supported types.

---

### Issue: "Failed to initialize Backblaze service"

**Solution:**

1. Verify bucket exists: Log in to Backblaze and check `pivot-materials` bucket
2. Verify credentials are correct
3. Check B2 API status: https://www.backblazestatuswiki.com/

---

## 💰 Cost Monitoring

### Backblaze B2 Costs

- **Storage:** $0.005/GB/month (~$0.25 for 50GB)
- **Downloads:** $0.01/GB (first 1GB/day free)
- **Uploads:** FREE

### Firebase Functions Costs

- **Free tier:** 2M invocations/month
- **Paid:** $0.40 per million invocations after free tier

**Estimated monthly cost for 10,000 uploads:**

- Backblaze: ~$0.25-$0.50
- Firebase Functions: $0 (within free tier)
- **Total: <$1/month**

---

## 📝 Next Steps

After successful deployment:

1. ✅ **Test all endpoints** using Postman or curl
2. ✅ **Monitor logs** for any errors
3. ✅ **Create Flutter service** to integrate with backend
4. ✅ **Build upload UI** in the materials screen
5. ✅ **Test end-to-end flow** with real files

---

## 📚 Additional Resources

- [Backblaze B2 Documentation](https://www.backblaze.com/b2/docs/)
- [Firebase Functions Documentation](https://firebase.google.com/docs/functions)
- [Firebase Secrets Manager](https://firebase.google.com/docs/functions/config-env#secret-manager)

---

## 🆘 Support

If you encounter issues:

1. Check Firebase Functions logs: `firebase functions:log`
2. Verify Backblaze bucket settings
3. Ensure all secrets are properly configured
4. Run local tests first before deploying
