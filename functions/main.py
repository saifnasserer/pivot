import firebase_functions
from firebase_functions import https_fn
from firebase_admin import initialize_app, messaging, exceptions
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
        icon = data.get("icon", "ic_launcher")  # Default to app icon
        color = data.get("color", "#000000")    # Default to black
        sound = data.get("sound", "default")    # Default sound

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
