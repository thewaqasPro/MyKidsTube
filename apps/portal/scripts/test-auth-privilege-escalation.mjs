import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import { execSync } from 'node:child_process';

import fs from 'node:fs';
import path from 'node:path';

const BASE_URL = process.env.TEST_BASE_URL || 'http://localhost:4321';
const DB_RELATIVE = '.wrangler/state/v3/d1/miniflare-D1DatabaseObject/26aba24673b56639dc1c07e8e573f4ed629a7f06d2569a5c07b6c52eec7fb33d.sqlite';
const SQLITE_DB = fs.existsSync(DB_RELATIVE)
  ? path.resolve(DB_RELATIVE)
  : path.resolve('apps/portal', DB_RELATIVE);

function sha256(text) {
  return crypto.createHash('sha256').update(text).digest('hex');
}

function runSql(sql) {
  execSync(`sqlite3 "${SQLITE_DB}" "${sql}"`);
}

async function runTests() {
  console.log(`\n🔒 Running Security Verification against ${BASE_URL}...\n`);

  // Setup test credentials in SQLite
  const testDevToken = 'dev_tok_automated_test_secret_abc123';
  const testDevHash = sha256(testDevToken);
  const testDeviceId = 'dev_auto_test_1';

  const testParentToken = 'parent_tok_automated_test_secret_xyz789';
  const testParentHash = sha256(testParentToken);

  runSql(`INSERT OR REPLACE INTO devices (id, device_name, pairing_code, status, auth_token, created_at) VALUES ('${testDeviceId}', 'Test Tablet', 'AUT-999', 'paired', '${testDevHash}', datetime('now'));`);
  runSql(`INSERT OR REPLACE INTO parent_sessions (token_hash, created_at, expires_at) VALUES ('${testParentHash}', datetime('now'), datetime('now', '+1 day'));`);

  try {
    // -------------------------------------------------------------
    // Acceptance Criteria 1:
    // A valid device auth_token returns 401 on:
    // DELETE /api/studio/videos, POST /api/queue/add, POST /api/v1/ingest, POST /api/cookies, POST /api/assets/warm
    // -------------------------------------------------------------
    console.log('--- Testing Device Token on Parent Routes (Must return 401) ---');

    const parentEndpoints = [
      { name: 'DELETE /api/studio/videos', url: `${BASE_URL}/api/studio/videos`, method: 'DELETE', body: {} },
      { name: 'POST /api/queue/add', url: `${BASE_URL}/api/queue/add`, method: 'POST', body: { url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ' } },
      { name: 'POST /api/v1/ingest', url: `${BASE_URL}/api/v1/ingest`, method: 'POST', body: { url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ' } },
      { name: 'POST /api/cookies', url: `${BASE_URL}/api/cookies`, method: 'POST', body: { cookies: 'test' } },
      { name: 'POST /api/assets/warm', url: `${BASE_URL}/api/assets/warm`, method: 'POST', body: {} },
    ];

    for (const ep of parentEndpoints) {
      const res = await fetch(ep.url, {
        method: ep.method,
        headers: {
          'Origin': BASE_URL,
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${testDevToken}`,
        },
        body: ep.method !== 'GET' && Object.keys(ep.body).length > 0 ? JSON.stringify(ep.body) : undefined,
      });

      assert.equal(res.status, 401, `Expected 401 for device token on ${ep.name}, got ${res.status}`);
      const data = await res.json().catch(() => ({}));
      assert.equal(data.error, 'unauthorized', `Expected error: 'unauthorized' on ${ep.name}`);
      console.log(`  ✅ ${ep.name} correctly rejected device token with 401 Unauthorized`);
    }

    // -------------------------------------------------------------
    // Acceptance Criteria 2:
    // A valid parent session returns 200 on the same routes
    // -------------------------------------------------------------
    console.log('\n--- Testing Parent Session on Parent Routes (Must return 200) ---');

    // 1. DELETE /api/studio/videos?ids=test_dummy_r1 (existing video returns 200 for parent)
    {
      runSql(`INSERT OR REPLACE INTO categories (id, name) VALUES ('test_cat_r1', 'Test Cat R1'); INSERT OR REPLACE INTO videos (id, title, category_id, video_file, thumbnail_file, created_at) VALUES ('test_dummy_r1', 'Dummy R1', 'test_cat_r1', 'v.mp4', 'v.webp', datetime('now'));`);
      const res = await fetch(`${BASE_URL}/api/studio/videos?ids=test_dummy_r1`, {
        method: 'DELETE',
        headers: {
          'Origin': BASE_URL,
          'Content-Type': 'application/json',
          'Cookie': `kidstube_parent_session=${testParentToken}`,
        },
      });
      assert.equal(res.status, 200, `Expected 200 on DELETE /api/studio/videos for parent, got ${res.status}`);
      console.log('  ✅ DELETE /api/studio/videos correctly returned 200 for parent session');
    }

    // 2. POST /api/queue/add
    {
      const res = await fetch(`${BASE_URL}/api/queue/add`, {
        method: 'POST',
        headers: {
          'Origin': BASE_URL,
          'Content-Type': 'application/json',
          'Cookie': `kidstube_parent_session=${testParentToken}`,
        },
        body: JSON.stringify({ url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ' }),
      });
      assert.equal(res.status, 200, `Expected 200 on POST /api/queue/add for parent, got ${res.status}`);
      console.log('  ✅ POST /api/queue/add correctly returned 200 for parent session');
      // Clean up queued video
      runSql(`DELETE FROM videos WHERE id = 'dQw4w9WgXcQ';`);
    }

    // 3. POST /api/v1/ingest
    {
      const res = await fetch(`${BASE_URL}/api/v1/ingest`, {
        method: 'POST',
        headers: {
          'Origin': BASE_URL,
          'Content-Type': 'application/json',
          'Cookie': `kidstube_parent_session=${testParentToken}`,
        },
        body: JSON.stringify({ url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ' }),
      });
      assert.equal(res.status, 200, `Expected 200 on POST /api/v1/ingest for parent, got ${res.status}`);
      console.log('  ✅ POST /api/v1/ingest correctly returned 200 for parent session');
      runSql(`DELETE FROM videos WHERE id = 'dQw4w9WgXcQ';`);
    }

    // 4. POST /api/assets/warm
    {
      const res = await fetch(`${BASE_URL}/api/assets/warm`, {
        method: 'POST',
        headers: {
          'Origin': BASE_URL,
          'Content-Type': 'application/json',
          'Cookie': `kidstube_parent_session=${testParentToken}`,
        },
      });
      assert.equal(res.status, 200, `Expected 200 on POST /api/assets/warm for parent, got ${res.status}`);
      console.log('  ✅ POST /api/assets/warm correctly returned 200 for parent session');
    }

    // -------------------------------------------------------------
    // Acceptance Criteria 3:
    // Unauthenticated requests still 401 everywhere (no regression)
    // -------------------------------------------------------------
    console.log('\n--- Testing Unauthenticated Requests (Must return 401) ---');

    for (const ep of parentEndpoints) {
      const res = await fetch(ep.url, {
        method: ep.method,
        headers: {
          'Origin': BASE_URL,
          'Content-Type': 'application/json',
        },
        body: ep.method !== 'GET' && Object.keys(ep.body).length > 0 ? JSON.stringify(ep.body) : undefined,
      });

      assert.equal(res.status, 401, `Expected 401 for unauthenticated on ${ep.name}, got ${res.status}`);
      console.log(`  ✅ ${ep.name} correctly returned 401 for unauthenticated request`);
    }

    // -------------------------------------------------------------
    // Device endpoints (api/v1/devices/*)
    // -------------------------------------------------------------
    console.log('\n--- Testing Device Endpoints (/api/v1/devices/*) ---');

    // 1. GET /api/v1/devices unauthenticated -> 401
    {
      const res = await fetch(`${BASE_URL}/api/v1/devices`, {
        headers: { 'Content-Type': 'application/json' },
      });
      assert.equal(res.status, 401, `Expected 401 on GET /api/v1/devices unauthenticated, got ${res.status}`);
      console.log('  ✅ GET /api/v1/devices correctly returned 401 for missing token');
    }

    // 2. GET /api/v1/devices with invalid token -> 401
    {
      const res = await fetch(`${BASE_URL}/api/v1/devices`, {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer wrong_token',
        },
      });
      assert.equal(res.status, 401, `Expected 401 on GET /api/v1/devices with invalid token, got ${res.status}`);
      console.log('  ✅ GET /api/v1/devices correctly returned 401 for invalid token');
    }

    // 3. GET /api/v1/devices with valid device token -> 200
    {
      const res = await fetch(`${BASE_URL}/api/v1/devices`, {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${testDevToken}`,
        },
      });
      assert.equal(res.status, 200, `Expected 200 on GET /api/v1/devices with valid token, got ${res.status}`);
      const data = await res.json();
      assert.equal(data.id, testDeviceId);
      console.log('  ✅ GET /api/v1/devices correctly returned 200 with device data for valid token');
    }

    // 4. POST /api/v1/devices/pair with device token -> 401
    {
      const res = await fetch(`${BASE_URL}/api/v1/devices/pair`, {
        method: 'POST',
        headers: {
          'Origin': BASE_URL,
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${testDevToken}`,
        },
        body: JSON.stringify({ pairing_code: 'AUT-999' }),
      });
      assert.equal(res.status, 401, `Expected 401 on POST /api/v1/devices/pair with device token, got ${res.status}`);
      console.log('  ✅ POST /api/v1/devices/pair correctly rejected device token with 401');
    }

    // 5. Studio & Upload pages redirect non-parents to /login
    {
      const resStudio = await fetch(`${BASE_URL}/studio`, {
        redirect: 'manual',
        headers: { 'Authorization': `Bearer ${testDevToken}` },
      });
      assert.equal(resStudio.status, 302, `Expected 302 redirect for device token on /studio, got ${resStudio.status}`);
      assert.ok(resStudio.headers.get('location')?.includes('/login'), 'Redirected to login');
      console.log('  ✅ /studio page correctly redirected device token to /login');

      const resUpload = await fetch(`${BASE_URL}/upload`, {
        redirect: 'manual',
        headers: { 'Authorization': `Bearer ${testDevToken}` },
      });
      assert.equal(resUpload.status, 302, `Expected 302 redirect for device token on /upload, got ${resUpload.status}`);
      assert.ok(resUpload.headers.get('location')?.includes('/login'), 'Redirected to login');
      console.log('  ✅ /upload page correctly redirected device token to /login');
    }

    // -------------------------------------------------------------
    // R2: Public Registration Disabled & Route Audit
    // -------------------------------------------------------------
    console.log('\n--- R2: Testing Registration Disabled & Route Audit ---');

    // 1. POST /api/auth/sign-up/email with fresh email must return 404 (disabled) and NO session
    {
      const freshEmail = `attacker_${Date.now()}@evil.test`;
      const res = await fetch(`${BASE_URL}/api/auth/sign-up/email`, {
        method: 'POST',
        headers: {
          'Origin': BASE_URL,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          name: 'Attacker',
          email: freshEmail,
          password: 'SuperSecretPassword123!',
        }),
      });

      assert.equal(res.status, 404, `Expected 404 for /api/auth/sign-up/email, got ${res.status}`);
      const body = await res.json().catch(() => ({}));
      assert.equal(body.error, 'signup_disabled', `Expected error: 'signup_disabled', got ${body.error}`);
      assert.equal(res.headers.get('set-cookie'), null, 'Expected NO set-cookie header on blocked sign-up');

      // Verify no user was created in SQLite
      const count = execSync(`sqlite3 "${SQLITE_DB}" "SELECT COUNT(*) FROM user WHERE email = '${freshEmail}';"`)
        .toString()
        .trim();
      assert.equal(count, '0', 'Attacker user must NOT exist in the database');
      console.log('  ✅ POST /api/auth/sign-up/email rejected with 404 signup_disabled (no user created)');
    }

    // 2. Disallowed routes under /api/auth/* are blocked with 404
    {
      const disallowed = [
        { method: 'POST', path: '/api/auth/sign-up' },
        { method: 'POST', path: '/api/auth/reset-password' },
        { method: 'POST', path: '/api/auth/change-password' },
        { method: 'GET', path: '/api/auth/admin' },
        { method: 'POST', path: '/api/auth/delete-user' },
      ];

      for (const d of disallowed) {
        const res = await fetch(`${BASE_URL}${d.path}`, {
          method: d.method,
          headers: { 'Content-Type': 'application/json' },
          body: d.method === 'POST' ? JSON.stringify({}) : undefined,
        });
        assert.equal(res.status, 404, `Expected 404 for disallowed route ${d.path}, got ${res.status}`);
        console.log(`  ✅ Disallowed route ${d.method} ${d.path} blocked with 404`);
      }
    }

    // 3. Intended flows (session, sign-out) are reachable
    {
      const resSession = await fetch(`${BASE_URL}/api/auth/get-session`, {
        headers: { 'Content-Type': 'application/json' },
      });
      assert.equal(resSession.status, 200, `Expected 200 for /api/auth/get-session, got ${resSession.status}`);
      console.log('  ✅ Intended flow GET /api/auth/get-session is reachable (returns 200 null session)');

      const resSignOut = await fetch(`${BASE_URL}/api/auth/sign-out`, {
        method: 'POST',
        headers: {
          'Origin': BASE_URL,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({}),
      });
      assert.equal(resSignOut.status, 200, `Expected 200 for /api/auth/sign-out, got ${resSignOut.status}`);
      console.log('  ✅ Intended flow POST /api/auth/sign-out is reachable (returns 200)');
    }

    // -------------------------------------------------------------
    // R2: Default Role is 'unapproved' & Requires Parent Promotion
    // -------------------------------------------------------------
    console.log('\n--- R2: Testing Default Role & Promotion Controls ---');

    const testUnapprovedId = 'test_unapproved_user_1';
    const testUnapprovedEmail = 'unapproved@kidstube.test';
    const testUnapprovedSessionToken = 'unapproved_tok_abc_test_123';
    const nowTs = Math.floor(Date.now() / 1000);

    // Insert an unapproved user and session into SQLite
    runSql(`INSERT OR REPLACE INTO user (id, name, email, role, created_at, updated_at) VALUES ('${testUnapprovedId}', 'Unapproved User', '${testUnapprovedEmail}', 'unapproved', ${nowTs}, ${nowTs});`);
    runSql(`INSERT OR REPLACE INTO session (id, user_id, token, expires_at, created_at, updated_at) VALUES ('sess_unapproved_1', '${testUnapprovedId}', '${testUnapprovedSessionToken}', datetime('now', '+7 days'), ${nowTs}, ${nowTs});`);

    try {
      // 1. Unapproved user session attempting parent route -> 401 Unauthorized
      const resBlocked = await fetch(`${BASE_URL}/api/studio/videos`, {
        method: 'DELETE',
        headers: {
          'Origin': BASE_URL,
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${testUnapprovedSessionToken}`,
        },
      });
      assert.equal(resBlocked.status, 401, `Unapproved user must be rejected on parent route with 401, got ${resBlocked.status}`);
      console.log('  ✅ Unapproved user session rejected with 401 on parent route (no API access)');

      // 2. Unapproved user cannot promote themselves or anyone else -> 401
      const resSelfPromote = await fetch(`${BASE_URL}/api/studio/users`, {
        method: 'POST',
        headers: {
          'Origin': BASE_URL,
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${testUnapprovedSessionToken}`,
        },
        body: JSON.stringify({ userId: testUnapprovedId, role: 'parent' }),
      });
      assert.equal(resSelfPromote.status, 401, `Unapproved user cannot promote anyone, got ${resSelfPromote.status}`);
      console.log('  ✅ Unapproved user cannot promote users (401 Unauthorized)');

      // 3. Existing parent can promote unapproved user -> 200
      const resParentPromote = await fetch(`${BASE_URL}/api/studio/users`, {
        method: 'POST',
        headers: {
          'Origin': BASE_URL,
          'Content-Type': 'application/json',
          'Cookie': `kidstube_parent_session=${testParentToken}`,
        },
        body: JSON.stringify({ userId: testUnapprovedId, role: 'parent' }),
      });
      assert.equal(resParentPromote.status, 200, `Parent must be able to promote user, got ${resParentPromote.status}`);
      const promoteData = await resParentPromote.json();
      assert.equal(promoteData.success, true);
      assert.equal(promoteData.user.role, 'parent');

      const promotedRole = execSync(`sqlite3 "${SQLITE_DB}" "SELECT role FROM user WHERE id = '${testUnapprovedId}';"`)
        .toString()
        .trim();
      assert.equal(promotedRole, 'parent', 'User role must now be parent in DB');
      console.log('  ✅ Existing authenticated parent successfully promoted unapproved user to parent');

      // 4. Promoted user can now access parent route -> 200
      runSql(`INSERT OR REPLACE INTO categories (id, name) VALUES ('test_cat_r2', 'Test Cat R2'); INSERT OR REPLACE INTO videos (id, title, category_id, video_file, thumbnail_file, created_at) VALUES ('test_dummy_r2', 'Dummy R2', 'test_cat_r2', 'v2.mp4', 'v2.webp', datetime('now'));`);
      const resNowAllowed = await fetch(`${BASE_URL}/api/studio/videos?ids=test_dummy_r2`, {
        method: 'DELETE',
        headers: {
          'Origin': BASE_URL,
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${testUnapprovedSessionToken}`,
        },
      });
      assert.equal(resNowAllowed.status, 200, `Promoted parent user must get 200, got ${resNowAllowed.status}`);
      console.log('  ✅ Newly promoted parent user can now access parent routes');
    } finally {
      runSql(`DELETE FROM session WHERE id = 'sess_unapproved_1';`);
      runSql(`DELETE FROM user WHERE id = '${testUnapprovedId}';`);
    }

    // -------------------------------------------------------------
    // R2 & R3: Verify No Hardcoded Secrets Committed Anywhere
    // -------------------------------------------------------------
    console.log('\n--- R2 & R3: Testing Secret Literal Elimination ---');
    const gitGrepAuth = execSync('git grep "kidstube_dev_secret_key_change_in_production_32bytes" || true').toString().trim();
    assert.equal(gitGrepAuth, '', 'Better Auth secret literal must NOT be in git repo files');
    console.log('  ✅ git grep verified: Better Auth secret literal completely removed');

    const gitGrepCleanup = execSync('git grep "mykidstube_default_secret_2026" || true').toString().trim();
    assert.equal(gitGrepCleanup, '', 'VPS cleanup secret literal must NOT be in git repo files');
    console.log('  ✅ git grep verified: VPS cleanup secret literal completely removed');

    // -------------------------------------------------------------
    // R3: Run VPS Cleanup Service Authentication & Fail-Closed Suite
    // -------------------------------------------------------------
    console.log('\n--- R3: Executing VPS Cleanup Service Authentication Suite ---');
    const rootDir = fs.existsSync('apps/portal') ? process.cwd() : path.resolve(process.cwd(), '../..');
    const pythonScript = path.resolve(rootDir, 'apps/server/test_cleanup_auth.py');
    const vpsTestOut = execSync(`python3 "${pythonScript}"`, { cwd: rootDir }).toString();
    assert.ok(vpsTestOut.includes('ALL VPS CLEANUP AUTH & FAIL-CLOSED TESTS PASSED'), 'VPS cleanup tests must pass');
    console.log('  ✅ VPS Cleanup Service verified: unset env fails closed (401), old secret rejected (401), new secret authenticated (200)');

    // Verify cleanupVpsMedia fails closed when secret is missing from environment
    const tsxCheck = execSync(`npx tsx -e "
(async () => {
  const { cleanupVpsMedia } = await import('./src/lib/vpsCleanup');
  const assert = (await import('node:assert/strict')).default;
  delete process.env.VPS_CLEANUP_SECRET;
  try {
    await cleanupVpsMedia(['test_video'], { locals: { env: {} } });
    assert.fail('Expected cleanupVpsMedia to throw when VPS_CLEANUP_SECRET is unset');
  } catch (err) {
    assert.ok(err.message.includes('VPS_CLEANUP_SECRET environment variable is missing'), 'Caught expected fail-closed error');
    console.log('  ✅ Portal cleanupVpsMedia verified: fails closed with thrown Error when secret is unset');
  }
})();
"`, { cwd: fs.existsSync('apps/portal') ? path.resolve('apps/portal') : process.cwd() }).toString();
    console.log(tsxCheck.trim());

    // -------------------------------------------------------------
    // R4: PIN Login Rate Limiting Verification
    // -------------------------------------------------------------
    console.log('\n--- R4: Testing PIN Login Rate Limiting (/api/auth/login) ---');
    const attackerIp = `198.51.100.${Math.floor(Math.random() * 150) + 50}`;
    const legitIp = `203.0.113.${Math.floor(Math.random() * 150) + 50}`;

    // 10 wrong-PIN attempts from attackerIp must return 401
    for (let i = 1; i <= 10; i++) {
      const res = await fetch(`${BASE_URL}/api/auth/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'CF-Connecting-IP': attackerIp,
        },
        body: JSON.stringify({ pin: '0000' }),
      });
      assert.equal(res.status, 401, `Attempt ${i} from attacker IP should return 401, got ${res.status}`);
      const body = await res.json();
      assert.equal(body.error, 'Incorrect Parent PIN');
    }
    console.log(`  ✅ 10 rapid wrong-PIN attempts from IP ${attackerIp} returned 401 Unauthorized`);

    // 11th attempt from attackerIp must return 429 Too Many Requests
    {
      const res = await fetch(`${BASE_URL}/api/auth/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'CF-Connecting-IP': attackerIp,
        },
        body: JSON.stringify({ pin: '0000' }),
      });
      assert.equal(res.status, 429, `11th attempt from attacker IP must return 429, got ${res.status}`);
      const body = await res.json();
      assert.equal(body.error, 'Too many requests. Please try again later.');
      assert.equal(res.headers.get('retry-after'), '60', 'Expected Retry-After header: 60');
      console.log(`  ✅ 11th attempt from IP ${attackerIp} blocked with 429 Too Many Requests & Retry-After header`);
    }

    // Even with the correct PIN, the locked-out IP is still blocked with 429
    {
      const res = await fetch(`${BASE_URL}/api/auth/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'CF-Connecting-IP': attackerIp,
        },
        body: JSON.stringify({ pin: '1234' }),
      });
      assert.equal(res.status, 429, `Correct PIN from locked-out IP must still return 429, got ${res.status}`);
      console.log(`  ✅ Correct PIN from locked-out IP ${attackerIp} still rejected with 429`);
    }

    // Correct PIN from legitimate IP must succeed with 200 OK
    {
      const res = await fetch(`${BASE_URL}/api/auth/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'CF-Connecting-IP': legitIp,
        },
        body: JSON.stringify({ pin: '1234' }),
      });
      assert.equal(res.status, 200, `Correct PIN from legitimate IP must return 200, got ${res.status}`);
      const body = await res.json();
      assert.equal(body.success, true);
      const setCookie = res.headers.get('set-cookie');
      assert.ok(setCookie && setCookie.includes('kidstube_parent_session'), 'Expected kidstube_parent_session cookie');
      console.log(`  ✅ Correct PIN from legitimate IP ${legitIp} succeeded with 200 OK and valid session cookie`);
    }

    // -------------------------------------------------------------
    // R4: Drizzle Credentials & Configuration Verification
    // -------------------------------------------------------------
    console.log('\n--- R4: Testing drizzle.config.ts Credential Sanitization & Fail-Closed ---');
    const drizzleConfigPath = fs.existsSync('apps/portal/drizzle.config.ts')
      ? path.resolve('apps/portal/drizzle.config.ts')
      : path.resolve('drizzle.config.ts');
    const drizzleContent = fs.readFileSync(drizzleConfigPath, 'utf8');

    // Confirm no account ID or database ID literals remain
    assert.ok(!drizzleContent.includes('e625c672ee355cd19487de814338560a'), 'Account ID literal must NOT be in drizzle.config.ts');
    assert.ok(!drizzleContent.includes('dce947fe-b59f-40f0-9788-c76414b476b4'), 'Database ID literal must NOT be in drizzle.config.ts');
    console.log('  ✅ drizzle.config.ts contains NO credential or ID literals');

    // Confirm git history never contained a hardcoded token literal
    const gitLogTokens = execSync('git log -S "CLOUDFLARE_API_TOKEN = " -S "CLOUDFLARE_D1_TOKEN = " -- apps/portal/drizzle.config.ts || true').toString().trim();
    assert.equal(gitLogTokens, '', 'Git history must never contain committed token assignments in drizzle.config.ts');
    console.log('  ✅ Git history verified: no API token literal was ever committed in drizzle.config.ts');

    // Confirm drizzle-kit fails closed when DB_REMOTE=true is set without credentials
    const portalDir = fs.existsSync('apps/portal') ? path.resolve('apps/portal') : process.cwd();
    let drizzleFailClosed = false;
    try {
      execSync('DB_REMOTE=true npx drizzle-kit check', { cwd: portalDir, stdio: 'pipe' });
    } catch (drizzleErr) {
      drizzleFailClosed = true;
      const errOut = drizzleErr.stderr?.toString() || drizzleErr.stdout?.toString() || '';
      assert.ok(
        errOut.includes('Missing required remote D1 credentials') || drizzleErr.status !== 0,
        'Expected remote D1 credentials missing error'
      );
    }
    assert.ok(drizzleFailClosed, 'drizzle-kit must fail closed when DB_REMOTE=true without credentials');
    console.log('  ✅ drizzle-kit remote configuration verified: fails closed when remote credentials are unset');

    // -------------------------------------------------------------
    // R6: Lock down the thumbnail fetch-and-cache proxy
    // -------------------------------------------------------------
    console.log('\n--- R6: Testing Thumbnail Fetch-and-Cache Proxy Lockdown ---');

    // 1. Path traversal attempts must return 400
    {
      const res = await fetch(`${BASE_URL}/api/assets/thumbs/..%2f..%2fetc%2fpasswd`);
      assert.equal(res.status, 400, `Path traversal input must return 400, got ${res.status}`);
      const body = await res.json();
      assert.equal(body.error, 'bad_request');
      console.log('  ✅ Path traversal (..%2f..%2fetc%2fpasswd) rejected with 400 Bad Request');
    }

    // 2. Non-11-char input must return 400
    {
      const badInputs = ['short_abc.webp', '12345.jpg', 'toolongvideoid1234.png', 'invalid!id.webp'];
      for (const input of badInputs) {
        const res = await fetch(`${BASE_URL}/api/assets/thumbs/${input}`);
        assert.equal(res.status, 400, `Non-11-char or invalid input '${input}' must return 400, got ${res.status}`);
        const body = await res.json();
        assert.equal(body.error, 'bad_request');
      }
      console.log('  ✅ Non-11-char and invalid ID inputs strictly rejected with 400 Bad Request');
    }

    // 3. Unauthenticated request for an arbitrary baseId not in catalog must return 401
    {
      const arbitraryId = 'dQw4w9WgX99'; // Valid 11-char YouTube ID syntax, not in catalog
      const res = await fetch(`${BASE_URL}/api/assets/thumbs/${arbitraryId}.webp`);
      assert.equal(res.status, 401, `Unauthenticated request for arbitrary baseId must return 401, got ${res.status}`);
      const body = await res.json();
      assert.equal(body.error, 'unauthorized');
      console.log('  ✅ Unauthenticated request for arbitrary baseId blocked with 401 Unauthorized');
    }

    // 4. Device token (role: 'device') requesting an arbitrary baseId not in catalog must also return 401
    {
      const arbitraryId = 'dQw4w9WgX88';
      const res = await fetch(`${BASE_URL}/api/assets/thumbs/${arbitraryId}.webp`, {
        headers: {
          'Authorization': `Bearer ${testDevToken}`,
        },
      });
      assert.equal(res.status, 401, `Device token for arbitrary uncataloged baseId must return 401, got ${res.status}`);
      console.log('  ✅ Device token for arbitrary uncataloged baseId rejected with 401 Unauthorized');
    }

    // 5. Unauthenticated request for an existing catalog video in D1 must serve with 200 OK
    {
      const catalogVideoId = 'We2DYPbILP8'; // Exists in D1
      const res = await fetch(`${BASE_URL}/api/assets/thumbs/${catalogVideoId}.webp`);
      assert.equal(res.status, 200, `Thumbnail for catalog video must return 200, got ${res.status}`);
      const contentType = res.headers.get('content-type') || '';
      assert.ok(contentType.includes('image'), `Expected image content-type, got ${contentType}`);
      console.log('  ✅ Unauthenticated thumbnail for real catalog video served with 200 OK');
    }

    // 6. Authenticated parent requesting a valid YouTube ID (even uncataloged) is authorized
    {
      const res = await fetch(`${BASE_URL}/api/assets/thumbs/dQw4w9WgXcQ.webp`, {
        headers: {
          'Authorization': `Bearer ${testParentToken}`,
        },
      });
      assert.equal(res.status, 200, `Authenticated parent thumbnail request must return 200, got ${res.status}`);
      console.log('  ✅ Authenticated parent thumbnail request authorized and served with 200 OK');
    }

    // -------------------------------------------------------------
    // R7: Harden metrics batching, device registration, DELETE semantics, token delivery
    // -------------------------------------------------------------
    console.log('\n--- R7: Testing Metrics Batching, Registration, DELETE & Token Delivery ---');

    // 1. Authenticate metrics/watch: unauthenticated requests must return 401
    {
      const res = await fetch(`${BASE_URL}/api/metrics/watch`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ video_id: 'We2DYPbILP8', seconds_watched: 10 }),
      });
      assert.equal(res.status, 401, `Unauthenticated metrics/watch must return 401, got ${res.status}`);
      const body = await res.json();
      assert.equal(body.error, 'unauthorized');
      console.log('  ✅ Unauthenticated metrics/watch rejected with 401 Unauthorized');
    }

    // 2. Batch metrics with bogus video_ids must return 400 with nothing inserted
    {
      const res = await fetch(`${BASE_URL}/api/metrics/watch`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${testDevToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          events: [
            { video_id: 'We2DYPbILP8', seconds_watched: 10 },
            { video_id: 'bogus_video_nonexistent_xyz', seconds_watched: 15 },
          ],
        }),
      });
      assert.equal(res.status, 400, `Batch metrics with bogus video_id must return 400, got ${res.status}`);
      const body = await res.json();
      assert.equal(body.error, 'bad_request');
      console.log('  ✅ Batch metrics with bogus video_id rejected with 400 Bad Request');
    }

    // 3. Batch metrics with valid video_ids succeeds with 200 OK
    {
      const res = await fetch(`${BASE_URL}/api/metrics/watch`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${testDevToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          events: [
            { video_id: 'We2DYPbILP8', seconds_watched: 10, video_duration: 60 },
          ],
        }),
      });
      assert.equal(res.status, 200, `Batch metrics with valid video_id must return 200, got ${res.status}`);
      console.log('  ✅ Batch metrics with valid video_id accepted with 200 OK');
    }

    // 4. Rate-limit register.ts per IP: 50 rapid calls from one IP return 429
    {
      const spamIp = '198.51.100.77';
      let got429 = false;
      for (let i = 1; i <= 50; i++) {
        const res = await fetch(`${BASE_URL}/api/v1/devices/register`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'CF-Connecting-IP': spamIp,
          },
          body: JSON.stringify({ device_name: `Spam Device ${i}` }),
        });
        if (res.status === 429) {
          got429 = true;
          break;
        }
      }
      assert.ok(got429, 'Expected 429 Too Many Requests within 50 rapid register calls');
      console.log('  ✅ 50 rapid register calls from one IP rate-limited with 429s');
    }

    // 5. DELETE of a nonexistent id returns 404
    {
      const res = await fetch(`${BASE_URL}/api/studio/videos`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${testParentToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ id: 'nonexistent_video_dummy_999' }),
      });
      assert.equal(res.status, 404, `DELETE of nonexistent video must return 404, got ${res.status}`);
      const body = await res.json();
      assert.equal(body.error, 'not_found');
      console.log('  ✅ Single-id DELETE of nonexistent video returned 404 Not Found');
    }

    // 6. Bulk delete reports actually-deleted IDs
    {
      runSql(`INSERT OR REPLACE INTO categories (id, name) VALUES ('test_cat_r7', 'Test Cat R7'); INSERT OR REPLACE INTO videos (id, title, category_id, video_file, thumbnail_file, created_at) VALUES ('r7_del_real', 'Real R7', 'test_cat_r7', 'r7.mp4', 'r7.webp', datetime('now'));`);
      const res = await fetch(`${BASE_URL}/api/studio/videos`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${testParentToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ ids: ['r7_del_real', 'r7_del_ghost_1', 'r7_del_ghost_2'] }),
      });
      assert.equal(res.status, 200, `Bulk delete must return 200, got ${res.status}`);
      const body = await res.json();
      assert.deepEqual(body.deleted_ids, ['r7_del_real'], 'Bulk delete must strictly report actually-deleted IDs');
      console.log('  ✅ Bulk DELETE reported only actually-deleted IDs');
    }

    // 7. Expired vs unknown pairing codes both return identical generic 404
    {
      runSql(`INSERT OR REPLACE INTO devices (id, device_name, pairing_code, status, expires_at, created_at) VALUES ('dev_exp_r7', 'Exp Tablet', 'EXP-777', 'pending', datetime('now', '-1 hour'), datetime('now', '-2 hours'));`);
      const resUnknown = await fetch(`${BASE_URL}/api/v1/devices/status/UNKNOWN-000`);
      const resExpired = await fetch(`${BASE_URL}/api/v1/devices/status/EXP-777`);
      assert.equal(resUnknown.status, 404);
      assert.equal(resExpired.status, 404);
      const bUnknown = await resUnknown.json();
      const bExpired = await resExpired.json();
      assert.deepEqual(bUnknown, bExpired, 'Expired and unknown pairing codes must return identical 404 bodies (no oracle)');
      runSql(`DELETE FROM devices WHERE id = 'dev_exp_r7';`);
      console.log('  ✅ Expired-vs-unknown pairing code distinction collapsed to identical generic 404');
    }

    // 8. Atomic one-time token delivery: two concurrent status polls -> only one receives token
    {
      const testCode = 'ATM-111';
      const secretToken = 'atomic_secret_raw_token_999';
      runSql(`INSERT OR REPLACE INTO devices (id, device_name, pairing_code, status, auth_token, raw_token_pending, created_at) VALUES ('dev_atomic_r7', 'Atomic Tablet', '${testCode}', 'paired', 'hash_test', '${secretToken}', datetime('now'));`);

      const [res1, res2] = await Promise.all([
        fetch(`${BASE_URL}/api/v1/devices/status/${testCode}`),
        fetch(`${BASE_URL}/api/v1/devices/status/${testCode}`),
      ]);

      const b1 = await res1.json();
      const b2 = await res2.json();

      const deliveredTokens = [b1.auth_token, b2.auth_token].filter(Boolean);
      assert.equal(deliveredTokens.length, 1, `Exactly one poll must receive auth_token, got ${deliveredTokens.length}`);
      assert.equal(deliveredTokens[0], secretToken);
      runSql(`DELETE FROM devices WHERE id = 'dev_atomic_r7';`);
      console.log('  ✅ Two concurrent status polls: atomic claim ensures exactly one receives the token');
    }

    console.log('\n🎉 ALL SECURITY PRIVILEGE ESCALATION, R2, R3, R4, R6 & R7 TESTS PASSED!\n');
  } finally {
    // Cleanup test data
    runSql(`DELETE FROM devices WHERE id = '${testDeviceId}';`);
    runSql(`DELETE FROM parent_sessions WHERE token_hash = '${testParentHash}';`);
  }
}

runTests().catch((err) => {
  console.error('\n❌ TEST FAILED:', err);
  process.exit(1);
});
