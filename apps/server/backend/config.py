import os
from pathlib import Path

DATA_DIR = Path(os.getenv("DATA_DIR", "/data"))
MEDIA_DIR = Path(os.getenv("MEDIA_DIR", "/data/media"))
VIDEOS_DIR = MEDIA_DIR / "videos"
THUMBS_DIR = MEDIA_DIR / "thumbs"
DB_PATH = DATA_DIR / "catalog.db"

PORT = int(os.getenv("PORT", "8000"))
DEFAULT_QUALITY = os.getenv("DEFAULT_QUALITY", "480p")
MAX_CONCURRENT_DOWNLOADS = int(os.getenv("MAX_CONCURRENT_DOWNLOADS", "1"))
PARENT_PIN = os.getenv("PARENT_PIN", "1234")

# Ensure required directories exist
VIDEOS_DIR.mkdir(parents=True, exist_ok=True)
THUMBS_DIR.mkdir(parents=True, exist_ok=True)
