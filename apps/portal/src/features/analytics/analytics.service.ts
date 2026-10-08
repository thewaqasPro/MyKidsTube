import type { D1Database } from '@cloudflare/workers-types';

export interface AnalyticsFilterParams {
  deviceId?: string;
  profileId?: string;
  range?: string; // 'today', '7d', '30d', 'all'
}

export class AnalyticsService {
  static async getAnalyticsReport(db: D1Database, params: AnalyticsFilterParams) {
    const deviceId = params.deviceId || 'all';
    const profileId = params.profileId || 'all';
    const range = params.range || '7d';

    // 1. Fetch available Devices and Child Profiles for filter dropdowns
    const [devicesRes, profilesRes] = await Promise.all([
      db.prepare('SELECT id, device_name, status, profile_id FROM devices ORDER BY created_at DESC').all(),
      db.prepare('SELECT id, name, avatar_icon, age_bracket FROM child_profiles ORDER BY name ASC').all(),
    ]);

    const devices = devicesRes.results || [];
    const profiles = profilesRes.results || [];

    // 2. Build SQL filters for watch_events
    const whereClauses: string[] = [];
    const bindArgs: any[] = [];

    if (deviceId !== 'all') {
      whereClauses.push('(w.device_id = ?)');
      bindArgs.push(deviceId);
    }

    if (profileId !== 'all') {
      whereClauses.push('(w.profile_id = ?)');
      bindArgs.push(profileId);
    }

    // Date range filtering
    const now = new Date();
    if (range === 'today') {
      const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate()).toISOString();
      whereClauses.push('(w.event_at >= ?)');
      bindArgs.push(todayStart);
    } else if (range === '7d') {
      const d7 = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString();
      whereClauses.push('(w.event_at >= ?)');
      bindArgs.push(d7);
    } else if (range === '30d') {
      const d30 = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000).toISOString();
      whereClauses.push('(w.event_at >= ?)');
      bindArgs.push(d30);
    }

    const whereSql = whereClauses.length > 0 ? `WHERE ${whereClauses.join(' AND ')}` : '';

    // 3. Aggregate Core Summary Metrics
    const summaryQuery = `
      SELECT 
        COUNT(*) as total_events,
        COALESCE(SUM(w.seconds_watched), 0) as total_seconds,
        COALESCE(SUM(CASE WHEN w.is_completed = 1 THEN 1 ELSE 0 END), 0) as completed_count,
        COALESCE(SUM(CASE WHEN w.is_skipped = 1 THEN 1 ELSE 0 END), 0) as skipped_count,
        COALESCE(SUM(CASE WHEN w.is_completed = 0 AND w.is_skipped = 0 THEN 1 ELSE 0 END), 0) as partial_count
      FROM watch_events w
      ${whereSql}
    `;

    const summaryRes: any = await db.prepare(summaryQuery).bind(...bindArgs).first();
    const totalEvents = Number(summaryRes?.total_events || 0);
    const totalSeconds = Number(summaryRes?.total_seconds || 0);
    const completedCount = Number(summaryRes?.completed_count || 0);
    const skippedCount = Number(summaryRes?.skipped_count || 0);
    const partialCount = Number(summaryRes?.partial_count || 0);

    const completionRate = totalEvents > 0 ? Number(((completedCount / totalEvents) * 100).toFixed(1)) : 0;
    const skipRate = totalEvents > 0 ? Number(((skippedCount / totalEvents) * 100).toFixed(1)) : 0;

    // 4. Daily Time-Series Trend
    const trendQuery = `
      SELECT 
        substr(w.event_at, 1, 10) as day_date,
        COUNT(*) as session_count,
        COALESCE(SUM(w.seconds_watched), 0) as total_seconds
      FROM watch_events w
      ${whereSql}
      GROUP BY day_date
      ORDER BY day_date ASC
      LIMIT 30
    `;
    const trendRes = await db.prepare(trendQuery).bind(...bindArgs).all();
    const trendPoints = (trendRes.results || []).map((r: any) => ({
      date: r.day_date,
      seconds: Number(r.total_seconds || 0),
      sessions: Number(r.session_count || 0),
    }));

    // 5. Category Breakdown
    const categoryQuery = `
      SELECT 
        COALESCE(v.category_id, 'other') as category_id,
        COUNT(w.id) as sessions,
        COALESCE(SUM(w.seconds_watched), 0) as total_seconds
      FROM watch_events w
      LEFT JOIN videos v ON w.video_id = v.id
      ${whereSql}
      GROUP BY category_id
      ORDER BY total_seconds DESC
    `;
    const categoryRes = await db.prepare(categoryQuery).bind(...bindArgs).all();
    const categories = (categoryRes.results || []).map((r: any) => ({
      categoryId: r.category_id,
      seconds: Number(r.total_seconds || 0),
      sessions: Number(r.sessions || 0),
    }));

    // 6. Content Kids Love Most (Top Watched & Completed)
    const lovedQuery = `
      SELECT 
        w.video_id,
        COALESCE(v.title, 'Video ' || w.video_id) as video_title,
        COALESCE(v.thumbnail_file, '') as thumbnail_file,
        COALESCE(v.category_id, 'cartoons') as category_id,
        COALESCE(v.duration, 0) as duration,
        COUNT(w.id) as watch_count,
        COALESCE(SUM(w.seconds_watched), 0) as total_seconds,
        COALESCE(SUM(CASE WHEN w.is_completed = 1 THEN 1 ELSE 0 END), 0) as completed_count,
        COALESCE(SUM(CASE WHEN w.is_skipped = 1 THEN 1 ELSE 0 END), 0) as skip_count
      FROM watch_events w
      LEFT JOIN videos v ON w.video_id = v.id
      ${whereSql}
      GROUP BY w.video_id
      HAVING total_seconds > 20
      ORDER BY completed_count DESC, total_seconds DESC
      LIMIT 10
    `;
    const lovedRes = await db.prepare(lovedQuery).bind(...bindArgs).all();
    const lovedVideos = (lovedRes.results || []).map((r: any) => {
      const views = Number(r.watch_count || 0);
      const comps = Number(r.completed_count || 0);
      return {
        videoId: r.video_id,
        title: r.video_title,
        thumbnailFile: r.thumbnail_file,
        categoryId: r.category_id,
        duration: Number(r.duration || 0),
        views,
        totalSeconds: Number(r.total_seconds || 0),
        completedCount: comps,
        completionRate: views > 0 ? Number(((comps / views) * 100).toFixed(0)) : 0,
      };
    });

    // 7. Passed On Quickly (< 10s skips)
    const skippedQuery = `
      SELECT 
        w.video_id,
        COALESCE(v.title, 'Video ' || w.video_id) as video_title,
        COALESCE(v.thumbnail_file, '') as thumbnail_file,
        COALESCE(v.category_id, 'cartoons') as category_id,
        COALESCE(v.duration, 0) as duration,
        COUNT(w.id) as total_impressions,
        COALESCE(SUM(CASE WHEN w.is_skipped = 1 THEN 1 ELSE 0 END), 0) as skip_count,
        COALESCE(AVG(w.seconds_watched), 0) as avg_abandon_seconds
      FROM watch_events w
      LEFT JOIN videos v ON w.video_id = v.id
      ${whereSql}
      GROUP BY w.video_id
      HAVING skip_count > 0
      ORDER BY skip_count DESC, total_impressions DESC
      LIMIT 10
    `;
    const skippedRes = await db.prepare(skippedQuery).bind(...bindArgs).all();
    const skippedVideos = (skippedRes.results || []).map((r: any) => {
      const imps = Number(r.total_impressions || 0);
      const skips = Number(r.skip_count || 0);
      return {
        videoId: r.video_id,
        title: r.video_title,
        thumbnailFile: r.thumbnail_file,
        categoryId: r.category_id,
        duration: Number(r.duration || 0),
        impressions: imps,
        skipCount: skips,
        skipPercentage: imps > 0 ? Number(((skips / imps) * 100).toFixed(0)) : 0,
        avgAbandonSeconds: Number(Number(r.avg_abandon_seconds || 0).toFixed(1)),
      };
    });

    // 8. Retention Funnel
    const funnelStarted = totalEvents;
    const funnelPast10s = Math.max(0, totalEvents - skippedCount);
    const funnelCompleted = completedCount;

    return {
      summary: {
        totalSeconds,
        totalMinutes: Math.round(totalSeconds / 60),
        totalHours: Number((totalSeconds / 3600).toFixed(1)),
        totalSessions: totalEvents,
        completionRate,
        skipRate,
        completedCount,
        skippedCount,
        partialCount,
      },
      retentionFunnel: {
        started: funnelStarted,
        survived10s: funnelPast10s,
        completed: funnelCompleted,
        survivalRate: funnelStarted > 0 ? Number(((funnelPast10s / funnelStarted) * 100).toFixed(1)) : 0,
        completionRate,
      },
      trend: trendPoints,
      categories,
      lovedVideos,
      skippedVideos,
      filterOptions: {
        devices: devices.map((d: any) => ({
          id: d.id,
          name: d.device_name || 'Kids Device',
          status: d.status,
          profileId: d.profile_id,
        })),
        profiles: profiles.map((p: any) => ({
          id: p.id,
          name: p.name,
          avatar: p.avatar_icon,
          ageBracket: p.age_bracket,
        })),
      },
      currentFilters: {
        deviceId,
        profileId,
        range,
      },
    };
  }
}
