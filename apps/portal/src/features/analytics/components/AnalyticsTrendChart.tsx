import React from 'react';
import { BarChart3 } from 'lucide-react';

interface DailyTrendItem {
  date: string;
  day_label: string;
  minutes: number;
  views: number;
  completed: number;
  skipped: number;
}

interface AnalyticsTrendChartProps {
  timeSeries: DailyTrendItem[];
  selectedRange: string;
}

export const AnalyticsTrendChart: React.FC<AnalyticsTrendChartProps> = ({
  timeSeries = [],
  selectedRange,
}) => {
  const maxSeriesMins = Math.max(1, ...timeSeries.map((t) => t.minutes || 0));

  return (
    <div className="lg:col-span-2 p-6 bg-surface border border-border rounded-2xl shadow-sm flex flex-col justify-between">
      <div>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <BarChart3 className="w-4 h-4 text-sky" />
            <h2 className="text-[15px] font-bold text-text-primary uppercase tracking-wider">
              Daily Viewing Trend ({selectedRange.toUpperCase()})
            </h2>
          </div>
          <span className="text-[12px] text-text-secondary">Minutes per day</span>
        </div>
        <p className="text-[12.5px] text-text-secondary mt-1">
          Hover to inspect viewing sessions and completion breakdown.
        </p>
      </div>

      {/* Bar Chart Canvas */}
      <div className="mt-8">
        <div className="h-44 flex items-end justify-between gap-2 pt-6">
          {timeSeries.map((item, idx) => {
            const ratio = Math.max(0.06, item.minutes / maxSeriesMins);
            return (
              <div key={idx} className="flex-1 flex flex-col items-center group relative h-full justify-end">
                {/* Hover Tooltip */}
                <div className="absolute -top-12 opacity-0 group-hover:opacity-100 transition-opacity bg-sidebar/95 border border-border px-2.5 py-1.5 rounded-lg text-center z-10 pointer-events-none whitespace-nowrap shadow-xl">
                  <p className="text-[11px] font-bold text-text-primary">{item.date} ({item.day_label})</p>
                  <p className="text-[10px] text-sky">{item.minutes} mins • {item.views} plays</p>
                  <p className="text-[9px] text-mint">&check; {item.completed} completed • &times; {item.skipped} skipped</p>
                </div>

                {/* Animated Bar with Stacked segments */}
                <div
                  style={{ height: `${ratio * 100}%` }}
                  className={`w-full max-w-[32px] rounded-t-lg transition-all duration-300 relative overflow-hidden ${
                    item.minutes > 0 ? 'bg-gradient-to-t from-sky/70 to-sky' : 'bg-surface-elevated'
                  }`}
                />
                <span className="text-[11px] text-text-secondary mt-2 font-medium">
                  {item.day_label}
                </span>
                <span className="text-[9px] text-text-muted">
                  {item.date}
                </span>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
