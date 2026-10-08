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

function getRemoteD1Credentials() {
  const accountId = process.env.CLOUDFLARE_ACCOUNT_ID;
  const databaseId = process.env.CLOUDFLARE_DATABASE_ID;
  const token = process.env.CLOUDFLARE_D1_TOKEN || process.env.CLOUDFLARE_API_TOKEN;

  if (!accountId || !databaseId || !token) {
    throw new Error(
      'Missing required remote D1 credentials. Ensure CLOUDFLARE_ACCOUNT_ID, CLOUDFLARE_DATABASE_ID, and CLOUDFLARE_D1_TOKEN or CLOUDFLARE_API_TOKEN are set in your environment.'
    );
  }

  return { accountId, databaseId, token };
}

const isRemote = process.env.DB_REMOTE === 'true';

export default defineConfig(
  isRemote
    ? {
        schema: './src/db/schema/index.ts',
        out: './drizzle',
        dialect: 'sqlite',
        driver: 'd1-http',
        dbCredentials: getRemoteD1Credentials(),
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

