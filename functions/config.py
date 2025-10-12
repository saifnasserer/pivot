"""
Configuration management for Backblaze B2 storage.
Uses Firebase Secrets Manager for production and environment variables for local testing.
"""
import os
from typing import Optional

class BackblazeConfig:
    """Backblaze B2 configuration settings"""
    
    # File upload constraints
    MAX_FILE_SIZE_MB = 20
    MAX_FILE_SIZE_BYTES = MAX_FILE_SIZE_MB * 1024 * 1024  # 20 MB in bytes
    
    # Allowed MIME types and extensions
    ALLOWED_EXTENSIONS = {
        '.pdf': 'application/pdf',
        '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        '.pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.png': 'image/png',
    }
    
    # Download URL expiration (in seconds)
    DOWNLOAD_URL_EXPIRY = 86400  # 24 hours
    
    # Bucket configuration
    BUCKET_NAME = 'pivot-materials'
    
    @staticmethod
    def get_key_id() -> Optional[str]:
        """Get Backblaze Key ID from environment or Firebase Secrets"""
        # HARDCODED FOR TESTING - DO NOT USE IN PRODUCTION
        return "003a81351b57fa10000000003"
    
    @staticmethod
    def get_application_key() -> Optional[str]:
        """Get Backblaze Application Key from environment or Firebase Secrets"""
        # HARDCODED FOR TESTING - DO NOT USE IN PRODUCTION
        return "K0034qqaTlEskzUiGU7Wa8pwqnplhw0"
    
    @staticmethod
    def validate_config() -> tuple[bool, str]:
        """
        Validate that all required configuration is present
        Returns: (is_valid, error_message)
        """
        key_id = BackblazeConfig.get_key_id()
        app_key = BackblazeConfig.get_application_key()
        
        if not key_id:
            return False, "B2_KEY_ID not configured in Firebase Secrets or environment"
        
        if not app_key:
            return False, "B2_APPLICATION_KEY not configured in Firebase Secrets or environment"
        
        return True, ""
    
    @staticmethod
    def get_allowed_extensions_list() -> list[str]:
        """Get list of allowed file extensions"""
        return list(BackblazeConfig.ALLOWED_EXTENSIONS.keys())
    
    @staticmethod
    def is_allowed_extension(filename: str) -> bool:
        """Check if file extension is allowed"""
        ext = os.path.splitext(filename.lower())[1]
        return ext in BackblazeConfig.ALLOWED_EXTENSIONS
    
    @staticmethod
    def get_mime_type(filename: str) -> Optional[str]:
        """Get MIME type for a given filename"""
        ext = os.path.splitext(filename.lower())[1]
        return BackblazeConfig.ALLOWED_EXTENSIONS.get(ext)
    
    @staticmethod
    def format_file_size(size_bytes: int) -> str:
        """Format file size in human-readable format"""
        if size_bytes < 1024:
            return f"{size_bytes} B"
        elif size_bytes < 1024 * 1024:
            return f"{size_bytes / 1024:.2f} KB"
        else:
            return f"{size_bytes / (1024 * 1024):.2f} MB"

