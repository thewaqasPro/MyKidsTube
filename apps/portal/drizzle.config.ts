import { defineConfig } from 'drizzle-kit';
import fs from 'node:fs';
import path from 'node:path';

function getLocalD1DB(): string {
  const basePath = path.resolve('.wrangler/state/v3/d1/miniflare-D1DatabaseObject');
  if (fs.existsSync(basePath)) {
    const files = fs.readdirSync(basePath);
    const dbFile = files.find((f) => f.endsWith('.sqlite') && f !== 'metadata.sqlite');
    if (dbFile) {
      return path.join(basePath, dbFile);
    }
  }
  return '.wrangler/state/v3/d1/miniflare-D1DatabaseObject/db.sqlite';
}

const isRemote = process.env.DB_REMOTE === 'true' && Boolean(process.env.CLOUDFLARE_D1_TOKEN || process.env.CLOUDFLARE_API_TOKEN);

export default defineConfig(
  isRemote
    ? {
        schema: './src/db/schema/index.ts',
        out: './drizzle',
        dialect: 'sqlite',
        driver: 'd1-http',
        dbCredentials: {
          accountId: process.env.CLOUDFLARE_ACCOUNT_ID || 'e625c672ee355cd19487de814338560a',
          databaseId: process.env.CLOUDFLARE_DATABASE_ID || 'dce947fe-b59f-40f0-9788-c76414b476b4',
          token: (process.env.CLOUDFLARE_D1_TOKEN || process.env.CLOUDFLARE_API_TOKEN)!,
        },
      }
    : {
        schema: './src/db/schema/index.ts',
        out: './drizzle',
        dialect: 'sqlite',
        dbCredentials: {
          url: getLocalD1DB(),
        },
      }
);

