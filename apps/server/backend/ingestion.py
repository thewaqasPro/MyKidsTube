import asyncio
import os
import uuid
import logging
from typing import Dict, Any, Optional
import yt_dlp
from config import VIDEOS_DIR, THUMBS_DIR, DEFAULT_QUALITY
import database

logger = logging.getLogger("ingestion")
logging.basicConfig(level=logging.INFO)

class IngestionTask:
    def __init__(self, task_id: str, url: str, category_id: str, quality: str = "720p", allowed_profile_ids: Optional[list] = None):
        self.task_id = task_id
        self.url = url
        self.category_id = category_id
        self.quality = quality
        self.allowed_profile_ids = allowed_profile_ids
        self.status = "queued"  # queued, downloading, processing, completed, failed
        self.progress = 0.0
        self.speed_str = ""
        self.eta_str = ""
        self.title = ""
        self.error_message = ""
        self.result: Optional[Dict[str, Any]] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "task_id": self.task_id,
            "url": self.url,
            "category_id": self.category_id,
            "quality": self.quality,
            "status": self.status,
            "progress": round(self.progress, 1),
            "speed": self.speed_str,
            "eta": self.eta_str,
            "title": self.title,
            "error_message": self.error_message,
            "result": self.result
        }

class IngestionManager:
    def __init__(self):
        self.tasks: Dict[str, IngestionTask] = {}
        self.queue: asyncio.Queue = asyncio.Queue()
        self._worker_running = False

    def enqueue(self, url: str, category_id: str, quality: str = DEFAULT_QUALITY, allowed_profile_ids: Optional[list] = None) -> IngestionTask:
        task_id = str(uuid.uuid4())[:8]
        task = IngestionTask(task_id, url, category_id, quality, allowed_profile_ids)
        self.tasks[task_id] = task
        self.queue.put_nowait(task)
        if not self._worker_running:
            asyncio.create_task(self._process_queue())
        return task

    def get_task(self, task_id: str) -> Optional[IngestionTask]:
        return self.tasks.get(task_id)

    def get_all_tasks(self) -> Dict[str, Any]:
        return [t.to_dict() for t in sorted(self.tasks.values(), key=lambda x: x.task_id, reverse=True)[:25]]

    async def _process_queue(self):
        self._worker_running = True
        try:
            while not self.queue.empty():
                task = await self.queue.get()
                await self._run_download(task)
                self.queue.task_done()
        finally:
            self._worker_running = False

    async def _run_download(self, task: IngestionTask):
        loop = asyncio.get_event_loop()
        task.status = "downloading"

        def progress_hook(d):
            if d['status'] == 'downloading':
                total = d.get('total_bytes') or d.get('total_bytes_estimate') or 0
                downloaded = d.get('downloaded_bytes') or 0
                if total > 0:
                    task.progress = (downloaded / total) * 100
                speed = d.get('speed')
                if speed:
                    task.speed_str = f"{speed / (1024 * 1024):.1f} MB/s"
                eta = d.get('eta')
                if eta:
                    task.eta_str = f"{eta}s"
            elif d['status'] == 'finished':
                task.status = "processing"
                task.progress = 99.0

        def execute_ytdlp():
            max_height = 480 if task.quality == "480p" else 720
            video_id = str(uuid.uuid4())[:12]
            output_template = str(VIDEOS_DIR / f"{video_id}.%(ext)s")

            ydl_opts = {
                # 1. Prioritize H.264 (avc1) + AAC (m4a) to enable instant stream copy without CPU transcoding
                'format': (
                    f'bestvideo[vcodec^=avc1][height<={max_height}]+bestaudio[acodec^=mp4a]/'
                    f'bestvideo[ext=mp4][height<={max_height}]+bestaudio[ext=m4a]/'
                    f'best[ext=mp4][height<={max_height}]/'
                    f'bestvideo[height<={max_height}]+bestaudio/'
                    f'best[height<={max_height}]/best'
                ),
                'outtmpl': output_template,
                'merge_output_format': 'mp4',
                'concurrent_fragment_downloads': 1,
                'buffersize': 1024 * 1024,  # Cap internal buffer to 1MB to prevent RAM spikes on 1GB VPS
                'postprocessors': [
                    {
                        'key': 'FFmpegVideoConvertor',
                        'preferedformat': 'mp4',
                    },
                    {
                        'key': 'FFmpegThumbnailsConvertor',
                        'format': 'webp',
                    }
                ],
                'postprocessor_args': {
                    # Stream copy when merging pre-encoded H264+AAC (takes ~2 seconds, zero CPU re-encoding)
                    'Merger': [
                        '-c:v', 'copy',
                        '-c:a', 'copy',
                        '-movflags', '+faststart',
                        '-threads', '1',
                    ],
                    # If transcode is strictly unavoidable (e.g. raw VP9/WebM), use ultrafast 1-thread mode
                    'VideoConvertor': [
                        '-c:v', 'libx264',
                        '-preset', 'ultrafast',
                        '-crf', '26',
                        '-threads', '1',
                        '-c:a', 'aac',
                        '-b:a', '96k',
                        '-movflags', '+faststart',
                    ],
                },
                'writethumbnail': True,
                'progress_hooks': [progress_hook],
                'noplaylist': True,
                'quiet': True,
                'no_warnings': True,
            }

            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(task.url, download=True)
                
                title = info.get('title', 'Unknown Video')
                duration = info.get('duration', 0)
                minutes = duration // 60
                seconds = duration % 60
                duration_formatted = f"{minutes:02d}:{seconds:02d}"

                video_filename = f"{video_id}.mp4"
                final_video_path = VIDEOS_DIR / video_filename

                # Check for thumbnail file generated by yt-dlp
                thumb_filename = f"{video_id}.webp"
                final_thumb_path = THUMBS_DIR / thumb_filename

                # Move/find thumbnail
                possible_thumb = VIDEOS_DIR / f"{video_id}.webp"
                if possible_thumb.exists():
                    possible_thumb.rename(final_thumb_path)
                else:
                    # Fallback thumbnail check for jpg/png
                    for ext in ['jpg', 'jpeg', 'png']:
                        cand = VIDEOS_DIR / f"{video_id}.{ext}"
                        if cand.exists():
                            cand.rename(THUMBS_DIR / f"{video_id}.{ext}")
                            thumb_filename = f"{video_id}.{ext}"
                            break

                file_size = final_video_path.stat().st_size if final_video_path.exists() else 0

                video_record = {
                    "id": video_id,
                    "title": title,
                    "duration": duration,
                    "duration_formatted": duration_formatted,
                    "category_id": task.category_id,
                    "source_url": task.url,
                    "video_file": video_filename,
                    "thumbnail_file": thumb_filename,
                    "file_size_bytes": file_size,
                    "quality": f"{max_height}p"
                }

                database.insert_or_update_video(video_record, task.allowed_profile_ids)
                return video_record

        try:
            record = await loop.run_in_executor(None, execute_ytdlp)
            task.status = "completed"
            task.progress = 100.0
            task.title = record["title"]
            task.result = record
            logger.info(f"Task {task.task_id} completed: {record['title']}")
        except Exception as e:
            logger.error(f"Task {task.task_id} failed: {e}", exc_info=True)
            task.status = "failed"
            task.error_message = str(e)

manager = IngestionManager()
