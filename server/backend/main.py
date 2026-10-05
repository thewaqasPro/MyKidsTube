import os
from contextlib import asynccontextmanager
from pathlib import Path
from fastapi import FastAPI, HTTPException, Request, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pydantic import BaseModel
from typing import Optional

from config import DB_PATH, VIDEOS_DIR, THUMBS_DIR, PARENT_PIN
import database
from ingestion import manager

@asynccontextmanager
async def lifespan(app: FastAPI):
    database.init_db()
    yield

app = FastAPI(
    title="KidsTube Media Server & Ingestion API",
    version="1.0.0",
    lifespan=lifespan
)

# Enable CORS for Flutter mobile clients and web browsers
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Ingest Request Model
class IngestRequest(BaseModel):
    url: str
    category_id: str = "cartoons"
    quality: Optional[str] = "720p"

class CategoryCreateRequest(BaseModel):
    id: str
    name: str
    icon: Optional[str] = "category"
    display_order: Optional[int] = 0

# Helper to construct absolute media URLs
def enrich_video_urls(video: dict, base_url: str) -> dict:
    enriched = dict(video)
    enriched["stream_url"] = f"{base_url}media/videos/{video['video_file']}"
    enriched["thumbnail_url"] = f"{base_url}media/thumbs/{video['thumbnail_file']}"
    return enriched

@app.get("/api/v1/health")
def health():
    return {"status": "ok", "service": "KidsTube Media Server"}

@app.get("/api/v1/catalog")
def get_catalog(request: Request):
    base_url = str(request.base_url)
    raw_catalog = database.get_catalog()
    
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
        "total_videos": raw_catalog["total_videos"],
        "sections": sections,
        "all_videos": all_enriched
    }

@app.post("/api/v1/ingest")
def ingest_video(req: IngestRequest):
    if not req.url or not req.url.strip():
        raise HTTPException(status_code=400, detail="Video URL is required")
    
    task = manager.enqueue(req.url.strip(), req.category_id, req.quality or "720p")
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
    
    # Remove files from disk
    v_file = VIDEOS_DIR / record["video_file"]
    t_file = THUMBS_DIR / record["thumbnail_file"]
    if v_file.exists():
        v_file.unlink()
    if t_file.exists():
        t_file.unlink()
        
    return {"status": "deleted", "video_id": video_id}

# Direct media serving (fallback when running outside Nginx)
app.mount("/media/videos", StaticFiles(directory=str(VIDEOS_DIR)), name="media_videos")
app.mount("/media/thumbs", StaticFiles(directory=str(THUMBS_DIR)), name="media_thumbs")

# Static files for parent dashboard
STATIC_DIR = Path(__file__).parent / "static"
if STATIC_DIR.exists():
    app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")

@app.get("/")
def serve_dashboard():
    dashboard_file = STATIC_DIR / "index.html"
    if dashboard_file.exists():
        return FileResponse(str(dashboard_file))
    return {"message": "KidsTube Media Server API is running. Access /api/v1/catalog"}
