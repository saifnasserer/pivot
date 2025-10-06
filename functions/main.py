import firebase_functions
from firebase_functions import https_fn
from firebase_admin import initialize_app, messaging, exceptions, firestore, auth
import json

# Initialize Firebase app
initialize_app()

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