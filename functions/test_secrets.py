"""
Quick test script to verify secrets are loaded correctly in production
"""
import os
import sys

# Add the functions directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from config import BackblazeConfig

def main():
    print("=" * 60)
    print("TESTING BACKBLAZE CONFIGURATION")
    print("=" * 60)
    
    # Test configuration
    is_valid, error = BackblazeConfig.validate_config()
    
    print(f"\nConfiguration Valid: {is_valid}")
    if not is_valid:
        print(f"Error: {error}")
    
    # Get credentials
    key_id = BackblazeConfig.get_key_id()
    app_key = BackblazeConfig.get_application_key()
    
    print(f"\nKey ID: {key_id if key_id else 'NOT FOUND'}")
    print(f"App Key: {app_key[:10] + '...' if app_key else 'NOT FOUND'}")
    
    if key_id and app_key:
        print(f"\nKey ID length: {len(key_id)} (expected: 25 or 31)")
        print(f"App Key length: {len(app_key)} (expected: 31 for v3)")
        
        # Test authorization
        print("\n" + "=" * 60)
        print("TESTING AUTHORIZATION")
        print("=" * 60)
        
        try:
            from backblaze_service import BackblazeService
            
            service = BackblazeService()
            success, error = service.initialize()
            
            if success:
                print("✅ Authorization successful!")
                print(f"Account ID: {service.api.account_info.get_account_id()}")
                print(f"Bucket: {service.bucket.name}")
            else:
                print(f"❌ Authorization failed: {error}")
        except Exception as e:
            print(f"❌ Exception during authorization: {e}")
            import traceback
            traceback.print_exc()

if __name__ == "__main__":
    main()

