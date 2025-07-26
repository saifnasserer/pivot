import functions_framework
import firebase_admin
from firebase_admin import credentials, messaging, exceptions
from flask import Request, jsonify
import json

# تحميل بيانات الحساب الخدمي (Service Account)
try:
    # Check if Firebase app is already initialized
    firebase_admin.get_app()
except ValueError:
    # Initialize Firebase only if not already initialized
    cred = credentials.Certificate("pivot-28563-firebase-adminsdk-fbsvc-12baa1b7d9.json")
firebase_admin.initialize_app(cred)

@functions_framework.http
def send_notification(request: Request):
    # Handle CORS
    if request.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '3600'
        }
        return ('', 204, headers)
    
    # Set CORS headers for the main request
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST',
        'Access-Control-Allow-Headers': 'Content-Type'
    }
    
    try:
        # Only allow POST requests
        if request.method != 'POST':
            return (jsonify({'error': 'Method not allowed'}), 405, headers)
        
    data = request.get_json()

        if not data:
            return (jsonify({'error': 'No data provided'}), 400, headers)
        
    token = data.get("token")
    title = data.get("title", "No Title")
    body = data.get("body", "No Body")

        if not token:
            return (jsonify({'error': 'Token is required'}), 400, headers)
        
    message = messaging.Message(
        notification=messaging.Notification(title=title, body=body),
        token=token,
    )

    response = messaging.send(message)
        return (jsonify({
            'success': True, 
            'message_id': response,
            'message': 'Notification sent successfully'
        }), 200, headers)
        
    except exceptions.InvalidArgumentError as e:
        return (jsonify({'error': f'Invalid argument, likely an invalid token: {str(e)}'}), 400, headers)
    except messaging.UnregisteredError:
        return (jsonify({'error': 'Invalid or unregistered token'}), 400, headers)
    except messaging.QuotaExceededError:
        return (jsonify({'error': 'Quota exceeded'}), 429, headers)
    except messaging.SenderIdMismatchError:
        return (jsonify({'error': 'Sender ID mismatch'}), 400, headers)
    except messaging.ThirdPartyAuthError:
        return (jsonify({'error': 'Third party auth error'}), 401, headers)
    except Exception as e:
        return (jsonify({'error': f'Internal server error: {str(e)}'}), 500, headers)
