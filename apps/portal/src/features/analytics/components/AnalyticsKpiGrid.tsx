import React from 'react';
import { Clock, CheckCircle2, AlertTriangle, PlaySquare } from 'lucide-react';

interface AnalyticsKpiGridProps {
  summary: {
    total_hours?: number;
    total_seconds?: number;
    total_events?: number;
    completion_rate?: number;
    completed_count?: number;
    skip_rate?: number;
    skipped_count?: number;
    partial_rate?: number;
    partial_count?: number;
  };
}

export const AnalyticsKpiGrid: React.FC<AnalyticsKpiGridProps> = ({ summary = {} }) => {
  const totalHours = summary.total_hours || 0;
  const totalSeconds = summary.total_seconds || 0;

  return (
    <section className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      {/* Screen Time */}
      <div className="p-5 bg-[#181818] border border-[#262626] rounded-2xl shadow-sm">
        <div className="flex items-center justify-between text-[#888888]">
          <span className="text-[12px] font-semibold uppercase tracking-wider">Screen Time</span>
          <Clock className="w-4 h-4 text-[#3EA6FF]" />
        </div>
        <div className="mt-3">
          <span className="text-[28px] font-extrabold text-white">
            {totalHours >= 1
              ? `${totalHours} hrs`
              : `${Math.round(totalSeconds / 60)} mins`}
          </span>
        </div>
        <div className="mt-2 text-[12px] text-[#888888]">
          {summary.total_events || 0} viewing sessions logged
        </div>
      </div>

      {/* Completion Rate */}
      <div className="p-5 bg-[#181818] border border-[#262626] rounded-2xl shadow-sm">
        <div className="flex items-center justify-between text-[#888888]">
          <span className="text-[12px] font-semibold uppercase tracking-wider">Captured Attention</span>
          <CheckCircle2 className="w-4 h-4 text-emerald-400" />
        </div>
        <div className="mt-3">
          <span className="text-[28px] font-extrabold text-emerald-400">
            {summary.completion_rate || 0}%
          </span>
          <span className="text-[12px] text-[#888888] ml-2">Completed ({summary.completed_count || 0})</span>
        </div>
        <div className="mt-2 text-[12px] text-[#888888]">
          Videos watched through &ge; 75%
        </div>
      </div>

      {/* Quick Pass Rate */}
      <div className="p-5 bg-[#181818] border border-[#262626] rounded-2xl shadow-sm">
        <div className="flex items-center justify-between text-[#888888]">
          <span className="text-[12px] font-semibold uppercase tracking-wider">Quick Pass / Bounce</span>
          <AlertTriangle className="w-4 h-4 text-rose-400" />
        </div>
        <div className="mt-3">
          <span className="text-[28px] font-extrabold text-rose-400">
            {summary.skip_rate || 0}%
          </span>
          <span className="text-[12px] text-[#888888] ml-2">Skipped ({summary.skipped_count || 0})</span>
        </div>
        <div className="mt-2 text-[12px] text-[#888888]">
          Abandoned within &lt; 10 seconds
        </div>
      </div>

      {/* Partial Engagement */}
      <div className="p-5 bg-[#181818] border border-[#262626] rounded-2xl shadow-sm">
        <div className="flex items-center justify-between text-[#888888]">
          <span className="text-[12px] font-semibold uppercase tracking-wider">Partial Watch</span>
          <PlaySquare className="w-4 h-4 text-amber-400" />
        </div>
        <div className="mt-3">
          <span className="text-[28px] font-extrabold text-amber-400">
            {summary.partial_rate || 0}%
          </span>
          <span className="text-[12px] text-[#888888] ml-2">({summary.partial_count || 0})</span>
        </div>
        <div className="mt-2 text-[12px] text-[#888888]">
          Watched 15% – 75% before pause
        </div>
      </div>
    </section>
  );
};
