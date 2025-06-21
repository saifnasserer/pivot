# Firebase Functions - Notification Service

This directory contains the Firebase Cloud Function for sending push notifications.

## Setup

1. **Install dependencies:**

   ```bash
   cd functions
   pip install -r requirements.txt
   ```

2. **Service Account:**
   - Make sure `pivot-28563-firebase-adminsdk-fbsvc-12baa1b7d9.json` is in the functions directory
   - This file contains the Firebase Admin SDK credentials

## Local Testing

1. **Start the function locally:**

   ```bash
   cd functions
   functions-framework --target=send_notification --port=8080
   ```

2. **Test the function:**

   ```bash
   python test_function.py
   ```

   **Note:** Replace `YOUR_FCM_TOKEN_HERE` in `test_function.py` with an actual FCM token from your Flutter app.

3. **Manual testing with curl:**
   ```bash
   curl -X POST http://localhost:8080 \
     -H "Content-Type: application/json" \
     -d '{
       "token": "YOUR_FCM_TOKEN_HERE",
       "title": "Test Title",
       "body": "Test Body"
     }'
   ```

## Deployment

1. **Deploy to Firebase:**

   ```bash
   firebase deploy --only functions
   ```

2. **Get the function URL:**
   After deployment, Firebase will provide a URL like:
   `https://us-central1-pivot-28563.cloudfunctions.net/send_notification`

## Usage from Flutter App

```dart
// Example HTTP request from Flutter
final response = await http.post(
  Uri.parse('https://us-central1-pivot-28563.cloudfunctions.net/send_notification'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'token': 'FCM_TOKEN_HERE',
    'title': 'Notification Title',
    'body': 'Notification Body'
  }),
);

if (response.statusCode == 200) {
  print('Notification sent successfully!');
} else {
  print('Failed to send notification: ${response.body}');
}
```

## Function Parameters

- `token` (required): FCM token of the target device
- `title` (optional): Notification title (default: "No Title")
- `body` (optional): Notification body (default: "No Body")

## Response Format

**Success:**

```json
{
  "success": true,
  "message_id": "message_id_from_firebase",
  "message": "Notification sent successfully"
}
```

**Error:**

```json
{
  "error": "Error description"
}
```

## Security Notes

- The function accepts requests from any origin (CORS is set to '\*')
- In production, consider restricting CORS to your app's domain
- The service account key should never be committed to version control
- Consider using environment variables for sensitive data
