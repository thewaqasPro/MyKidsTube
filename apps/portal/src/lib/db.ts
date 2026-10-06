import type { Video, Category, ChildProfile } from '../types/video';
import { API_BASE } from './constants';

export async function getDbData() {
  try {
    const { env } = await import('cloudflare:workers');
    const db = (env as any)?.DB;

    if (db) {
      const [vRes, cRes, pRes] = await Promise.all([
        db.prepare('SELECT * FROM videos ORDER BY created_at DESC').all(),
        db.prepare('SELECT * FROM categories ORDER BY display_order ASC').all(),
        db.prepare('SELECT * FROM child_profiles').all(),
      ]);

      return {
        source: 'cloudflare-d1',
        videos: (vRes.results as unknown as Video[]) || [],
        categories: (cRes.results as unknown as Category[]) || [],
        profiles: (pRes.results as unknown as ChildProfile[]) || [],
      };
    }
  } catch {
    // Expected when running outside Cloudflare Workers (e.g. local node build)
  }

  // Fallback to backend API
  try {
    const [catRes, profRes] = await Promise.all([
      fetch(`${API_BASE}/api/v1/catalog`),
      fetch(`${API_BASE}/api/v1/profiles`).catch(() => null),
    ]);

    let videos: Video[] = [];
    let categories: Category[] = [];
    let profiles: ChildProfile[] = [];

    if (catRes.ok) {
      const catData = await catRes.json();
      videos = catData.all_videos || [];
      categories = catData.sections?.map((s: any) => s.category) || [];
    }

    if (profRes && profRes.ok) {
      profiles = await profRes.json();
    }

    return { source: 'backend-api', videos, categories, profiles };
  } catch (e) {
    console.error('Fallback fetch error:', e);
    return { source: 'error', videos: [], categories: [], profiles: [] };
  }
}
