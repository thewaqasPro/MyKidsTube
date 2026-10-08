import React from 'react';
import { Flame, ThumbsDown } from 'lucide-react';
import { getThumbnailUrl } from '@/lib/constants';

interface LovedVideoItem {
  video_id: string;
  thumbnail_file?: string;
  title: string;
  channel_name?: string;
  completion_pct: number;
  play_count: number;
  total_seconds: number;
}

interface SkippedVideoItem {
  video_id: string;
  thumbnail_file?: string;
  title: string;
  channel_name?: string;
  skip_count: number;
  avg_seconds_before_skip: number;
  skip_pct: number;
}

interface AnalyticsLeaderboardTablesProps {
  lovedVideos: LovedVideoItem[];
  skippedVideos: SkippedVideoItem[];
}

export const AnalyticsLeaderboardTables: React.FC<AnalyticsLeaderboardTablesProps> = ({
  lovedVideos = [],
  skippedVideos = [],
}) => {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      {/* Loved Videos */}
      <div className="p-6 sm:p-7 bg-surface border-2 border-border rounded-[32px] shadow-xl">
        <div className="flex items-center justify-between mb-5">
          <div className="flex items-center gap-2.5">
            <Flame className="w-5 h-5 text-coral" />
            <h2 className="text-sm font-display font-black text-text-primary tracking-wide">
              Content Kids Love Most
            </h2>
          </div>
          <span className="text-[11px] text-mint font-bold bg-mint/15 border border-mint/30 px-3 py-1 rounded-full">
            High Completion & Replays
          </span>
        </div>

        {lovedVideos.length === 0 ? (
          <p className="text-xs text-text-secondary py-10 text-center font-medium">No repeat viewing patterns recorded yet.</p>
        ) : (
          <div className="divide-y divide-border">
            {lovedVideos.map((video, idx) => (
              <div key={idx} className="py-3.5 flex items-center gap-3.5">
                <span className="text-xs font-black text-sun w-6 text-center">
                  #{idx + 1}
                </span>
                <img
                  src={getThumbnailUrl(video.thumbnail_file, video.video_id)}
                  alt=""
                  className="w-16 h-10 object-cover rounded-xl bg-black border border-border"
                />
                <div className="flex-1 min-w-0">
                  <p className="text-xs font-bold text-text-primary truncate">{video.title}</p>
                  <p className="text-[11px] text-text-secondary flex items-center gap-2 mt-0.5">
                    <span>{video.channel_name || 'WonderKids'}</span>
                    <span>•</span>
                    <span className="text-mint font-bold">{video.completion_pct}% finished</span>
                  </p>
                </div>
                <div className="text-right">
                  <span className="text-xs font-black text-text-primary block">{video.play_count} plays</span>
                  <span className="text-[10px] text-text-secondary font-mono">{Math.round(video.total_seconds / 60)}m spent</span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Videos Passed Quickly */}
      <div className="p-6 sm:p-7 bg-surface border-2 border-border rounded-[32px] shadow-xl">
        <div className="flex items-center justify-between mb-5">
          <div className="flex items-center gap-2.5">
            <ThumbsDown className="w-5 h-5 text-coral" />
            <h2 className="text-sm font-display font-black text-text-primary tracking-wide">
              Passed Quickly (&lt; 10s Skips)
            </h2>
          </div>
          <span className="text-[11px] text-coral font-bold bg-coral/15 border border-coral/30 px-3 py-1 rounded-full">
            Lost Interest Fast
          </span>
        </div>

        {skippedVideos.length === 0 ? (
          <p className="text-xs text-text-secondary py-10 text-center font-medium">No fast skips detected. Kids are engaged!</p>
        ) : (
          <div className="divide-y divide-border">
            {skippedVideos.map((video, idx) => (
              <div key={idx} className="py-3.5 flex items-center gap-3.5">
                <span className="text-xs font-black text-coral w-6 text-center">
                  &times;
                </span>
                <img
                  src={getThumbnailUrl(video.thumbnail_file, video.video_id)}
                  alt=""
                  className="w-16 h-10 object-cover rounded-xl bg-black border border-border opacity-80"
                />
                <div className="flex-1 min-w-0">
                  <p className="text-xs font-bold text-text-primary truncate">{video.title}</p>
                  <p className="text-[11px] text-text-secondary flex items-center gap-2 mt-0.5">
                    <span className="text-coral font-bold">{video.skip_count} quick skips</span>
                    <span>•</span>
                    <span>left at ~{video.avg_seconds_before_skip}s</span>
                  </p>
                </div>
                <div className="text-right">
                  <span className="text-xs font-bold text-coral block">
                    {video.skip_pct}% bounce
                  </span>
                  <span className="text-[10px] text-text-muted">Consider pruning</span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};
