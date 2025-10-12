"""
Backblaze B2 Storage Service
Handles all interactions with Backblaze B2 cloud storage for educational materials.
"""
import os
import uuid
import re
from typing import Optional, Dict, Any
from datetime import datetime, timedelta

# Use v3 API for new Backblaze accounts (31-char keys)
try:
    from b2sdk.v3 import InMemoryAccountInfo, B2Api
    from b2sdk.v3.exception import B2Error, BucketIdNotFound, FileNotPresent
    SDK_VERSION = "v3"
except ImportError:
    # Fallback to v2 for older installations
    from b2sdk.v2 import InMemoryAccountInfo, B2Api
    from b2sdk.v2.exception import B2Error, BucketIdNotFound, FileNotPresent
    SDK_VERSION = "v2"

from config import BackblazeConfig

print(f"Using B2 SDK: {SDK_VERSION}")


class BackblazeService:
    """Service class for Backblaze B2 operations"""
    
    def __init__(self):
        """Initialize Backblaze B2 API client"""
        self.config = BackblazeConfig()
        self.api = None
        self.bucket = None
        self._initialized = False
    
    def initialize(self) -> tuple[bool, Optional[str]]:
        """
        Initialize B2 API connection and get bucket
        Returns: (success, error_message)
        """
        # In serverless environments, we need to check if API is actually authorized
        # not just if the flag is set
        if self._initialized and self.api and self.bucket:
            try:
                # Verify authorization is still valid
                _ = self.api.account_info.get_account_auth_token()
                return True, None
            except Exception as e:
                print(f"DEBUG: Authorization expired or invalid: {e}. Re-initializing...")
                self._initialized = False
        
        try:
            # Validate configuration
            is_valid, error_msg = self.config.validate_config()
            if not is_valid:
                return False, error_msg
            
            # Get credentials
            key_id = self.config.get_key_id()
            app_key = self.config.get_application_key()
            
            # Debug logging
            print(f"DEBUG: Attempting B2 authorization with Key ID: {key_id[:10] if key_id else 'None'}...")
            print(f"DEBUG: App Key present: {bool(app_key)}")
            
            if not key_id or not app_key:
                return False, f"Missing credentials: key_id={bool(key_id)}, app_key={bool(app_key)}"
            
            # Initialize B2 API
            info = InMemoryAccountInfo()
            self.api = B2Api(info)
            
            # Authorize account - v3 API uses simpler authorization
            print(f"DEBUG: Authorizing with key_id={key_id}, app_key length={len(app_key)}")
            
            if SDK_VERSION == "v3":
                # v3 API: No realm parameter needed, it auto-detects from the key
                self.api.authorize_account(
                    application_key_id=key_id,
                    application_key=app_key
                )
            else:
                # v2 API (legacy)
                self.api.authorize_account("production", key_id, app_key)
            
            print(f"DEBUG: Authorization successful. Account ID: {self.api.account_info.get_account_id()}")
            
            # Get bucket
            print(f"DEBUG: Getting bucket: {self.config.BUCKET_NAME}")
            self.bucket = self.api.get_bucket_by_name(self.config.BUCKET_NAME)
            print(f"DEBUG: Bucket found. ID: {self.bucket.id_}, Name: {self.bucket.name}")
            
            self._initialized = True
            return True, None
            
        except B2Error as e:
            error_msg = f"B2 API error: {str(e)}"
            print(f"ERROR: {error_msg}")
            return False, error_msg
        except Exception as e:
            error_msg = f"Initialization error: {str(e)}"
            print(f"ERROR: {error_msg}")
            import traceback
            traceback.print_exc()
            return False, error_msg
    
    def _sanitize_filename(self, filename: str) -> str:
        """
        Sanitize filename to be URL-safe and user-friendly
        Removes special characters but keeps Arabic characters
        """
        # Get name and extension
        name, ext = os.path.splitext(filename)
        
        # Remove or replace problematic characters
        # Keep alphanumeric, Arabic, spaces, hyphens, underscores
        name = re.sub(r'[^\w\s\-\u0600-\u06FF]', '', name)
        name = re.sub(r'\s+', '_', name)  # Replace spaces with underscores
        name = name.strip('_')
        
        # Limit length
        if len(name) > 100:
            name = name[:100]
        
        return f"{name}{ext.lower()}"
    
    def _generate_file_path(self, user_id: str, title: str, original_filename: str) -> str:
        """
        Generate unique file path with user-friendly naming
        Format: materials/{user_id}/{sanitized_title}_{uuid}.{ext}
        """
        # Sanitize the title for use in filename
        safe_title = self._sanitize_filename(title)
        if not safe_title or safe_title == '.':
            safe_title = "material"
        
        # Get extension from original filename
        _, ext = os.path.splitext(original_filename)
        
        # Generate unique ID
        unique_id = str(uuid.uuid4())[:8]
        
        # Remove extension from safe_title if it has one
        safe_title_no_ext, _ = os.path.splitext(safe_title)
        
        # Construct filename
        filename = f"{safe_title_no_ext}_{unique_id}{ext.lower()}"
        
        # Full path in bucket
        file_path = f"materials/{user_id}/{filename}"
        
        return file_path
    
    def generate_upload_authorization(
        self,
        user_id: str,
        title: str,
        original_filename: str,
        file_size: int
    ) -> Dict[str, Any]:
        """
        Generate upload authorization for client-side direct upload
        
        Args:
            user_id: ID of the user uploading the file
            title: Title of the material (used in filename)
            original_filename: Original filename from client
            file_size: Size of file in bytes
            
        Returns:
            Dictionary with upload URL, authorization token, and file info
        """
        # Validate file size
        if file_size > self.config.MAX_FILE_SIZE_BYTES:
            raise ValueError(
                f"File size {self.config.format_file_size(file_size)} exceeds "
                f"maximum allowed size of {self.config.MAX_FILE_SIZE_MB} MB"
            )
        
        # Validate file extension
        if not self.config.is_allowed_extension(original_filename):
            allowed = ', '.join(self.config.get_allowed_extensions_list())
            raise ValueError(f"File type not allowed. Allowed types: {allowed}")
        
        # Generate file path
        file_path = self._generate_file_path(user_id, title, original_filename)
        
        # Get upload URL and authorization token from B2
        # Use B2 SDK v3 API endpoint for new credentials
        
        import requests
        
        # Get account authorization token
        auth_token = self.api.account_info.get_account_auth_token()
        api_url = self.api.account_info.get_api_url()
        
        # Determine API version based on SDK version
        api_version = "v3" if SDK_VERSION == "v3" else "v2"
        
        # Call b2_get_upload_url with correct API version
        response = requests.post(
            f'{api_url}/b2api/{api_version}/b2_get_upload_url',
            headers={'Authorization': auth_token},
            json={'bucketId': self.bucket.id_}
        )
        response.raise_for_status()
        upload_data = response.json()
        
        # Get MIME type
        mime_type = self.config.get_mime_type(original_filename)
        
        return {
            'uploadUrl': upload_data['uploadUrl'],
            'authorizationToken': upload_data['authorizationToken'],
            'filePath': file_path,
            'fileName': os.path.basename(file_path),
            'contentType': mime_type,
            'fileSize': file_size,
            'bucketId': self.bucket.id_,
        }
    
    def generate_download_url(self, file_path: str, expires_in_seconds: Optional[int] = None) -> str:
        """
        Generate a download URL for a file
        For private buckets, returns a simple URL that requires authentication
        
        Args:
            file_path: Path to file in bucket (e.g., "materials/user123/file.pdf")
            expires_in_seconds: URL expiration time (not used for simple URLs)
            
        Returns:
            Download URL
        """
        try:
            # Get file info to verify it exists
            file_version = self.bucket.get_file_info_by_name(file_path)
            
            # Get the base download URL
            # For private buckets, this will require Authorization header when accessing
            download_url = self.bucket.get_download_url(file_path)
            
            return download_url
            
        except FileNotPresent:
            raise ValueError(f"File not found: {file_path}")
        except B2Error as e:
            raise Exception(f"Error generating download URL: {str(e)}")
    
    def delete_file(self, file_path: str) -> tuple[bool, Optional[str]]:
        """
        Delete a file from Backblaze B2
        
        Args:
            file_path: Path to file in bucket
            
        Returns:
            (success, error_message)
        """
        try:
            # Get file info first
            file_version = self.bucket.get_file_info_by_name(file_path)
            
            # Delete the file
            self.api.delete_file_version(file_version.id_, file_path)
            
            return True, None
            
        except FileNotPresent:
            return False, f"File not found: {file_path}"
        except B2Error as e:
            return False, f"B2 API error: {str(e)}"
        except Exception as e:
            return False, f"Error deleting file: {str(e)}"
    
    def list_user_files(self, user_id: str, limit: int = 100) -> list[Dict[str, Any]]:
        """
        List all files for a specific user
        
        Args:
            user_id: User ID to filter files
            limit: Maximum number of files to return
            
        Returns:
            List of file information dictionaries
        """
        try:
            prefix = f"materials/{user_id}/"
            files = []
            
            for file_version, _ in self.bucket.ls(prefix, latest_only=True, recursive=True):
                files.append({
                    'fileName': file_version.file_name,
                    'fileId': file_version.id_,
                    'size': file_version.size,
                    'uploadTimestamp': file_version.upload_timestamp,
                    'contentType': file_version.content_type,
                })
                
                if len(files) >= limit:
                    break
            
            return files
            
        except B2Error as e:
            raise Exception(f"Error listing files: {str(e)}")
    
    def get_file_info(self, file_path: str) -> Optional[Dict[str, Any]]:
        """
        Get information about a specific file
        
        Args:
            file_path: Path to file in bucket
            
        Returns:
            File information dictionary or None if not found
        """
        try:
            file_version = self.bucket.get_file_info_by_name(file_path)
            
            return {
                'fileName': file_version.file_name,
                'fileId': file_version.id_,
                'size': file_version.size,
                'uploadTimestamp': file_version.upload_timestamp,
                'contentType': file_version.content_type,
            }
            
        except FileNotPresent:
            return None
        except B2Error as e:
            raise Exception(f"Error getting file info: {str(e)}")


# Global instance (initialized on first use)
_backblaze_service: Optional[BackblazeService] = None


def get_backblaze_service() -> BackblazeService:
    """
    Get or create the global Backblaze service instance
    This ensures we reuse the same authenticated connection
    Always calls initialize() to handle serverless cold starts
    """
    global _backblaze_service
    
    if _backblaze_service is None:
        _backblaze_service = BackblazeService()
    
    # Always try to initialize (it will check if already initialized)
    success, error = _backblaze_service.initialize()
    if not success:
        raise Exception(f"Failed to initialize Backblaze service: {error}")
    
    return _backblaze_service

