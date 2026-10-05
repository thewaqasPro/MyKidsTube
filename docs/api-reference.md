# KidsTube: REST API Reference

The backend exposes a lightweight, standard REST API on port `8080` (fronted by Nginx) or `8000` (FastAPI direct).

Base URL: `http://<SERVER_HOST>:8080/api/v1`

---

## 1. System & Health

### `GET /api/v1/health`
Check if the backend server is reachable.
- **Response `200 OK`:**
  ```json
  {
    "status": "ok",
    "service": "KidsTube Multi-User Media Server"
  }
  ```

---

## 2. Media Catalog

### `GET /api/v1/catalog`
Fetches all categories and videos. Optionally filter by child profile.

- **Query Parameters:**
  - `profile_id` (optional, string): If provided, returns only videos curated for this specific child profile.
- **Response `200 OK`:**
  ```json
  {
    "server_time": "2026-10-05T20:30:00.000000",
    "profile_id": "all",
    "total_videos": 12,
    "sections": [
      {
        "category": {
          "id": "cartoons",
          "name": "Cartoons",
          "icon": "tv",
          "display_order": 1
        },
        "videos": [
          {
            "id": "a1b2c3d4",
            "title": "Sample Cartoon Episode 1",
            "duration": 600,
            "duration_formatted": "10:00",
            "category_id": "cartoons",
            "source_url": "https://youtube.com/watch?v=...",
            "video_file": "a1b2c3d4.mp4",
            "thumbnail_file": "a1b2c3d4.webp",
            "stream_url": "http://SERVER_HOST:8080/media/videos/a1b2c3d4.mp4",
            "thumbnail_url": "http://SERVER_HOST:8080/media/thumbs/a1b2c3d4.webp",
            "file_size_bytes": 84500000,
            "quality": "720p"
          }
        ]
      }
    ],
    "all_videos": [...]
  }
  ```

---

## 3. Video Ingestion & Tasks

### `POST /api/v1/ingest`
Queues a video URL for background downloading and transcoding.
- **Request Body:**
  ```json
  {
    "url": "https://www.youtube.com/watch?v=example",
    "category_id": "cartoons",
    "quality": "720p",
    "allowed_profile_ids": ["kids_all", "kids_toddler"]
  }
  ```
- **Response `200 OK`:**
  ```json
  {
    "status": "queued",
    "task_id": "task_4a1b",
    "message": "Video queued for download and transcoding"
  }
  ```

### `GET /api/v1/tasks`
Lists active and recently completed download/transcoding jobs.
- **Response `200 OK`:**
  ```json
  [
    {
      "task_id": "task_4a1b",
      "url": "https://www.youtube.com/watch?v=example",
      "status": "downloading",
      "progress": 68.4,
      "speed": "2.4 MB/s",
      "eta": "12s",
      "title": "Sample Video Title",
      "error_message": "",
      "result": null
    }
  ]
  ```

### `DELETE /api/v1/videos/{video_id}`
Deletes a video, its thumbnail file from disk, and removes database records.

---

## 4. Device Registration & 6-Digit Pairing

### `POST /api/v1/devices/register`
Called by a new tablet/phone to obtain a 6-digit pairing code.
- **Request Body:**
  ```json
  {
    "device_name": "Living Room Tablet"
  }
  ```
- **Response `200 OK`:**
  ```json
  {
    "device_id": "dev_9x8y7z",
    "device_name": "Living Room Tablet",
    "pairing_code": "KID-482",
    "status": "pending"
  }
  ```

### `GET /api/v1/devices/status/{pairing_code}`
Polled by the mobile device every 2–3 seconds while displaying the pairing screen.
- **Response (Pending):**
  ```json
  {
    "device_id": "dev_9x8y7z",
    "status": "pending",
    "pairing_code": "KID-482"
  }
  ```
- **Response (Once Paired by Parent):**
  ```json
  {
    "device_id": "dev_9x8y7z",
    "status": "paired",
    "pairing_code": "KID-482",
    "auth_token": "tok_abcdef123456",
    "family_id": "default_family",
    "profile": {
      "id": "profile_maya",
      "name": "Maya",
      "avatar_icon": "bear",
      "age_bracket": "toddler"
    }
  }
  ```

### `POST /api/v1/devices/pair`
Called by the Parent Web Dashboard to authorize a device.
- **Request Body:**
  ```json
  {
    "pairing_code": "KID-482",
    "profile_id": "profile_maya",
    "family_id": "default_family"
  }
  ```

### `GET /api/v1/devices`
Lists all active paired devices.

---

## 5. Child Profiles

### `GET /api/v1/profiles`
Returns all child profiles for the family.
- **Response `200 OK`:**
  ```json
  [
    {
      "id": "profile_maya",
      "family_id": "default_family",
      "name": "Maya",
      "avatar_icon": "bear",
      "age_bracket": "toddler"
    }
  ]
  ```

### `POST /api/v1/profiles`
Creates a new child profile.
- **Request Body:**
  ```json
  {
    "name": "Noah",
    "avatar_icon": "rocket",
    "age_bracket": "big_kid",
    "family_id": "default_family"
  }
  ```

### `DELETE /api/v1/profiles/{profile_id}`
Removes a child profile and its video permissions.
