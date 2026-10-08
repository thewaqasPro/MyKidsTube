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
      <div className="p-5 bg-surface border border-border rounded-2xl shadow-sm">
        <div className="flex items-center justify-between text-text-secondary">
          <span className="text-[12px] font-semibold uppercase tracking-wider">Screen Time</span>
          <Clock className="w-4 h-4 text-sky" />
        </div>
        <div className="mt-3">
          <span className="text-[28px] font-extrabold text-text-primary">
            {totalHours >= 1
              ? `${totalHours} hrs`
              : `${Math.round(totalSeconds / 60)} mins`}
          </span>
        </div>
        <div className="mt-2 text-[12px] text-text-secondary">
          {summary.total_events || 0} viewing sessions logged
        </div>
      </div>

      {/* Completion Rate */}
      <div className="p-5 bg-surface border border-border rounded-2xl shadow-sm">
        <div className="flex items-center justify-between text-text-secondary">
          <span className="text-[12px] font-semibold uppercase tracking-wider">Captured Attention</span>
          <CheckCircle2 className="w-4 h-4 text-mint" />
        </div>
        <div className="mt-3">
          <span className="text-[28px] font-extrabold text-mint">
            {summary.completion_rate || 0}%
          </span>
          <span className="text-[12px] text-text-secondary ml-2">Completed ({summary.completed_count || 0})</span>
        </div>
        <div className="mt-2 text-[12px] text-text-secondary">
          Videos watched through &ge; 75%
        </div>
      </div>

      {/* Quick Pass Rate */}
      <div className="p-5 bg-surface border border-border rounded-2xl shadow-sm">
        <div className="flex items-center justify-between text-text-secondary">
          <span className="text-[12px] font-semibold uppercase tracking-wider">Quick Pass / Bounce</span>
          <AlertTriangle className="w-4 h-4 text-coral" />
        </div>
        <div className="mt-3">
          <span className="text-[28px] font-extrabold text-coral">
            {summary.skip_rate || 0}%
          </span>
          <span className="text-[12px] text-text-secondary ml-2">Skipped ({summary.skipped_count || 0})</span>
        </div>
        <div className="mt-2 text-[12px] text-text-secondary">
          Abandoned within &lt; 10 seconds
        </div>
      </div>

      {/* Partial Engagement */}
      <div className="p-5 bg-surface border border-border rounded-2xl shadow-sm">
        <div className="flex items-center justify-between text-text-secondary">
          <span className="text-[12px] font-semibold uppercase tracking-wider">Partial Watch</span>
          <PlaySquare className="w-4 h-4 text-sun" />
        </div>
        <div className="mt-3">
          <span className="text-[28px] font-extrabold text-sun">
            {summary.partial_rate || 0}%
          </span>
          <span className="text-[12px] text-text-secondary ml-2">({summary.partial_count || 0})</span>
        </div>
        <div className="mt-2 text-[12px] text-text-secondary">
          Watched 15% – 75% before pause
        </div>
      </div>
    </section>
  );
};
