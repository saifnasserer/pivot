#!/usr/bin/env python3
"""
Test script for the notification function
Run this to test the function locally before deployment
"""

import requests
import json
import time

def test_notification_function():
    # Replace with your actual FCM token from your Flutter app
    test_token = "961104767168"
    
    # Test data
    test_data = {
        "token": test_token,
        "title": "Test Notification",
        "body": "This is a test notification from your Firebase Function!"
    }
    
    # Local testing URL (when running with functions-framework)
    url = "http://localhost:8080"
    
    print("Testing notification function...")
    print(f"URL: {url}")
    print(f"Data: {json.dumps(test_data, indent=2)}")
    
    try:
        print("Sending request...")
        response = requests.post(url, json=test_data, timeout=10)
        print(f"Status Code: {response.status_code}")
        print(f"Response Headers: {dict(response.headers)}")
        print(f"Response Body: {response.text}")
        
        if response.status_code == 200:
            try:
                response_data = response.json()
                print("✅ Function test successful!")
                print(f"Response: {json.dumps(response_data, indent=2)}")
            except json.JSONDecodeError:
                print("⚠️  Function returned 200 but response is not valid JSON")
                print(f"Raw response: {response.text}")
        else:
            print("❌ Function test failed!")
            try:
                error_data = response.json()
                print(f"Error: {json.dumps(error_data, indent=2)}")
            except json.JSONDecodeError:
                print(f"Error: {response.text}")
            
    except requests.exceptions.ConnectionError:
        print("❌ Could not connect to function. Make sure to run:")
        print("   cd functions && functions-framework --target=send_notification --port=8080")
    except requests.exceptions.Timeout:
        print("❌ Request timed out. The function might be taking too long to respond.")
    except Exception as e:
        print(f"❌ Error: {e}")
        print(f"Error type: {type(e)}")

if __name__ == "__main__":
    test_notification_function() 