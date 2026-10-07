# KidsTube: REST API Reference

The KidsTube API is hosted on Cloudflare Workers / Pages Edge runtime backed by Cloudflare D1 SQL database and Cloudflare R2 storage, with media binary files served by an optimized Nginx instance running on the storage host.

- **Cloudflare API Base URL:** `https://mykidstube.kidstube.workers.dev/api`
- **Media Host Base URL:** `https://<VPS_HOST>/media/videos/` and `/media/thumbs/`
- **Reverse Proxy Route (Optional):** `https://<VPS_HOST>/api/` (proxied transparently to Cloudflare Worker)

---

## 1. Authentication & Security Model

KidsTube enforces strict separation between parent administrative operations and device consumption:

1. **Parent Administration:**
   - Parent APIs require an active session verified via the `kidstube_parent_session` cookie.
   - Sessions are 256-bit cryptographically random tokens stored as SHA-256 hashes in D1 `parent_sessions` with 24-hour expiration.
   - Unauthenticated or expired requests receive `401 Unauthorized`.

2. **Mobile Device Access:**
   - Paired devices authenticate using a bearer token issued during the 6-digit pairing handshake: `Authorization: Bearer <device_auth_token>`.
   - Device pairing codes expire after 10 minutes and are single-use.

3. **CORS & Rate Limiting:**
   - State-changing APIs enforce strict CORS and reject unauthorized cross-origin requests.
   - Pairing and sensitive endpoints are rate-limited to 10 requests per minute per IP.

---

## 2. Parent Authentication & Session

### `POST /api/auth/login`
Authenticates a parent using their PIN and sets a secure HttpOnly session cookie.
- **Request Body:**
  ```json
  {
    "pin": "1234"
  }
  ```
- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "message": "Authenticated successfully"
  }
  ```
- **Response Headers:**
  `Set-Cookie: kidstube_parent_session=<token>; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=86400`

### `POST /api/auth/logout`
Terminates the parent session, revoking the token in D1 and clearing the cookie.
- **Response `200 OK`:**
  ```json
  {
    "success": true
  }
  ```

---

## 3. Media Catalog & Profiles

### `GET /api/v1/catalog`
Fetches all categories and videos. Filterable by child profile.
- **Query Parameters:**
  - `profile_id` (optional, string): Filters videos assigned to this child profile.
- **Headers:**
  - `Cache-Control: private, max-age=60`
- **Response `200 OK`:**
  ```json
  {
    "server_time": "2026-10-07T12:00:00.000Z",
    "profile_id": "all",
    "total_videos": 12,
    "sections": [...],
    "all_videos": [...]
  }
  ```

### `GET /api/v1/profiles`
Returns all child profiles for the family account.
- **Headers:**
  - `Cache-Control: private, max-age=60`

---

## 4. Device Registration & Pairing

### `POST /api/v1/devices/register`
Called by mobile device on fresh install to request a 6-digit pairing code.
- **Request Body:**
  ```json
  {
    "device_name": "Kids Tablet"
  }
  ```
- **Response `200 OK`:**
  ```json
  {
    "device_id": "3f48a1...uuid",
    "device_name": "Kids Tablet",
    "pairing_code": "842915",
    "status": "pending",
    "expires_at": "2026-10-07T12:10:00.000Z"
  }
  ```

### `GET /api/v1/devices/status/{pairing_code}`
Polled by the mobile device while awaiting parent authorization. Rate-limited (10 req/min).
- **Response (Pending):**
  ```json
  {
    "status": "pending",
    "pairing_code": "842915"
  }
  ```
- **Response (Paired - One-Time Token Delivery):**
  ```json
  {
    "status": "paired",
    "auth_token": "dev_tok_random64hex...",
    "profile_id": "profile_maya",
    "profile_name": "Maya"
  }
  ```

### `POST /api/v1/devices/pair` (Requires Parent Session)
Called from the parent portal to bind the device to a profile.
- **Request Body:**
  ```json
  {
    "pairing_code": "842915",
    "profile_id": "profile_maya"
  }
  ```

---

## 5. Studio & Queue Management (Requires Parent Session)

- `GET /api/studio/videos`: List all catalog videos with curation metadata.
- `PATCH /api/studio/videos`: Update video title, category, or status.
- `DELETE /api/studio/videos?id={id}`: Remove video from catalog.
- `GET /api/studio/stats`: Returns library counts, pending queue stats, and storage metrics.
- `GET /api/studio/devices`: Returns real paired device list.
- `POST /api/queue/add`: Add YouTube URLs to ingest queue (max 20 URLs per batch, parent-authed).
- `GET /api/queue/pending`: Returns links.txt for batch processing script.
