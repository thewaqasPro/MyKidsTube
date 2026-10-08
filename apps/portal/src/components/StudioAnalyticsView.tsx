import React, { useState, useEffect } from 'react';
import {
  Tv,
  Users,
  Calendar,
  RefreshCw,
} from 'lucide-react';
import { AnalyticsKpiGrid } from '@/features/analytics/components/AnalyticsKpiGrid';
import { AnalyticsTrendChart } from '@/features/analytics/components/AnalyticsTrendChart';
import { AnalyticsRetentionFunnel } from '@/features/analytics/components/AnalyticsRetentionFunnel';
import { AnalyticsLeaderboardTables } from '@/features/analytics/components/AnalyticsLeaderboardTables';

interface StudioAnalyticsViewProps {
  initialProfiles?: any[];
}

export const StudioAnalyticsView: React.FC<StudioAnalyticsViewProps> = ({ initialProfiles = [] }) => {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Filters
  const [selectedDevice, setSelectedDevice] = useState<string>('all');
  const [selectedProfile, setSelectedProfile] = useState<string>('all');
  const [selectedRange, setSelectedRange] = useState<string>('7d');

  const fetchAnalytics = async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch(
        `/api/studio/analytics?device_id=${selectedDevice}&profile_id=${selectedProfile}&range=${selectedRange}`
      );
      if (!res.ok) throw new Error('Failed to load analytics');
      const json = await res.json();
      setData(json);
    } catch (err: any) {
      setError(err?.message || 'Error loading analytics');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAnalytics();
  }, [selectedDevice, selectedProfile, selectedRange]);

  const summary = data?.summary || {};
  const timeSeries = data?.time_series || [];
  const categoryShares = data?.category_shares || [];
  const lovedVideos = data?.loved_videos || [];
  const skippedVideos = data?.skipped_videos || [];
  const retentionFunnel = data?.retention_funnel || [];
  const devices = data?.devices || [];
  const profiles = data?.profiles || initialProfiles;

  return (
    <div className="space-y-6">
      {/* Header and Filter Toolbar */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 p-6 bg-surface border-2 border-border rounded-[32px] shadow-xl">
        <div>
          <div className="flex items-center gap-2.5">
            <h1 className="text-xl sm:text-2xl font-display font-black text-white tracking-wide">Kid Viewing & Retention Intelligence</h1>
            <span className="px-3 py-1 text-xs font-black bg-coral/15 text-coral rounded-full border border-coral/30">
              PER-DEVICE & PER-USER
            </span>
          </div>
          <p className="text-xs text-text-secondary mt-1 font-medium">
            Track which videos each child loves versus what they skip quickly within 10 seconds.
          </p>
        </div>

        {/* Filter Bar Controls */}
        <div className="flex flex-wrap items-center gap-2.5">
          {/* Device Selector */}
          <div className="flex items-center gap-1.5 px-3.5 py-2 bg-canvas-deep border-2 border-border rounded-2xl text-xs font-bold">
            <Tv className="w-3.5 h-3.5 text-sky" />
            <select
              value={selectedDevice}
              onChange={(e) => setSelectedDevice(e.target.value)}
              className="bg-transparent text-white outline-none cursor-pointer pr-1"
            >
              <option value="all" className="bg-surface text-white">All Devices</option>
              {devices.map((d: any) => (
                <option key={d.id} value={d.id} className="bg-surface text-white">
                  {d.device_name || d.id}
                </option>
              ))}
            </select>
          </div>

          {/* Kid Profile Selector */}
          <div className="flex items-center gap-1.5 px-3.5 py-2 bg-canvas-deep border-2 border-border rounded-2xl text-xs font-bold">
            <Users className="w-3.5 h-3.5 text-mint" />
            <select
              value={selectedProfile}
              onChange={(e) => setSelectedProfile(e.target.value)}
              className="bg-transparent text-white outline-none cursor-pointer pr-1"
            >
              <option value="all" className="bg-surface text-white">All Kids</option>
              {profiles.map((p: any) => (
                <option key={p.id} value={p.id} className="bg-surface text-white">
                  {p.name} ({p.age_bracket || 'kid'})
                </option>
              ))}
            </select>
          </div>

          {/* Time Range Selector */}
          <div className="flex items-center gap-1.5 px-3.5 py-2 bg-canvas-deep border-2 border-border rounded-2xl text-xs font-bold">
            <Calendar className="w-3.5 h-3.5 text-violet" />
            <select
              value={selectedRange}
              onChange={(e) => setSelectedRange(e.target.value)}
              className="bg-transparent text-white outline-none cursor-pointer pr-1"
            >
              <option value="today" className="bg-surface text-white">Today</option>
              <option value="7d" className="bg-surface text-white">Last 7 Days</option>
              <option value="30d" className="bg-surface text-white">Last 30 Days</option>
              <option value="all" className="bg-surface text-white">All Time</option>
            </select>
          </div>

          <button
            onClick={fetchAnalytics}
            disabled={loading}
            className="p-2.5 bg-canvas-deep hover:bg-surface-hover border-2 border-border text-text-secondary hover:text-white rounded-2xl transition-all cursor-pointer"
            title="Refresh Analytics"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      {loading && !data ? (
        <div className="p-16 text-center text-text-secondary flex flex-col items-center justify-center gap-3">
          <RefreshCw className="w-6 h-6 animate-spin text-sky" />
          <span className="font-bold text-xs">Crunching viewing metrics...</span>
        </div>
      ) : error ? (
        <div className="p-6 bg-red-950/20 border border-red-800/40 rounded-2xl text-red-400">
          {error}
        </div>
      ) : (
        <>
          {/* Executive Metric Cards */}
          <AnalyticsKpiGrid summary={summary} />

          {/* Visual Charts: Daily Trend & Attention Funnel */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <AnalyticsTrendChart timeSeries={timeSeries} selectedRange={selectedRange} />
            <AnalyticsRetentionFunnel retentionFunnel={retentionFunnel} categoryShares={categoryShares} />
          </div>

          {/* Tables: Most Loved vs Passed Quickly */}
          <AnalyticsLeaderboardTables lovedVideos={lovedVideos} skippedVideos={skippedVideos} />
        </>
      )}
    </div>
  );
};
