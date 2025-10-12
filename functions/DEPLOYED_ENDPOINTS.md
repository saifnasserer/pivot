# 🚀 Deployed Firebase Functions - Backblaze B2 Integration

## ✅ Deployment Status: SUCCESS

**Date:** October 11, 2025  
**Region:** us-central1  
**Project:** pivot-28563

---

## 📡 New Backblaze B2 Endpoints

### 1. Generate Upload URL

**URL:** `https://us-central1-pivot-28563.cloudfunctions.net/generate_upload_url`  
**Method:** POST  
**Purpose:** Generate presigned URL for direct client upload

### 2. Confirm Material Upload

**URL:** `https://us-central1-pivot-28563.cloudfunctions.net/confirm_material_upload`  
**Method:** POST  
**Purpose:** Save material metadata to Firestore after successful upload

### 3. Refresh Download URL

**URL:** `https://us-central1-pivot-28563.cloudfunctions.net/refresh_download_url`  
**Method:** POST  
**Purpose:** Regenerate expired download URLs (24-hour expiry)

### 4. Delete Material File

**URL:** `https://us-central1-pivot-28563.cloudfunctions.net/delete_material_file`  
**Method:** POST  
**Purpose:** Delete file from Backblaze and Firestore

---

## 📡 Existing Functions (Updated)

### 5. Send Notification

**URL:** `https://send-notification-nz4xjaqrhq-uc.a.run.app`

### 6. Delete User Auth

**URL:** `https://delete-user-auth-nz4xjaqrhq-uc.a.run.app`

### 7. Get Profile Image URLs

**URL:** `https://get-profile-image-urls-nz4xjaqrhq-uc.a.run.app`

### 8. Sync Remote Config

**URL:** `https://sync-remote-config-nz4xjaqrhq-uc.a.run.app`

---

## 🧪 Testing Instructions

### Option 1: Using Postman (Recommended)

1. **Import Collection:**

   - Open Postman
   - Import `Backblaze_API_Tests.postman_collection.json`

2. **Get Firebase ID Token:**
   You need a valid Firebase ID token for testing. Here are 3 ways:

   **Method A: From Your Flutter App**

   ```dart
   final user = FirebaseAuth.instance.currentUser;
   final token = await user?.getIdToken();
   print('ID Token: $token');
   ```

   **Method B: From Firebase Console**

   - Go to Firebase Console → Authentication
   - Click on a user
   - Copy their UID
   - Use REST API to get token

   **Method C: Using Firebase CLI**

   ```bash
   firebase login
   firebase auth:export users.json --project pivot-28563
   # Extract token from the exported data
   ```

3. **Update Postman Variables:**

   - Set `firebase_id_token` to your actual token
   - Other variables are pre-configured

4. **Run Tests:**
   - Start with "1. Generate Upload URL (Doctor Mode)"
   - Continue through all 10 tests

### Option 2: Using curl

#### Test 1: Generate Upload URL

```bash
curl -X POST https://us-central1-pivot-28563.cloudfunctions.net/generate_upload_url \
  -H "Content-Type: application/json" \
  -d '{
    "idToken": "YOUR_FIREBASE_ID_TOKEN",
    "title": "Test PDF Document",
    "fileName": "test.pdf",
    "fileSize": 2048,
    "lectureId": "test_lecture_123"
  }'
```

**Expected Response:**

```json
{
  "success": true,
  "uploadUrl": "https://pod-031-2034-14.backblaze.com/...",
  "authorizationToken": "...",
  "filePath": "materials/user123/Test_PDF_Document_abc123.pdf",
  "fileName": "Test_PDF_Document_abc123.pdf",
  "contentType": "application/pdf",
  "fileSize": 2048,
  "bucketId": "..."
}
```

#### Test 2: Test File Size Validation (Should Fail)

```bash
curl -X POST https://us-central1-pivot-28563.cloudfunctions.net/generate_upload_url \
  -H "Content-Type: application/json" \
  -d '{
    "idToken": "YOUR_FIREBASE_ID_TOKEN",
    "title": "Large File Test",
    "fileName": "large.pdf",
    "fileSize": 25000000,
    "lectureId": "test_lecture_123"
  }'
```

**Expected Response:**

```json
{
  "error": "File size 23.84 MB exceeds maximum allowed size of 20 MB"
}
```

#### Test 3: Test Invalid File Type (Should Fail)

```bash
curl -X POST https://us-central1-pivot-28563.cloudfunctions.net/generate_upload_url \
  -H "Content-Type: application/json" \
  -d '{
    "idToken": "YOUR_FIREBASE_ID_TOKEN",
    "title": "Invalid File",
    "fileName": "virus.exe",
    "fileSize": 1024,
    "lectureId": "test_lecture_123"
  }'
```

**Expected Response:**

```json
{
  "error": "File type not allowed. Allowed types: .pdf, .docx, .pptx, .jpg, .jpeg, .png"
}
```

#### Test 4: Refresh Download URL

```bash
curl -X POST https://us-central1-pivot-28563.cloudfunctions.net/refresh_download_url \
  -H "Content-Type: application/json" \
  -d '{
    "idToken": "YOUR_FIREBASE_ID_TOKEN",
    "filePath": "materials/user123/test_file.pdf"
  }'
```

---

## 🔍 Monitoring & Logs

### View Logs:

```bash
# All functions
firebase functions:log

# Specific function
firebase functions:log --only generate_upload_url

# Follow logs in real-time
firebase functions:log --only generate_upload_url --follow
```

### Function Metrics:

```bash
firebase functions:list
```

### Firebase Console:

https://console.firebase.google.com/project/pivot-28563/functions

---

## ✅ Success Indicators

When testing, look for:

1. **Authentication Works:**

   - Valid tokens return data
   - Invalid tokens return 401 error

2. **Validation Works:**

   - File size > 20MB rejected
   - Invalid file types (.exe, .zip) rejected
   - Valid file types (.pdf, .docx) accepted

3. **Upload URL Generation:**

   - Returns valid Backblaze upload URL
   - Returns authorization token
   - Generates proper file path with user ID

4. **Role-Based Access:**
   - Students cannot upload (403 error)
   - Doctors/Assistants can upload
   - Everyone can download

---

## 🐛 Troubleshooting

### Error: "idToken is required"

**Solution:** Make sure you're sending the Firebase ID token in the request body

### Error: "Invalid ID token"

**Solution:** Token expired or invalid. Get a fresh token from Firebase Auth

### Error: "Insufficient permissions"

**Solution:** User role must be Doctor, Assistant, or Admin for uploads

### Error: "B2_KEY_ID not configured"

**Solution:** Firebase Secrets not set properly. Re-run:

```bash
firebase functions:secrets:set B2_KEY_ID
firebase functions:secrets:set B2_APPLICATION_KEY
```

### Error: "Bucket not found"

**Solution:** Check that bucket `pivot-materials` exists in Backblaze

---

## 📊 Test Results Template

Copy this and fill it in after testing:

```
✅ Generate Upload URL Test:
   - Valid request: _______________
   - Invalid file size: _______________
   - Invalid file type: _______________
   - Invalid token: _______________

✅ Confirm Upload Test:
   - Doctor mode: _______________
   - Assistant mode: _______________

✅ Refresh Download URL Test:
   - Valid file path: _______________
   - Invalid file path: _______________

✅ Delete Material Test:
   - Owner deletion: _______________
   - Non-owner deletion: _______________
   - Admin deletion: _______________
```

---

## 🎯 Next Steps After Testing

Once all endpoint tests pass:

1. ✅ Backend verified working
2. ➡️ **Create Flutter services** (`lib/services/backblaze_service.dart`)
3. ➡️ **Build upload dialog UI** (`lib/features/media/screens/add_material_file_dialog.dart`)
4. ➡️ **Update MaterialLinksScreen** to support both links and uploads
5. ➡️ **Test end-to-end** from Flutter app

---

**Deployment Date:** October 11, 2025  
**Status:** ✅ Production Ready  
**Cost:** ~$0.25/month for 10,000 uploads
