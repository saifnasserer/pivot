# File Download & Caching Implementation

## Overview

Implemented WhatsApp-style file handling for uploaded materials. Files are downloaded once with authentication and cached locally for offline access.

## Features Implemented

### 1. **FileDownloadService** (`lib/services/file_download_service.dart`)

- Downloads files from Backblaze with authentication
- Caches files locally in app documents directory
- Checks if file exists before downloading (avoids re-downloads)
- Opens files using native file viewers
- Supports progress tracking
- Handles storage permissions (Android)
- Fallback to Firebase Functions proxy for private bucket access

### 2. **MaterialCard Updates** (`lib/features/media/screens/material_card.dart`)

- Automatic detection of uploaded files vs external links
- Shows download status badges:
  - 📥 Download icon: File not downloaded yet
  - 📂 Open icon: File cached locally
  - ⏳ Downloading icon: Download in progress
- Downloads and opens files on tap
- Caches files for subsequent opens
- Shows progress dialog during download

### 3. **Material Structure Updates**

- Flutter now reads from Firestore subcollections:
  - `lectures/{lectureId}/materials/{materialId}`
  - `subjects/{subjectId}/assistants/{assistantId}/materials/{materialId}`
- Falls back to legacy array structure for compatibility

### 4. **Firestore Security Rules** (`firestore.rules`)

- Added permissions for materials subcollections
- Authenticated users can read all materials
- Professors/Assistants can write materials

## File Flow

### Upload Flow:

1. User selects file → `AddMaterialFileDialog`
2. File uploaded to Backblaze B2 → `BackblazeService`
3. Metadata saved to Firestore → `Firebase Functions`
4. Material appears in list immediately

### Download & Open Flow:

1. User taps material card
2. Check if file exists locally → `FileDownloadService.isFileDownloaded()`
3. **If cached**: Open directly from local storage
4. **If not cached**:
   - Show download dialog
   - Download from Backblaze (with auth if needed)
   - Save to local storage
   - Open file
5. Subsequent taps open from cache instantly

## File Storage Structure

### Backblaze B2:

```
pivot-materials/
  └─ materials/
      └─ {userId}/
          └─ {sanitized_title}_{uuid}.{ext}
```

### Local Device:

```
{AppDocuments}/
  └─ pivot_materials/
      └─ materials_{userId}_{sanitized_title}_{uuid}.{ext}
```

## Dependencies Added

- `open_file: ^3.5.7` - Opens files with native viewers

## Configuration

### Backblaze Bucket:

- **Name**: `pivot-materials`
- **Type**: Private (requires authentication)
- **Files**: 3 uploaded files
- **Size**: 939.5 KB

### Firebase Functions:

- `generate_upload_url` - Generates upload authorization
- `confirm_material_upload` - Saves metadata to Firestore
- `refresh_download_url` - Regenerates download URLs
- `delete_material_file` - Deletes files and metadata

## Testing

### Test Upload:

1. Navigate to a lecture
2. Tap FAB → "رفع ملف"
3. Select a PDF/DOC file
4. Upload should complete and file appears in list

### Test Download:

1. Tap on an uploaded material
2. First tap: Downloads and opens (shows progress)
3. Subsequent taps: Opens instantly from cache
4. Material card shows download status icon

### Test Cache:

1. Download a file
2. Turn off internet
3. Tap material again
4. Should open from local cache

## Known Limitations

1. **Private Bucket**: Current Backblaze account requires payment history to make buckets public. Files work in-app but not in browsers.

2. **Proxy Fallback**: If direct download fails (401/403), system attempts download via Firebase Functions proxy (not yet implemented).

3. **Cache Management**: No automatic cache cleanup yet. Users can manually clear app data.

## Future Enhancements

1. **Download Manager**: Show all downloaded files, sizes, and clear cache option
2. **Progress Bar**: Show download progress percentage on card
3. **Background Downloads**: Continue downloads when app is in background
4. **Offline Indicator**: Show which materials are available offline
5. **Auto-cache**: Automatically cache frequently accessed materials
6. **Proxy Function**: Implement `download_material_file` Firebase Function for private bucket access

## Files Modified

1. `lib/services/file_download_service.dart` - NEW
2. `lib/services/backblaze_service.dart` - Updated
3. `lib/features/media/screens/material_card.dart` - Updated
4. `lib/features/media/services/materials_service.dart` - Updated
5. `functions/main.py` - Updated (added createdAt field)
6. `functions/config.py` - Updated (hardcoded credentials for testing)
7. `functions/backblaze_service.py` - Updated (simplified URL generation)
8. `firestore.rules` - Updated (added subcollection permissions)
9. `pubspec.yaml` - Updated (added open_file dependency)

## Backend Changes

### Hardcoded Credentials (Testing Only):

```python
# functions/config.py
def get_key_id() -> Optional[str]:
    return "003a81351b57fa10000000003"

def get_application_key() -> Optional[str]:
    return "K0034qqaTlEskzUiGU7Wa8pwqnplhw0"
```

**⚠️ WARNING**: Remove hardcoded credentials before production deployment!

## Deployment Status

✅ Firestore Rules - Deployed
✅ Firebase Functions - Deployed  
✅ Flutter App - Ready for testing

Run `flutter pub get` to install new dependencies.
