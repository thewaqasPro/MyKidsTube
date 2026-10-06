import os
import uuid
import shutil
import subprocess
import asyncio
from contextlib import asynccontextmanager
from pathlib import Path
from fastapi import FastAPI, HTTPException, Request, BackgroundTasks, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pydantic import BaseModel
from typing import Optional, List
import yt_dlp

from config import DB_PATH, VIDEOS_DIR, THUMBS_DIR, PARENT_PIN, COOKIES_FILE
import database
from ingestion import manager

@asynccontextmanager
async def lifespan(app: FastAPI):
    database.init_db()
    yield

app = FastAPI(
    title="KidsTube Multi-User Media Server & Ingestion API",
    version="2.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Request Models
class IngestRequest(BaseModel):
    url: str
    category_id: str = "cartoons"
    quality: Optional[str] = "720p"
    allowed_profile_ids: Optional[List[str]] = None

class CategoryCreateRequest(BaseModel):
    id: str
    name: str
    icon: Optional[str] = "category"
    display_order: Optional[int] = 0

class DeviceRegisterRequest(BaseModel):
    device_name: str

class DevicePairRequest(BaseModel):
    pairing_code: str
    profile_id: Optional[str] = None
    family_id: Optional[str] = "default_family"

class ProfileCreateRequest(BaseModel):
    name: str
    avatar_icon: Optional[str] = "bear"
    age_bracket: Optional[str] = "all"
    family_id: Optional[str] = "default_family"

# Helper to construct absolute media URLs
def get_base_url(request: Request) -> str:
    proto = request.headers.get("x-forwarded-proto") or request.url.scheme
    host = request.headers.get("x-forwarded-host") or request.headers.get("host") or request.url.netloc
    if "waqas.pro" in host or proto == "https":
        return f"https://{host}/"
    return f"{proto}://{host}/"

def enrich_video_urls(video: dict, base_url: str) -> dict:
    enriched = dict(video)
    enriched["stream_url"] = f"{base_url}media/videos/{video['video_file']}"
    enriched["thumbnail_url"] = f"{base_url}media/thumbs/{video['thumbnail_file']}"
    
    ch_icon = video.get("channel_icon") or ""
    if ch_icon.startswith("http"):
        enriched["channel_icon_url"] = ch_icon
    elif ch_icon:
        enriched["channel_icon_url"] = f"{base_url}media/thumbs/{ch_icon}"
    else:
        enriched["channel_icon_url"] = None

    if "channel_name" not in enriched or not enriched["channel_name"]:
        if "•" in enriched.get("title", ""):
            enriched["channel_name"] = enriched["title"].split("•")[0].strip()
        else:
            enriched["channel_name"] = "KidsTube"

    return enriched

@app.get("/api/v1/health")
def health():
    return {"status": "ok", "service": "KidsTube Multi-User Media Server"}

# --- Catalog API (Per Profile or Full) ---
@app.get("/api/v1/catalog")
def get_catalog(request: Request, profile_id: Optional[str] = None):
    base_url = get_base_url(request)
    raw_catalog = database.get_profile_catalog(profile_id)
    
    sections = []
    for sec in raw_catalog["sections"]:
        enriched_videos = [enrich_video_urls(v, base_url) for v in sec["videos"]]
        sections.append({
            "category": sec["category"],
            "videos": enriched_videos
        })

    all_enriched = [enrich_video_urls(v, base_url) for v in raw_catalog["all_videos"]]

    return {
        "server_time": database.datetime.utcnow().isoformat(),
        "profile_id": raw_catalog["profile_id"],
        "total_videos": raw_catalog["total_videos"],
        "sections": sections,
        "all_videos": all_enriched
    }

# --- Device Pairing Endpoints (6-Digit Code) ---
@app.post("/api/v1/devices/register")
def register_device_endpoint(req: DeviceRegisterRequest):
    return database.register_device(req.device_name)

@app.get("/api/v1/devices/status/{pairing_code}")
def check_device_status(pairing_code: str):
    device = database.get_device_by_code(pairing_code)
    if not device:
        raise HTTPException(status_code=404, detail="Invalid pairing code")
    
    profile = None
    if device.get("profile_id"):
        conn = database.get_db()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM child_profiles WHERE id = ?", (device["profile_id"],))
        p_row = cursor.fetchone()
        conn.close()
        if p_row:
            profile = dict(p_row)

    return {
        "device_id": device["id"],
        "device_name": device["device_name"],
        "status": device["status"],
        "pairing_code": device["pairing_code"],
        "auth_token": device.get("auth_token"),
        "family_id": device.get("family_id"),
        "profile": profile
    }

@app.post("/api/v1/devices/pair")
def pair_device(req: DevicePairRequest):
    device = database.confirm_device_pairing(
        req.pairing_code,
        req.family_id or "default_family",
        req.profile_id
    )
    if not device:
        raise HTTPException(status_code=400, detail="Pairing failed. Invalid or expired code.")
    return {"status": "paired", "device": device}

@app.get("/api/v1/devices")
def list_devices(family_id: str = "default_family"):
    return database.get_all_paired_devices(family_id)

# --- Child Profiles ---
@app.get("/api/v1/profiles")
def list_profiles(family_id: str = "default_family"):
    return database.get_child_profiles(family_id)

@app.post("/api/v1/profiles")
def create_profile(req: ProfileCreateRequest):
    return database.create_child_profile(
        req.family_id or "default_family",
        req.name,
        req.avatar_icon or "bear",
        req.age_bracket or "all"
    )

@app.delete("/api/v1/profiles/{profile_id}")
def delete_profile(profile_id: str):
    database.delete_child_profile(profile_id)
    return {"status": "deleted", "profile_id": profile_id}

# --- Video Ingestion & Management ---
@app.post("/api/v1/ingest")
async def ingest_video(req: IngestRequest):
    if not req.url or not req.url.strip():
        raise HTTPException(status_code=400, detail="Video URL is required")
    
    task = manager.enqueue(
        req.url.strip(),
        req.category_id,
        req.quality or "720p",
        allowed_profile_ids=req.allowed_profile_ids
    )
    return {
        "status": "queued",
        "task_id": task.task_id,
        "message": "Video queued for download and transcoding"
    }

@app.get("/api/v1/tasks")
def list_tasks():
    return manager.get_all_tasks()

@app.get("/api/v1/categories")
def list_categories():
    return database.get_all_categories()

@app.post("/api/v1/categories")
def create_category(req: CategoryCreateRequest):
    return database.create_category(req.id, req.name, req.icon or "category", req.display_order or 0)

@app.delete("/api/v1/videos/{video_id}")
def delete_video(video_id: str):
    record = database.delete_video(video_id)
    if not record:
        raise HTTPException(status_code=404, detail="Video not found")
    
    v_file = VIDEOS_DIR / record["video_file"]
    t_file = THUMBS_DIR / record["thumbnail_file"]
    if v_file.exists():
        v_file.unlink()
    if t_file.exists():
        t_file.unlink()
        
    return {"status": "deleted", "video_id": video_id}

# --- Seed Catalog with Curated 50 Normal Videos & 50 Shorts ---
@app.post("/api/v1/seed/shorts")
@app.post("/api/v1/seed/catalog")
def seed_kids_catalog():
    import seed_curated_catalog
    return seed_curated_catalog.run_curated_seed()

@app.get("/api/v1/seed/status")
def seed_status():
    conn = database.get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM videos WHERE category_id = 'shorts'")
    shorts_count = cursor.fetchone()[0]
    cursor.execute("SELECT COUNT(*) FROM videos")
    total_count = cursor.fetchone()[0]
    conn.close()
    return {
        "shorts_count": shorts_count,
        "total_videos": total_count,
        "seeded": shorts_count >= 50
    }

# --- YouTube Cookies Configuration (Bypass Datacenter IP restrictions) ---
class CookiesUploadRequest(BaseModel):
    cookies_content: str

@app.get("/api/v1/cookies/status")
def cookies_status():
    exists = COOKIES_FILE.exists()
    size = COOKIES_FILE.stat().st_size if exists else 0
    lines_count = 0
    if exists and size > 0:
        try:
            with open(COOKIES_FILE, "r", encoding="utf-8", errors="ignore") as f:
                lines_count = sum(1 for line in f if line.strip() and not line.startswith("#"))
        except Exception:
            pass
    return {
        "exists": exists and size > 0,
        "size_bytes": size,
        "valid_cookies_count": lines_count,
        "path": str(COOKIES_FILE)
    }

@app.post("/api/v1/cookies/upload")
def upload_cookies(req: CookiesUploadRequest):
    content = req.cookies_content.strip()
    if not content:
        raise HTTPException(status_code=400, detail="Cookies content is empty")
    COOKIES_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(COOKIES_FILE, "w", encoding="utf-8") as f:
        f.write(content + "\n")
    return {
        "status": "saved",
        "size_bytes": len(content),
        "message": "Cookies saved successfully."
    }

@app.post("/api/v1/cookies/test")
async def test_cookies():
    if not COOKIES_FILE.exists() or COOKIES_FILE.stat().st_size == 0:
        return {"valid": False, "message": "No cookies file found. Please paste and save cookies first."}
    
    loop = asyncio.get_running_loop()
    def _test():
        ydl_opts = {
            'cookiefile': str(COOKIES_FILE),
            'quiet': True,
            'no_warnings': True,
            'skip_download': True,
            'js_runtimes': {'nodejs': {}},
        }
        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info("https://www.youtube.com/watch?v=dQw4w9WgXcQ", download=False)
                return {
                    "valid": True,
                    "message": f"Successfully verified! Authenticated session confirmed by YouTube."
                }
        except Exception as e:
            err = str(e)
            if "Sign in to confirm you’re not a bot" in err:
                return {
                    "valid": False,
                    "message": "YouTube still asks for bot verification. Your cookies may have expired or were exported without being signed in."
                }
            return {"valid": False, "message": f"Verification failed: {err[:160]}"}

    return await loop.run_in_executor(None, _test)

@app.delete("/api/v1/cookies")
def delete_cookies():
    if COOKIES_FILE.exists():
        COOKIES_FILE.unlink()
    return {"status": "deleted"}

# --- Direct Video File Upload ---
@app.post("/api/v1/upload")
async def upload_video_file(
    file: UploadFile = File(...),
    category_id: str = Form("cartoons"),
    title: Optional[str] = Form(None),
    allowed_profile_ids: Optional[str] = Form(None)
):
    video_id = str(uuid.uuid4())[:12]
    ext = Path(file.filename or "video.mp4").suffix.lower() or ".mp4"
    temp_target = VIDEOS_DIR / f"{video_id}_temp{ext}"
    final_video = VIDEOS_DIR / f"{video_id}.mp4"
    thumb_file = THUMBS_DIR / f"{video_id}.webp"

    try:
        with open(temp_target, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        if ext != ".mp4":
            subprocess.run([
                "ffmpeg", "-y", "-i", str(temp_target),
                "-c:v", "libx264", "-preset", "ultrafast", "-crf", "26",
                "-c:a", "aac", "-b:a", "96k", "-movflags", "+faststart",
                str(final_video)
            ], check=True)
            if temp_target.exists():
                temp_target.unlink()
        else:
            temp_target.rename(final_video)

        # Extract duration
        duration = 0
        try:
            probe = subprocess.run([
                "ffprobe", "-v", "error", "-show_entries", "format=duration",
                "-of", "default=noprint_wrappers=1:nokey=1", str(final_video)
            ], capture_output=True, text=True)
            duration = int(float(probe.stdout.strip()))
        except Exception:
            pass

        # Generate thumbnail
        try:
            subprocess.run([
                "ffmpeg", "-y", "-ss", "00:00:02", "-i", str(final_video),
                "-vframes", "1", "-vf", "scale=640:-1", str(thumb_file)
            ], check=False)
        except Exception:
            pass

        minutes = duration // 60
        seconds = duration % 60
        duration_formatted = f"{minutes:02d}:{seconds:02d}"

        profiles = None
        if allowed_profile_ids:
            try:
                import json
                parsed = json.loads(allowed_profile_ids)
                if isinstance(parsed, list):
                    profiles = [str(x) for x in parsed]
                else:
                    profiles = [str(parsed)]
            except Exception:
                profiles = [p.strip() for p in allowed_profile_ids.split(",") if p.strip()]

        video_record = {
            "id": video_id,
            "title": title or Path(file.filename or "Uploaded Video").stem,
            "duration": duration,
            "duration_formatted": duration_formatted,
            "category_id": category_id,
            "source_url": "Direct Upload",
            "video_file": f"{video_id}.mp4",
            "thumbnail_file": f"{video_id}.webp",
            "file_size_bytes": final_video.stat().st_size if final_video.exists() else 0,
            "quality": "Direct"
        }

        database.insert_or_update_video(video_record, profiles)
        return {"status": "uploaded", "video": video_record}
    except Exception as e:
        if temp_target.exists():
            temp_target.unlink()
        raise HTTPException(status_code=500, detail=str(e))

# Static file mounts
app.mount("/media/videos", StaticFiles(directory=str(VIDEOS_DIR)), name="media_videos")
app.mount("/media/thumbs", StaticFiles(directory=str(THUMBS_DIR)), name="media_thumbs")

STATIC_DIR = Path(__file__).parent / "static"
if STATIC_DIR.exists():
    app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")

@app.get("/")
def serve_dashboard():
    dashboard_file = STATIC_DIR / "index.html"
    if dashboard_file.exists():
        return FileResponse(str(dashboard_file))
    return {"message": "KidsTube Media Server API is running. Access /api/v1/catalog"}
