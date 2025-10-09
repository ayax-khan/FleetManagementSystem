"""
Fleet Management System - Configuration Settings
"""

import os
from pathlib import Path
from typing import Optional
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    """Application settings"""
    
    # API Configuration
    API_V1_PREFIX: str = "/api/v1"
    PROJECT_NAME: str = "Fleet Management System"
    VERSION: str = "1.0.0"
    DEBUG: bool = True
    PORT: int = 8000
    
    # Database Configuration - Following user rule for hive storage location
    @property
    def HIVE_DB_PATH(self) -> str:
        """Get the Hive database path based on user rule"""
        username = os.environ.get('USERNAME', os.environ.get('USER', 'Unknown'))
        return f"C:\\Users\\{username}\\Documents\\fleetManagementSystem"
    
    # Excel Processing Configuration
    MAX_UPLOAD_SIZE: int = 50 * 1024 * 1024  # 50MB
    ALLOWED_EXTENSIONS: set = {".xlsx", ".xls"}
    TEMP_DIR: str = "temp"
    
    # Logging Configuration
    LOG_LEVEL: str = "INFO"
    LOG_FORMAT: str = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    
    class Config:
        case_sensitive = True
        env_file = ".env"

# Create settings instance
settings = Settings()

# Ensure directories exist
def ensure_directories():
    """Ensure required directories exist"""
    # Create hive database directory
    hive_path = Path(settings.HIVE_DB_PATH)
    hive_path.mkdir(parents=True, exist_ok=True)
    
    # Create temp directory
    temp_path = Path(settings.TEMP_DIR)
    temp_path.mkdir(parents=True, exist_ok=True)
    
    print(f"📁 Hive DB Path: {hive_path}")
    print(f"📁 Temp Directory: {temp_path}")

# Initialize directories on import
ensure_directories()