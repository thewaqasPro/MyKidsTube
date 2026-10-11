# D1 Database Seeds & Dumps

This directory contains database dumps and seed scripts for Cloudflare D1 (`mykidstube` / `kidstube-db`).

## Files

- **`d1_ready.sql`**
  The canonical database setup script. Drops/creates tables (`families`, `categories`, `child_profiles`, `videos`, `profile_video_assignments`, `devices`, etc.) and seeds initial categories, default profiles (`kids_all`, `kids_toddler`), and the baseline video catalog.
  ```bash
  # Execute locally
  npx wrangler d1 execute kidstube-db --local --file=seeds/d1_ready.sql

  # Execute on remote D1
  npx wrangler d1 execute mykidstube --remote --file=seeds/d1_ready.sql
  ```

- **`d1_catalog_dump.sql`**
  Raw SQLite dump exported from the live Cloudflare D1 catalog (wrapped in `BEGIN TRANSACTION` / `COMMIT`).

- **`d1_clean.sql`**
  Cleaned export of catalog tables without outer transaction wrappers for compatible batch imports.
