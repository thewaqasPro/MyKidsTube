import { execSync } from 'child_process';
import { readdirSync, existsSync } from 'fs';
import { join } from 'path';

const d1Dir = join(process.cwd(), '.wrangler/state/v3/d1/miniflare-D1DatabaseObject');

if (!existsSync(d1Dir)) {
  console.error('❌ Local Miniflare D1 directory not found:', d1Dir);
  process.exit(1);
}

const sqliteFiles = readdirSync(d1Dir).filter((f) => f.endsWith('.sqlite'));
if (sqliteFiles.length === 0) {
  console.error('❌ No SQLite databases found in local Miniflare directory.');
  process.exit(1);
}

const localDbPath = join(d1Dir, sqliteFiles[0]);
console.log('📦 Reading local database:', localDbPath);

try {
  // Export videos as INSERT OR REPLACE statements
  const rawSql = execSync(
    `sqlite3 "${localDbPath}" ".mode insert videos" "SELECT * FROM videos;"`,
    { encoding: 'utf-8' }
  );

  if (!rawSql.trim()) {
    console.log('ℹ️ No videos found in local database.');
    process.exit(0);
  }

  // Convert INSERT INTO to INSERT OR REPLACE INTO for idempotency
  const upsertSql = rawSql
    .split('\n')
    .map((line) => line.replace(/^INSERT INTO videos/, 'INSERT OR REPLACE INTO videos'))
    .join('\n');

  console.log(`🚀 Syncing videos to remote Cloudflare D1...`);
  
  execSync(
    `pnpm wrangler d1 execute mykidstube --remote --command "${upsertSql.replace(/"/g, '\\"')}"`,
    { stdio: 'inherit' }
  );

  console.log('✅ Remote Cloudflare D1 database successfully synchronized with local videos!');
} catch (err) {
  console.error('❌ Sync failed:', err.message);
  process.exit(1);
}
