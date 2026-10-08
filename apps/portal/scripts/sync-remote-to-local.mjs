import { execSync } from 'child_process';
import { readdirSync, existsSync } from 'fs';
import { join } from 'path';

const d1Dir = join(process.cwd(), '.wrangler/state/v3/d1/miniflare-D1DatabaseObject');

if (!existsSync(d1Dir)) {
  console.error('❌ Local Miniflare D1 directory not found:', d1Dir);
  process.exit(1);
}

const sqliteFiles = readdirSync(d1Dir).filter((f) => f.endsWith('.sqlite') && !f.startsWith('metadata'));
if (sqliteFiles.length === 0) {
  console.error('❌ No SQLite databases found in local Miniflare directory.');
  process.exit(1);
}

const localDbPath = join(d1Dir, sqliteFiles[0]);
console.log('📦 Target local database:', localDbPath);

const tables = ['categories', 'videos', 'families', 'child_profiles', 'admin_settings', 'devices'];

for (const table of tables) {
  console.log(`⬇️ Fetching ${table} from remote Cloudflare D1...`);
  try {
    const rawJson = execSync(
      `pnpm wrangler d1 execute mykidstube --remote --command "SELECT * FROM ${table};" --json`,
      { encoding: 'utf-8', maxBuffer: 10 * 1024 * 1024 }
    );

    const parsed = JSON.parse(rawJson);
    const rows = parsed[0]?.results || [];

    if (rows.length === 0) {
      console.log(`  ℹ️ No rows in ${table}.`);
      continue;
    }

    console.log(`  ✓ Got ${rows.length} rows for ${table}, inserting into local database...`);

    // Insert rows in batches
    for (const row of rows) {
      const keys = Object.keys(row);
      const values = keys.map((k) => {
        const val = row[k];
        if (val === null || val === undefined) return 'NULL';
        if (typeof val === 'number') return val;
        // Escape single quotes for SQL
        return `'${String(val).replace(/'/g, "''")}'`;
      });

      const sql = `INSERT OR REPLACE INTO ${table} (${keys.map((k) => `"${k}"`).join(', ')}) VALUES (${values.join(', ')});`;
      execSync(`sqlite3 "${localDbPath}" "${sql.replace(/"/g, '\\"')}"`);
    }

    console.log(`  ✅ Successfully synced ${rows.length} rows for ${table}`);
  } catch (err) {
    console.error(`  ❌ Failed to sync ${table}:`, err.message);
  }
}

console.log('🎉 Done! All data synchronized from remote Cloudflare D1 to local database.');
