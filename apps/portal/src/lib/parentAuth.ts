import { getDatabase } from './db';

export const PARENT_SESSION_COOKIE_NAME = 'kidstube_parent_session';
export const SESSION_MAX_AGE_SECONDS = 86400; // 24 hours

export async function hashToken(token: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(token);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');
}

export function extractSessionToken(request: Request): string | null {
  const authHeader = request.headers.get('authorization') || '';
  if (authHeader.toLowerCase().startsWith('bearer ')) {
    const token = authHeader.substring(7).trim();
    if (token.length > 0) return token;
  }
  const cookieHeader = request.headers.get('cookie') || '';
  const match = cookieHeader.match(new RegExp(`(?:^|;\\s*)${PARENT_SESSION_COOKIE_NAME}=([^;]+)`));
  if (!match) return null;
  const val = decodeURIComponent(match[1].trim());
  return val.length > 0 ? val : null;
}

export function buildSessionCookie(token: string): string {
  return `${PARENT_SESSION_COOKIE_NAME}=${token}; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=${SESSION_MAX_AGE_SECONDS}`;
}

export function buildClearSessionCookie(): string {
  return `${PARENT_SESSION_COOKIE_NAME}=; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=0`;
}

export async function createParentSession(db: any): Promise<string> {
  const randomBytes = new Uint8Array(32);
  crypto.getRandomValues(randomBytes);
  const rawToken = Array.from(randomBytes)
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');

  const tokenHash = await hashToken(rawToken);
  const now = new Date();
  const expiresAt = new Date(now.getTime() + SESSION_MAX_AGE_SECONDS * 1000);

  if (db) {
    try {
      await db
        .prepare('INSERT INTO parent_sessions (token_hash, created_at, expires_at) VALUES (?, ?, ?)')
        .bind(tokenHash, now.toISOString(), expiresAt.toISOString())
        .run();
    } catch (err: any) {
      console.warn('Failed to insert parent session, attempting table auto-heal:', err);
      try {
        await db
          .prepare(
            'CREATE TABLE IF NOT EXISTS parent_sessions (token_hash TEXT PRIMARY KEY, created_at TEXT NOT NULL, expires_at TEXT NOT NULL)'
          )
          .run();
        await db
          .prepare('CREATE INDEX IF NOT EXISTS idx_parent_sessions_expires_at ON parent_sessions (expires_at)')
          .run();
        await db
          .prepare('INSERT INTO parent_sessions (token_hash, created_at, expires_at) VALUES (?, ?, ?)')
          .bind(tokenHash, now.toISOString(), expiresAt.toISOString())
          .run();
      } catch (retryErr: any) {
        console.error('Failed to create parent session in D1 after auto-heal:', retryErr);
        throw new Error('Database error creating session. Ensure migrations are applied.');
      }
    }
  }

  return rawToken;
}

export async function verifyParentSession(request: Request, db: any): Promise<boolean> {
  const token = extractSessionToken(request);
  if (!token) return false;

  // Reject the old static forgeable token
  if (token === 'authenticated') return false;

  if (!db) {
    return false;
  }

  try {
    const tokenHash = await hashToken(token);
    const row: any = await db
      .prepare('SELECT token_hash, expires_at FROM parent_sessions WHERE token_hash = ?')
      .bind(tokenHash)
      .first();

    if (row && row.expires_at) {
      const expiresAt = new Date(row.expires_at).getTime();
      if (expiresAt <= Date.now()) {
        // Clean up expired session in background
        db.prepare('DELETE FROM parent_sessions WHERE token_hash = ?').bind(tokenHash).run().catch(() => null);
        return false;
      }
      return true;
    }

    return false;
  } catch (err) {
    console.error('Error verifying parent session:', err);
    return false;
  }
}

export async function requireParent(context: any): Promise<Response | null> {
  const { requireAuthenticatedParent } = await import('./auth');
  return requireAuthenticatedParent(context);
}

export async function requireDevice(context: any): Promise<Response | null> {
  const { requireAuthenticatedDevice } = await import('./auth');
  return requireAuthenticatedDevice(context);
}

export async function destroyParentSession(request: Request, db: any): Promise<void> {
  const token = extractSessionToken(request);
  if (!token || token === 'authenticated' || !db) return;

  try {
    const tokenHash = await hashToken(token);
    await db.prepare('DELETE FROM parent_sessions WHERE token_hash = ?').bind(tokenHash).run();
  } catch (err) {
    console.error('Error destroying parent session:', err);
  }
}
