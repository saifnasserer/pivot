import firebase_functions
from firebase_functions import https_fn
from firebase_admin import initialize_app, messaging, exceptions, firestore, auth
import json
from datetime import datetime

# Initialize Firebase app
initialize_app()

# Import Backblaze service (lazy import to avoid initialization issues)
def get_b2_service():
    """Lazy import and initialization of Backblaze service"""
    try:
        from backblaze_service import get_backblaze_service
        return get_backblaze_service()
    except Exception as e:
        raise Exception(f"Failed to initialize Backblaze service: {str(e)}")

@https_fn.on_request()
def send_notification(req: https_fn.Request) -> https_fn.Response:
    # Handle CORS
    if req.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '3600'
        }
        return https_fn.Response('', status=204, headers=headers)
    
    # Set CORS headers for the main request
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST',
        'Access-Control-Allow-Headers': 'Content-Type'
    }
    
    try:
        # Only allow POST requests
        if req.method != 'POST':
            return https_fn.Response(
                json.dumps({'error': 'Method not allowed'}),
                status=405,
                headers=headers
            )
        
        data = req.get_json()

        if not data:
            return https_fn.Response(
                json.dumps({'error': 'No data provided'}),
                status=400,
                headers=headers
            )
        
        token = data.get("token")
        title = data.get("title", "No Title")
        body = data.get("body", "No Body")
        icon = data.get("icon", "ic_notification")  # Default to notification icon
        color = data.get("color", "#000000")    # Default to black
        sound = data.get("sound", "default")    # Default sound
        
        # Extract custom data payload, ensuring all values are strings
        custom_data = data.get("data", {})
        if not isinstance(custom_data, dict):
            custom_data = {}

        string_custom_data = {k: str(v) for k, v in custom_data.items()}

        if not token:
            return https_fn.Response(
                json.dumps({'error': 'Token is required'}),
                status=400,
                headers=headers
            )
        
        # Create notification with custom options
        notification = messaging.Notification(
            title=title,
            body=body,
        )
        
        # Create Android-specific configuration
        android_config = messaging.AndroidConfig(
            notification=messaging.AndroidNotification(
                icon=icon,
                color=color,
                sound=sound,
                priority='high',
                default_sound=True,
                default_vibrate_timings=True,
                default_light_settings=True,
            ),
        )
        
        message = messaging.Message(
            notification=notification,
            android=android_config,
            token=token,
            data=string_custom_data,
        )

        response = messaging.send(message)
        return https_fn.Response(
            json.dumps({
                'success': True, 
                'message_id': response,
                'message': 'Notification sent successfully'
            }),
            status=200,
            headers=headers
        )
        
    except exceptions.InvalidArgumentError as e:
        return https_fn.Response(
            json.dumps({'error': f'Invalid argument, likely an invalid token: {str(e)}'}),
            status=400,
            headers=headers
        )
    except messaging.UnregisteredError:
        return https_fn.Response(
            json.dumps({'error': 'Invalid or unregistered token'}),
            status=400,
            headers=headers
        )
    except messaging.QuotaExceededError:
        return https_fn.Response(
            json.dumps({'error': 'Quota exceeded'}),
            status=429,
            headers=headers
        )
    except messaging.SenderIdMismatchError:
        return https_fn.Response(
            json.dumps({'error': 'Sender ID mismatch'}),
            status=400,
            headers=headers
        )
    except messaging.ThirdPartyAuthError:
        return https_fn.Response(
            json.dumps({'error': 'Third party auth error'}),
            status=401,
            headers=headers
        )
    except Exception as e:
        return https_fn.Response(
            json.dumps({'error': f'Internal server error: {str(e)}'}),
            status=500,
            headers=headers
        )

@https_fn.on_request()
def sync_remote_config(req: https_fn.Request) -> https_fn.Response:
    # Handle CORS
    if req.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '3600'
        }
        return https_fn.Response('', status=204, headers=headers)
    
    # Set CORS headers for the main request
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST',
        'Access-Control-Allow-Headers': 'Content-Type'
    }
    
    try:
        # Only allow POST requests
        if req.method != 'POST':
            return https_fn.Response(
                json.dumps({'error': 'Method not allowed'}),
                status=405,
                headers=headers
            )
        
        # Get Firestore client
        db = firestore.client()
        
        # Get update management settings from Firestore
        doc_ref = db.collection('settings').document('update_management')
        doc = doc_ref.get()
        
        if not doc.exists:
            return https_fn.Response(
                json.dumps({'error': 'Update management settings not found'}),
                status=404,
                headers=headers
            )
        
        settings = doc.to_dict()
        
        # Here you would typically update Firebase Remote Config
        # For now, we'll just return the settings
        # In a real implementation, you'd use the Firebase Admin SDK to update Remote Config
        
        return https_fn.Response(
            json.dumps({
                'success': True,
                'message': 'Settings retrieved successfully',
                'settings': settings
            }),
            status=200,
            headers=headers
        )
        
    except Exception as e:
        return https_fn.Response(
            json.dumps({'error': f'Internal server error: {str(e)}'}),
            status=500,
            headers=headers
        )

@https_fn.on_request()
def delete_user_auth(req: https_fn.Request) -> https_fn.Response:
    """
    Delete a user's Firebase Auth account using Admin SDK
    This function can only be called by authenticated admin users
    """
    # Handle CORS
    if req.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '3600'
        }
        return https_fn.Response('', status=204, headers=headers)
    
    # Set CORS headers for the main request
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST',
        'Access-Control-Allow-Headers': 'Content-Type'
    }
    
    try:
        # Only allow POST requests
        if req.method != 'POST':
            return https_fn.Response(
                json.dumps({'error': 'Method not allowed'}),
                status=405,
                headers=headers
            )
        
        data = req.get_json()
        if not data:
            return https_fn.Response(
                json.dumps({'error': 'No data provided'}),
                status=400,
                headers=headers
            )
        
        # Get the user ID to delete
        target_user_id = data.get('targetUserId')
        if not target_user_id:
            return https_fn.Response(
                json.dumps({'error': 'targetUserId is required'}),
                status=400,
                headers=headers
            )
        
        # Get the admin user ID (should be passed from the client)
        admin_user_id = data.get('adminUserId')
        if not admin_user_id:
            return https_fn.Response(
                json.dumps({'error': 'adminUserId is required'}),
                status=400,
                headers=headers
            )
        
        # Verify admin permissions
        db = firestore.client()
        admin_doc = db.collection('users').document(admin_user_id).get()
        
        if not admin_doc.exists:
            return https_fn.Response(
                json.dumps({'error': 'Admin user not found'}),
                status=404,
                headers=headers
            )
        
        admin_data = admin_doc.to_dict()
        admin_role = admin_data.get('role', '')
        
        if admin_role not in ['Admin', 'Super Admin']:
            return https_fn.Response(
                json.dumps({'error': 'Insufficient permissions. Admin role required.'}),
                status=403,
                headers=headers
            )
        
        # Verify target user exists
        target_user_doc = db.collection('users').document(target_user_id).get()
        if not target_user_doc.exists:
            return https_fn.Response(
                json.dumps({'error': 'Target user not found'}),
                status=404,
                headers=headers
            )
        
        # Delete the Firebase Auth account using Admin SDK
        try:
            auth.delete_user(target_user_id)
            
            return https_fn.Response(
                json.dumps({
                    'success': True,
                    'message': f'User {target_user_id} authentication account deleted successfully'
                }),
                status=200,
                headers=headers
            )
            
        except auth.UserNotFoundError:
            return https_fn.Response(
                json.dumps({'error': 'User authentication account not found'}),
                status=404,
                headers=headers
            )
        except Exception as auth_error:
            return https_fn.Response(
                json.dumps({'error': f'Failed to delete auth account: {str(auth_error)}'}),
                status=500,
                headers=headers
            )
        
    except Exception as e:
        return https_fn.Response(
            json.dumps({'error': f'Internal server error: {str(e)}'}),
            status=500,
            headers=headers
        )

@https_fn.on_request()
def get_profile_image_urls(req: https_fn.Request) -> https_fn.Response:
    """
    Get all profile image URLs for storage cleanup
    Admin-only function for security
    """
    # Handle CORS
    if req.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '3600'
        }
        return https_fn.Response('', status=204, headers=headers)
    
    # Set CORS headers for the main request
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST',
        'Access-Control-Allow-Headers': 'Content-Type'
    }
    
    try:
        # Only allow POST requests
        if req.method != 'POST':
            return https_fn.Response(
                json.dumps({'error': 'Method not allowed'}),
                status=405,
                headers=headers
            )
        
        data = req.get_json()
        if not data:
            return https_fn.Response(
                json.dumps({'error': 'No data provided'}),
                status=400,
                headers=headers
            )
        
        # Get the admin user ID
        admin_user_id = data.get('adminUserId')
        if not admin_user_id:
            return https_fn.Response(
                json.dumps({'error': 'adminUserId is required'}),
                status=400,
                headers=headers
            )
        
        # Verify admin permissions
        db = firestore.client()
        admin_doc = db.collection('users').document(admin_user_id).get()
        
        if not admin_doc.exists:
            return https_fn.Response(
                json.dumps({'error': 'Admin user not found'}),
                status=404,
                headers=headers
            )
        
        admin_data = admin_doc.to_dict()
        admin_role = admin_data.get('role', '')
        
        if admin_role not in ['Admin', 'Super Admin']:
            return https_fn.Response(
                json.dumps({'error': 'Insufficient permissions. Admin role required.'}),
                status=403,
                headers=headers
            )
        
        # Fetch profile image URLs from all users
        profile_image_urls = []
        users_ref = db.collection('users')
        users = users_ref.stream()
        
        for user_doc in users:
            user_data = user_doc.to_dict()
            profile_image_url = user_data.get('profileImageUrl')
            if profile_image_url and isinstance(profile_image_url, str):
                profile_image_urls.append(profile_image_url)
        
        return https_fn.Response(
            json.dumps({
                'success': True,
                'profileImageUrls': profile_image_urls,
                'count': len(profile_image_urls)
            }),
            status=200,
            headers=headers
        )
        
    except Exception as e:
        return https_fn.Response(
            json.dumps({'error': f'Internal server error: {str(e)}'}),
            status=500,
            headers=headers
        )


# ============================================================================
# BACKBLAZE B2 FILE UPLOAD ENDPOINTS
# ============================================================================

def _get_cors_headers():
    """Common CORS headers for all endpoints"""
    return {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        'Access-Control-Max-Age': '3600'
    }


def _handle_cors_preflight(req: https_fn.Request) -> https_fn.Response:
    """Handle CORS preflight requests"""
    if req.method == 'OPTIONS':
        return https_fn.Response('', status=204, headers=_get_cors_headers())
    return None


def _verify_firebase_token(id_token: str) -> tuple[bool, dict, str]:
    """
    Verify Firebase ID token and return user info
    Returns: (success, user_info, error_message)
    """
    try:
        decoded_token = auth.verify_id_token(id_token)
        return True, decoded_token, ""
    except auth.InvalidIdTokenError:
        return False, {}, "Invalid ID token"
    except auth.ExpiredIdTokenError:
        return False, {}, "Expired ID token"
    except Exception as e:
        return False, {}, f"Token verification error: {str(e)}"


def _verify_user_permissions(user_id: str, required_roles: list[str]) -> tuple[bool, str]:
    """
    Verify user has required permissions
    Returns: (has_permission, error_message)
    """
    try:
        db = firestore.client()
        user_doc = db.collection('users').document(user_id).get()
        
        if not user_doc.exists:
            return False, "User not found"
        
        user_data = user_doc.to_dict()
        user_role = user_data.get('role', '')
        
        if user_role not in required_roles:
            return False, f"Insufficient permissions. Required roles: {', '.join(required_roles)}"
        
        return True, ""
        
    except Exception as e:
        return False, f"Permission check error: {str(e)}"


@https_fn.on_request()
def generate_upload_url(req: https_fn.Request) -> https_fn.Response:
    """
    Generate a presigned upload URL for direct client-side upload to Backblaze B2
    
    Request body:
    {
        "idToken": "firebase_id_token",
        "title": "Material Title",
        "fileName": "document.pdf",
        "fileSize": 1024000,
        "lectureId": "lecture123" (optional),
        "subjectId": "subject123" (optional),
        "assistantId": "assistant123" (optional)
    }
    
    Response:
    {
        "success": true,
        "uploadUrl": "https://...",
        "authorizationToken": "...",
        "filePath": "materials/user123/file.pdf",
        "fileName": "file.pdf",
        "contentType": "application/pdf"
    }
    """
    # Handle CORS
    cors_response = _handle_cors_preflight(req)
    if cors_response:
        return cors_response
    
    headers = _get_cors_headers()
    
    try:
        # Only allow POST requests
        if req.method != 'POST':
            return https_fn.Response(
                json.dumps({'error': 'Method not allowed'}),
                status=405,
                headers=headers
            )
        
        # Parse request data
        data = req.get_json()
        if not data:
            return https_fn.Response(
                json.dumps({'error': 'No data provided'}),
                status=400,
                headers=headers
            )
        
        # Verify Firebase token
        id_token = data.get('idToken')
        if not id_token:
            return https_fn.Response(
                json.dumps({'error': 'idToken is required'}),
                status=400,
                headers=headers
            )
        
        success, user_info, error_msg = _verify_firebase_token(id_token)
        if not success:
            return https_fn.Response(
                json.dumps({'error': error_msg}),
                status=401,
                headers=headers
            )
        
        user_id = user_info.get('uid')
        
        # Check user permissions (only Doctor and Assistant can upload)
        has_permission, error_msg = _verify_user_permissions(
            user_id,
            ['Doctor', 'Assistant', 'Admin', 'Super Admin']
        )
        if not has_permission:
            return https_fn.Response(
                json.dumps({'error': error_msg}),
                status=403,
                headers=headers
            )
        
        # Validate required fields
        title = data.get('title')
        file_name = data.get('fileName')
        file_size = data.get('fileSize')
        
        if not title or not file_name or file_size is None:
            return https_fn.Response(
                json.dumps({'error': 'title, fileName, and fileSize are required'}),
                status=400,
                headers=headers
            )
        
        # Initialize Backblaze service
        b2_service = get_b2_service()
        
        # Generate upload authorization
        upload_data = b2_service.generate_upload_authorization(
            user_id=user_id,
            title=title,
            original_filename=file_name,
            file_size=file_size
        )
        
        return https_fn.Response(
            json.dumps({
                'success': True,
                **upload_data
            }),
            status=200,
            headers=headers
        )
        
    except ValueError as e:
        # Validation errors (file size, type, etc.)
        return https_fn.Response(
            json.dumps({'error': str(e)}),
            status=400,
            headers=headers
        )
    except Exception as e:
        return https_fn.Response(
            json.dumps({'error': f'Internal server error: {str(e)}'}),
            status=500,
            headers=headers
        )


@https_fn.on_request()
def confirm_material_upload(req: https_fn.Request) -> https_fn.Response:
    """
    Confirm successful upload and save material metadata to Firestore
    Called after client successfully uploads file to B2
    
    Request body:
    {
        "idToken": "firebase_id_token",
        "title": "Material Title",
        "description": "Optional description",
        "filePath": "materials/user123/file.pdf",
        "fileName": "file.pdf",
        "fileSize": 1024000,
        "contentType": "application/pdf",
        "lectureId": "lecture123" (optional, for doctor mode),
        "subjectId": "subject123" (optional, for assistant mode),
        "assistantId": "assistant123" (optional, for assistant mode)
    }
    
    Response:
    {
        "success": true,
        "materialId": "generated_material_id"
    }
    """
    # Handle CORS
    cors_response = _handle_cors_preflight(req)
    if cors_response:
        return cors_response
    
    headers = _get_cors_headers()
    
    try:
        # Only allow POST requests
        if req.method != 'POST':
            return https_fn.Response(
                json.dumps({'error': 'Method not allowed'}),
                status=405,
                headers=headers
            )
        
        # Parse request data
        data = req.get_json()
        if not data:
            return https_fn.Response(
                json.dumps({'error': 'No data provided'}),
                status=400,
                headers=headers
            )
        
        # Verify Firebase token
        id_token = data.get('idToken')
        if not id_token:
            return https_fn.Response(
                json.dumps({'error': 'idToken is required'}),
                status=400,
                headers=headers
            )
        
        success, user_info, error_msg = _verify_firebase_token(id_token)
        if not success:
            return https_fn.Response(
                json.dumps({'error': error_msg}),
                status=401,
                headers=headers
            )
        
        user_id = user_info.get('uid')
        
        # Get required fields
        title = data.get('title')
        file_path = data.get('filePath')
        file_name = data.get('fileName')
        file_size = data.get('fileSize')
        content_type = data.get('contentType')
        
        if not all([title, file_path, file_name, file_size, content_type]):
            return https_fn.Response(
                json.dumps({
                    'error': 'title, filePath, fileName, fileSize, and contentType are required'
                }),
                status=400,
                headers=headers
            )
        
        # Optional fields
        description = data.get('description', '')
        lecture_id = data.get('lectureId')
        subject_id = data.get('subjectId')
        assistant_id = data.get('assistantId')
        
        # Initialize Backblaze service and verify file exists
        b2_service = get_b2_service()
        file_info = b2_service.get_file_info(file_path)
        
        if not file_info:
            return https_fn.Response(
                json.dumps({'error': 'File not found in storage'}),
                status=404,
                headers=headers
            )
        
        # Generate download URL (24-hour expiry)
        download_url = b2_service.generate_download_url(file_path)
        
        # Create material metadata
        db = firestore.client()
        material_data = {
            'title': title,
            'description': description,
            'url': download_url,  # Store initial download URL
            'filePath': file_path,  # Store B2 file path for regenerating URLs
            'fileName': file_name,
            'fileSize': file_size,
            'contentType': content_type,
            'isUploadedFile': True,  # Flag to distinguish from external links
            'uploadedBy': user_id,
            'uploadedAt': firestore.SERVER_TIMESTAMP,
            'createdAt': datetime.now().isoformat(),  # Add createdAt field for Flutter
            'type': _determine_material_type(content_type),
            'averageRating': 0.0,
            'totalRatings': 0,
            'ratings': {}
        }
        
        # Add to appropriate collection
        if lecture_id:
            # Doctor mode: add to lecture's materials subcollection
            material_ref = db.collection('lectures').document(lecture_id)\
                             .collection('materials').document()
            material_data['lectureId'] = lecture_id
            print(f"DEBUG CONFIRM: Saving to lectures/{lecture_id}/materials/{material_ref.id}")
        elif subject_id and assistant_id:
            # Assistant mode: add to subject-assistant materials
            material_ref = db.collection('subjects').document(subject_id)\
                             .collection('assistants').document(assistant_id)\
                             .collection('materials').document()
            material_data['subjectId'] = subject_id
            material_data['assistantId'] = assistant_id
            print(f"DEBUG CONFIRM: Saving to subjects/{subject_id}/assistants/{assistant_id}/materials/{material_ref.id}")
        else:
            return https_fn.Response(
                json.dumps({
                    'error': 'Either lectureId OR (subjectId + assistantId) is required'
                }),
                status=400,
                headers=headers
            )
        
        # Save to Firestore
        print(f"DEBUG CONFIRM: Material data: {material_data}")
        material_ref.set(material_data)
        print(f"DEBUG CONFIRM: Material saved successfully with ID: {material_ref.id}")
        
        return https_fn.Response(
            json.dumps({
                'success': True,
                'materialId': material_ref.id,
                'downloadUrl': download_url
            }),
            status=200,
            headers=headers
        )
        
    except Exception as e:
        return https_fn.Response(
            json.dumps({'error': f'Internal server error: {str(e)}'}),
            status=500,
            headers=headers
        )


def _determine_material_type(content_type: str) -> str:
    """Determine MaterialType from MIME type"""
    if 'pdf' in content_type.lower():
        return 'pdf'
    elif 'image' in content_type.lower():
        return 'image'
    elif 'presentation' in content_type.lower() or 'powerpoint' in content_type.lower():
        return 'document'
    elif 'word' in content_type.lower() or 'document' in content_type.lower():
        return 'document'
    else:
        return 'document'


@https_fn.on_request()
def refresh_download_url(req: https_fn.Request) -> https_fn.Response:
    """
    Refresh/regenerate download URL for an uploaded material
    Download URLs expire after 24 hours, this endpoint generates a fresh one
    
    Request body:
    {
        "idToken": "firebase_id_token",
        "filePath": "materials/user123/file.pdf"
    }
    
    Response:
    {
        "success": true,
        "downloadUrl": "https://..."
    }
    """
    # Handle CORS
    cors_response = _handle_cors_preflight(req)
    if cors_response:
        return cors_response
    
    headers = _get_cors_headers()
    
    try:
        # Only allow POST requests
        if req.method != 'POST':
            return https_fn.Response(
                json.dumps({'error': 'Method not allowed'}),
                status=405,
                headers=headers
            )
        
        # Parse request data
        data = req.get_json()
        if not data:
            return https_fn.Response(
                json.dumps({'error': 'No data provided'}),
                status=400,
                headers=headers
            )
        
        # Verify Firebase token (any authenticated user can download)
        id_token = data.get('idToken')
        if not id_token:
            return https_fn.Response(
                json.dumps({'error': 'idToken is required'}),
                status=400,
                headers=headers
            )
        
        success, user_info, error_msg = _verify_firebase_token(id_token)
        if not success:
            return https_fn.Response(
                json.dumps({'error': error_msg}),
                status=401,
                headers=headers
            )
        
        # Get file path
        file_path = data.get('filePath')
        if not file_path:
            return https_fn.Response(
                json.dumps({'error': 'filePath is required'}),
                status=400,
                headers=headers
            )
        
        # Initialize Backblaze service
        b2_service = get_b2_service()
        
        # Generate new download URL
        download_url = b2_service.generate_download_url(file_path)
        
        return https_fn.Response(
            json.dumps({
                'success': True,
                'downloadUrl': download_url
            }),
            status=200,
            headers=headers
        )
        
    except ValueError as e:
        return https_fn.Response(
            json.dumps({'error': str(e)}),
            status=404,
            headers=headers
        )
    except Exception as e:
        return https_fn.Response(
            json.dumps({'error': f'Internal server error: {str(e)}'}),
            status=500,
            headers=headers
        )


@https_fn.on_request()
def delete_material_file(req: https_fn.Request) -> https_fn.Response:
    """
    Delete a material file from Backblaze B2 and its metadata from Firestore
    
    Request body:
    {
        "idToken": "firebase_id_token",
        "filePath": "materials/user123/file.pdf",
        "materialId": "material123",
        "lectureId": "lecture123" (optional, for doctor mode),
        "subjectId": "subject123" (optional, for assistant mode),
        "assistantId": "assistant123" (optional, for assistant mode)
    }
    
    Response:
    {
        "success": true,
        "message": "File deleted successfully"
    }
    """
    # Handle CORS
    cors_response = _handle_cors_preflight(req)
    if cors_response:
        return cors_response
    
    headers = _get_cors_headers()
    
    try:
        # Only allow POST requests
        if req.method != 'POST':
            return https_fn.Response(
                json.dumps({'error': 'Method not allowed'}),
                status=405,
                headers=headers
            )
        
        # Parse request data
        data = req.get_json()
        if not data:
            return https_fn.Response(
                json.dumps({'error': 'No data provided'}),
                status=400,
                headers=headers
            )
        
        # Verify Firebase token
        id_token = data.get('idToken')
        if not id_token:
            return https_fn.Response(
                json.dumps({'error': 'idToken is required'}),
                status=400,
                headers=headers
            )
        
        success, user_info, error_msg = _verify_firebase_token(id_token)
        if not success:
            return https_fn.Response(
                json.dumps({'error': error_msg}),
                status=401,
                headers=headers
            )
        
        user_id = user_info.get('uid')
        
        # Check permissions (only Doctor, Assistant, or Admin can delete)
        has_permission, error_msg = _verify_user_permissions(
            user_id,
            ['Doctor', 'Assistant', 'Admin', 'Super Admin']
        )
        if not has_permission:
            return https_fn.Response(
                json.dumps({'error': error_msg}),
                status=403,
                headers=headers
            )
        
        # Get required fields
        file_path = data.get('filePath')
        material_id = data.get('materialId')
        
        if not file_path or not material_id:
            return https_fn.Response(
                json.dumps({'error': 'filePath and materialId are required'}),
                status=400,
                headers=headers
            )
        
        # Get context (lecture or subject-assistant)
        lecture_id = data.get('lectureId')
        subject_id = data.get('subjectId')
        assistant_id = data.get('assistantId')
        
        # Delete from Firestore
        db = firestore.client()
        
        if lecture_id:
            # Doctor mode
            material_ref = db.collection('lectures').document(lecture_id)\
                             .collection('materials').document(material_id)
        elif subject_id and assistant_id:
            # Assistant mode
            material_ref = db.collection('subjects').document(subject_id)\
                             .collection('assistants').document(assistant_id)\
                             .collection('materials').document(material_id)
        else:
            return https_fn.Response(
                json.dumps({
                    'error': 'Either lectureId OR (subjectId + assistantId) is required'
                }),
                status=400,
                headers=headers
            )
        
        # Verify material exists and user has permission to delete
        material_doc = material_ref.get()
        if not material_doc.exists:
            return https_fn.Response(
                json.dumps({'error': 'Material not found'}),
                status=404,
                headers=headers
            )
        
        material_data = material_doc.to_dict()
        uploaded_by = material_data.get('uploadedBy', '')
        
        # Only the uploader or admin can delete
        if uploaded_by != user_id:
            # Check if user is admin
            has_admin, _ = _verify_user_permissions(user_id, ['Admin', 'Super Admin'])
            if not has_admin:
                return https_fn.Response(
                    json.dumps({'error': 'You can only delete materials you uploaded'}),
                    status=403,
                    headers=headers
                )
        
        # Delete from Backblaze B2
        b2_service = get_b2_service()
        delete_success, delete_error = b2_service.delete_file(file_path)
        
        if not delete_success:
            # Log error but continue with Firestore deletion
            print(f"Warning: Failed to delete file from B2: {delete_error}")
        
        # Delete from Firestore
        material_ref.delete()
        
        return https_fn.Response(
            json.dumps({
                'success': True,
                'message': 'Material deleted successfully'
            }),
            status=200,
            headers=headers
        )
        
    except Exception as e:
        return https_fn.Response(
            json.dumps({'error': f'Internal server error: {str(e)}'}),
            status=500,
            headers=headers
        )