import requests
import json

def test_notification_function():
    url = "https://us-central1-pivot-28563.cloudfunctions.net/send_notification"
    
    # Test data
    test_data = {
        "token": "test_token",
        "title": "Test Notification",
        "body": "This is a test notification"
    }
    
    try:
        # Test with GET (should return method not allowed)
        print("Testing GET request...")
        response = requests.get(url)
        print(f"GET Status: {response.status_code}")
        print(f"GET Response: {response.text[:200]}...")
        
        # Test with POST
        print("\nTesting POST request...")
        response = requests.post(
            url,
            headers={'Content-Type': 'application/json'},
            data=json.dumps(test_data)
        )
        print(f"POST Status: {response.status_code}")
        print(f"POST Response: {response.text}")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_notification_function() 