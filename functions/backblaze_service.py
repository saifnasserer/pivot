"""
Backblaze B2 Storage Service
Handles all interactions with Backblaze B2 cloud storage for educational materials.
"""
import os
import uuid
import re
from typing import Optional, Dict, Any
from datetime import datetime, timedelta
from b2sdk.v2 import InMemoryAccountInfo, B2Api
from b2sdk.v2.exception import B2Error, BucketIdNotFound, FileNotPresent
from config import BackblazeConfig


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
        if self._initialized:
            return True, None
        
        try:
            # Validate configuration
            is_valid, error_msg = self.config.validate_config()
            if not is_valid:
                return False, error_msg
            
            # Get credentials
            key_id = self.config.get_key_id()
            app_key = self.config.get_application_key()
            
            # Initialize B2 API
            info = InMemoryAccountInfo()
            self.api = B2Api(info)
            self.api.authorize_account("production", key_id, app_key)
            
            # Get bucket
            self.bucket = self.api.get_bucket_by_name(self.config.BUCKET_NAME)
            
            self._initialized = True
            return True, None
            
        except B2Error as e:
            return False, f"B2 API error: {str(e)}"
        except Exception as e:
            return False, f"Initialization error: {str(e)}"
    
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
        # B2 SDK v2: We use the services layer to get upload URL
        # The bucket uses an upload manager internally
        
        import requests
        
        # Get account authorization token
        auth_token = self.api.account_info.get_account_auth_token()
        api_url = self.api.account_info.get_api_url()
        
        # Call b2_get_upload_url directly via REST API
        response = requests.post(
            f'{api_url}/b2api/v2/b2_get_upload_url',
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
        Generate a temporary download URL for a file
        
        Args:
            file_path: Path to file in bucket (e.g., "materials/user123/file.pdf")
            expires_in_seconds: URL expiration time (default: 24 hours)
            
        Returns:
            Signed download URL
        """
        if expires_in_seconds is None:
            expires_in_seconds = self.config.DOWNLOAD_URL_EXPIRY
        
        try:
            # Get file info
            file_version = self.bucket.get_file_info_by_name(file_path)
            
            # Generate download authorization
            download_auth = self.api.get_download_authorization(
                bucket_id=self.bucket.id_,
                file_name_prefix=file_path,
                valid_duration_in_seconds=expires_in_seconds
            )
            
            # Construct download URL with authorization
            download_url = self.api.get_download_url_for_file_name(
                bucket_name=self.config.BUCKET_NAME,
                file_name=file_path
            )
            
            # Add authorization token as query parameter
            download_url_with_auth = f"{download_url}?Authorization={download_auth}"
            
            return download_url_with_auth
            
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
    """
    global _backblaze_service
    
    if _backblaze_service is None:
        _backblaze_service = BackblazeService()
        success, error = _backblaze_service.initialize()
        if not success:
            raise Exception(f"Failed to initialize Backblaze service: {error}")
    
    return _backblaze_service

