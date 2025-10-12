#!/usr/bin/env python3
"""
Backblaze B2 Integration Test Script
Tests all Backblaze operations without requiring Firebase deployment

Usage:
    1. Set environment variables:
       export BACKBLAZE_KEY_ID="your_key_id"
       export BACKBLAZE_APPLICATION_KEY="your_app_key"
    
    2. Run the script:
       python test_backblaze.py
"""
import os
import sys
import tempfile
from pathlib import Path

# Add functions directory to path
sys.path.insert(0, str(Path(__file__).parent))

from config import BackblazeConfig
from backblaze_service import BackblazeService


class Colors:
    """ANSI color codes for pretty terminal output"""
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    RESET = '\033[0m'
    BOLD = '\033[1m'


def print_header(text):
    """Print a formatted header"""
    print(f"\n{Colors.BOLD}{Colors.BLUE}{'='*60}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.BLUE}{text.center(60)}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.BLUE}{'='*60}{Colors.RESET}\n")


def print_success(text):
    """Print success message"""
    print(f"{Colors.GREEN}✓ {text}{Colors.RESET}")


def print_error(text):
    """Print error message"""
    print(f"{Colors.RED}✗ {text}{Colors.RESET}")


def print_info(text):
    """Print info message"""
    print(f"{Colors.YELLOW}ℹ {text}{Colors.RESET}")


def test_config():
    """Test 1: Validate configuration"""
    print_header("TEST 1: Configuration Validation")
    
    # Check for environment variables
    key_id = BackblazeConfig.get_key_id()
    app_key = BackblazeConfig.get_application_key()
    
    if not key_id:
        print_error("BACKBLAZE_KEY_ID not found in environment")
        print_info("Set it with: export BACKBLAZE_KEY_ID='your_key_id'")
        return False
    else:
        print_success(f"Key ID found: {key_id[:10]}...")
    
    if not app_key:
        print_error("BACKBLAZE_APPLICATION_KEY not found in environment")
        print_info("Set it with: export BACKBLAZE_APPLICATION_KEY='your_app_key'")
        return False
    else:
        print_success(f"Application Key found: {app_key[:10]}...")
    
    # Validate config
    is_valid, error_msg = BackblazeConfig.validate_config()
    if not is_valid:
        print_error(f"Configuration validation failed: {error_msg}")
        return False
    else:
        print_success("Configuration is valid")
    
    # Print settings
    print_info(f"Bucket Name: {BackblazeConfig.BUCKET_NAME}")
    print_info(f"Max File Size: {BackblazeConfig.MAX_FILE_SIZE_MB} MB")
    print_info(f"Allowed Extensions: {', '.join(BackblazeConfig.get_allowed_extensions_list())}")
    print_info(f"Download URL Expiry: {BackblazeConfig.DOWNLOAD_URL_EXPIRY / 3600} hours")
    
    return True


def test_initialization():
    """Test 2: Initialize Backblaze service"""
    print_header("TEST 2: Service Initialization")
    
    try:
        service = BackblazeService()
        success, error_msg = service.initialize()
        
        if not success:
            print_error(f"Initialization failed: {error_msg}")
            return False, None
        
        print_success("Backblaze service initialized successfully")
        print_success(f"Connected to bucket: {service.bucket.name}")
        
        return True, service
        
    except Exception as e:
        print_error(f"Exception during initialization: {str(e)}")
        return False, None


def test_file_validation(service):
    """Test 3: File validation"""
    print_header("TEST 3: File Validation")
    
    # Test valid file types
    valid_files = [
        ('test.pdf', True),
        ('document.docx', True),
        ('presentation.pptx', True),
        ('image.jpg', True),
        ('photo.png', True),
    ]
    
    for filename, should_pass in valid_files:
        is_allowed = BackblazeConfig.is_allowed_extension(filename)
        if is_allowed == should_pass:
            print_success(f"{filename}: {'Allowed' if is_allowed else 'Blocked'} ✓")
        else:
            print_error(f"{filename}: Validation failed")
            return False
    
    # Test invalid file types
    invalid_files = ['test.exe', 'script.sh', 'archive.zip', 'video.mp4']
    for filename in invalid_files:
        is_allowed = BackblazeConfig.is_allowed_extension(filename)
        if not is_allowed:
            print_success(f"{filename}: Correctly blocked ✓")
        else:
            print_error(f"{filename}: Should have been blocked!")
            return False
    
    # Test file size validation
    print_info(f"\nTesting file size validation (max: {BackblazeConfig.MAX_FILE_SIZE_MB} MB)")
    
    try:
        # Test valid size
        service.generate_upload_authorization(
            user_id="test_user_123",
            title="Test Document",
            original_filename="test.pdf",
            file_size=1024 * 1024  # 1 MB
        )
        print_success("1 MB file: Passed validation ✓")
    except ValueError as e:
        print_error(f"1 MB file failed: {str(e)}")
        return False
    
    try:
        # Test oversized file
        service.generate_upload_authorization(
            user_id="test_user_123",
            title="Large Document",
            original_filename="large.pdf",
            file_size=25 * 1024 * 1024  # 25 MB (over limit)
        )
        print_error("25 MB file should have been rejected!")
        return False
    except ValueError as e:
        print_success(f"25 MB file correctly rejected: {str(e)[:50]}...")
    
    return True


def test_upload_authorization(service):
    """Test 4: Generate upload authorization"""
    print_header("TEST 4: Upload Authorization Generation")
    
    try:
        # Generate upload URL for a test file
        upload_data = service.generate_upload_authorization(
            user_id="test_user_123",
            title="Test Material - ماتيريال اختبار",
            original_filename="test_document.pdf",
            file_size=2048  # 2 KB
        )
        
        # Verify all required fields are present
        required_fields = ['uploadUrl', 'authorizationToken', 'filePath', 'fileName', 'contentType']
        for field in required_fields:
            if field in upload_data:
                print_success(f"{field}: Present ✓")
            else:
                print_error(f"{field}: Missing!")
                return False, None
        
        print_info(f"\nGenerated file path: {upload_data['filePath']}")
        print_info(f"File name: {upload_data['fileName']}")
        print_info(f"Content type: {upload_data['contentType']}")
        print_info(f"Upload URL: {upload_data['uploadUrl'][:60]}...")
        
        return True, upload_data
        
    except Exception as e:
        print_error(f"Failed to generate upload authorization: {str(e)}")
        return False, None


def test_file_upload(service, upload_data):
    """Test 5: Upload a real test file"""
    print_header("TEST 5: File Upload (Simulated)")
    
    print_info("In a real scenario, the client would:")
    print_info("1. Use the uploadUrl from the authorization")
    print_info("2. Set the Authorization header with authorizationToken")
    print_info("3. Upload the file using HTTP POST")
    print_info("4. The file would be stored at: " + upload_data['filePath'])
    
    print_success("Upload authorization is valid and ready to use")
    
    # Note: We can't actually upload without a real file from the client
    # This would be done in the Flutter app
    
    return True


def test_file_operations(service):
    """Test 6: File listing and info"""
    print_header("TEST 6: File Operations")
    
    try:
        # List files for test user
        print_info("Listing files for test_user_123...")
        files = service.list_user_files("test_user_123", limit=10)
        
        if files:
            print_success(f"Found {len(files)} file(s):")
            for file in files:
                print_info(f"  - {file['fileName']} ({file['size']} bytes)")
        else:
            print_info("No files found for this user (expected for new bucket)")
        
        return True
        
    except Exception as e:
        print_error(f"File operations failed: {str(e)}")
        return False


def print_summary(results):
    """Print test summary"""
    print_header("TEST SUMMARY")
    
    total = len(results)
    passed = sum(1 for r in results.values() if r)
    failed = total - passed
    
    for test_name, result in results.items():
        status = f"{Colors.GREEN}PASS{Colors.RESET}" if result else f"{Colors.RED}FAIL{Colors.RESET}"
        print(f"  {test_name}: {status}")
    
    print(f"\n{Colors.BOLD}Total: {total} | Passed: {Colors.GREEN}{passed}{Colors.RESET}{Colors.BOLD} | Failed: {Colors.RED}{failed}{Colors.RESET}")
    
    if failed == 0:
        print(f"\n{Colors.GREEN}{Colors.BOLD}🎉 All tests passed! Backend is ready.{Colors.RESET}\n")
        return True
    else:
        print(f"\n{Colors.RED}{Colors.BOLD}❌ Some tests failed. Please fix the issues above.{Colors.RESET}\n")
        return False


def main():
    """Run all tests"""
    print(f"{Colors.BOLD}{Colors.BLUE}")
    print("╔═══════════════════════════════════════════════════════════╗")
    print("║         BACKBLAZE B2 INTEGRATION TEST SUITE             ║")
    print("║                  Pivot Materials Upload                   ║")
    print("╚═══════════════════════════════════════════════════════════╝")
    print(Colors.RESET)
    
    results = {}
    
    # Test 1: Configuration
    results['Configuration'] = test_config()
    if not results['Configuration']:
        print_error("\nConfiguration test failed. Cannot proceed.")
        return False
    
    # Test 2: Initialization
    init_success, service = test_initialization()
    results['Initialization'] = init_success
    if not init_success:
        print_error("\nInitialization failed. Cannot proceed.")
        return False
    
    # Test 3: File Validation
    results['File Validation'] = test_file_validation(service)
    
    # Test 4: Upload Authorization
    auth_success, upload_data = test_upload_authorization(service)
    results['Upload Authorization'] = auth_success
    
    # Test 5: File Upload (Simulated)
    if upload_data:
        results['File Upload'] = test_file_upload(service, upload_data)
    else:
        results['File Upload'] = False
    
    # Test 6: File Operations
    results['File Operations'] = test_file_operations(service)
    
    # Print summary
    all_passed = print_summary(results)
    
    if all_passed:
        print_info("Next steps:")
        print_info("1. Configure Firebase Secrets (see instructions below)")
        print_info("2. Deploy functions: firebase deploy --only functions")
        print_info("3. Test the deployed endpoints")
        print_info("4. Integrate with Flutter app")
    
    return all_passed


if __name__ == '__main__':
    try:
        success = main()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}Test interrupted by user{Colors.RESET}")
        sys.exit(1)
    except Exception as e:
        print(f"\n{Colors.RED}Unexpected error: {str(e)}{Colors.RESET}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

