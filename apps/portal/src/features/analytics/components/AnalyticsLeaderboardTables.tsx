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
      <div className="p-6 bg-[#181818] border border-[#262626] rounded-2xl shadow-sm">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <Flame className="w-4 h-4 text-[#FF0000]" />
            <h2 className="text-[15px] font-bold text-white uppercase tracking-wider">
              Content Kids Love Most
            </h2>
          </div>
          <span className="text-[11px] text-emerald-400 font-semibold bg-emerald-950/40 border border-emerald-800/40 px-2 py-0.5 rounded">
            High Completion & Replays
          </span>
        </div>

        {lovedVideos.length === 0 ? (
          <p className="text-[13px] text-[#666] py-8 text-center">No repeat viewing patterns recorded yet.</p>
        ) : (
          <div className="divide-y divide-[#222222]">
            {lovedVideos.map((video, idx) => (
              <div key={idx} className="py-3 flex items-center gap-3">
                <span className="text-[13px] font-black text-[#555] w-5 text-center">
                  #{idx + 1}
                </span>
                <img
                  src={getThumbnailUrl(video.thumbnail_file, video.video_id)}
                  alt=""
                  className="w-14 h-9 object-cover rounded-lg bg-black"
                />
                <div className="flex-1 min-w-0">
                  <p className="text-[13px] font-medium text-white truncate">{video.title}</p>
                  <p className="text-[11px] text-[#777] flex items-center gap-2">
                    <span>{video.channel_name || 'KidsTube'}</span>
                    <span>•</span>
                    <span className="text-emerald-400 font-semibold">{video.completion_pct}% finished</span>
                  </p>
                </div>
                <div className="text-right">
                  <span className="text-[13px] font-bold text-white block">{video.play_count} plays</span>
                  <span className="text-[11px] text-[#777]">{Math.round(video.total_seconds / 60)}m spent</span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Videos Passed Quickly */}
      <div className="p-6 bg-[#181818] border border-[#262626] rounded-2xl shadow-sm">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <ThumbsDown className="w-4 h-4 text-rose-400" />
            <h2 className="text-[15px] font-bold text-white uppercase tracking-wider">
              Passed Quickly (&lt; 10s Skips)
            </h2>
          </div>
          <span className="text-[11px] text-rose-400 font-semibold bg-rose-950/40 border border-rose-800/40 px-2 py-0.5 rounded">
            Lost Interest Fast
          </span>
        </div>

        {skippedVideos.length === 0 ? (
          <p className="text-[13px] text-[#666] py-8 text-center">No fast skips detected. Kids are engaged!</p>
        ) : (
          <div className="divide-y divide-[#222222]">
            {skippedVideos.map((video, idx) => (
              <div key={idx} className="py-3 flex items-center gap-3">
                <span className="text-[13px] font-black text-rose-500/70 w-5 text-center">
                  &times;
                </span>
                <img
                  src={getThumbnailUrl(video.thumbnail_file, video.video_id)}
                  alt=""
                  className="w-14 h-9 object-cover rounded-lg bg-black opacity-80"
                />
                <div className="flex-1 min-w-0">
                  <p className="text-[13px] font-medium text-white truncate">{video.title}</p>
                  <p className="text-[11px] text-[#777] flex items-center gap-2">
                    <span className="text-rose-400 font-semibold">{video.skip_count} quick skips</span>
                    <span>•</span>
                    <span>left at ~{video.avg_seconds_before_skip}s</span>
                  </p>
                </div>
                <div className="text-right">
                  <span className="text-[11px] font-bold text-rose-400/90 block">
                    {video.skip_pct}% bounce
                  </span>
                  <span className="text-[10px] text-[#666]">Consider pruning</span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};
