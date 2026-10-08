import React from 'react';
import { TrendingUp } from 'lucide-react';

interface FunnelItem {
  label: string;
  percentage: number;
  count: number;
  color: string;
}

interface CategoryShareItem {
  name: string;
  percentage: number;
  minutes: number;
}

interface AnalyticsRetentionFunnelProps {
  retentionFunnel: FunnelItem[];
  categoryShares: CategoryShareItem[];
}

export const AnalyticsRetentionFunnel: React.FC<AnalyticsRetentionFunnelProps> = ({
  retentionFunnel = [],
  categoryShares = [],
}) => {
  return (
    <div className="p-6 bg-surface border border-border rounded-2xl shadow-sm flex flex-col justify-between">
      <div>
        <div className="flex items-center gap-2">
          <TrendingUp className="w-4 h-4 text-mint" />
          <h2 className="text-[15px] font-bold text-text-primary uppercase tracking-wider">
            Attention Funnel
          </h2>
        </div>
        <p className="text-[12.5px] text-text-secondary mt-1">
          How long videos hold this child's focus.
        </p>
      </div>

      <div className="space-y-4 my-6">
        {retentionFunnel.map((item, i) => (
          <div key={i} className="space-y-1.5">
            <div className="flex justify-between text-[12.5px]">
              <span className="text-text-primary font-medium flex items-center gap-1.5">
                <span className="w-2 h-2 rounded-full" style={{ backgroundColor: item.color }} />
                {item.label}
              </span>
              <span className="text-text-secondary font-mono">
                {item.percentage}% ({item.count})
              </span>
            </div>
            <div className="h-2.5 w-full bg-surface-elevated rounded-full overflow-hidden border border-border">
              <div
                className="h-full rounded-full transition-all duration-500"
                style={{ width: `${item.percentage}%`, backgroundColor: item.color }}
              />
            </div>
          </div>
        ))}
      </div>

      {/* Category Shares Breakdown */}
      <div className="pt-4 border-t border-border">
        <h3 className="text-[12px] font-semibold text-text-secondary uppercase tracking-wider mb-2">
          Top Categories
        </h3>
        <div className="space-y-2">
          {categoryShares.slice(0, 3).map((cat, i) => (
            <div key={i} className="flex justify-between items-center text-[12px]">
              <span className="text-text-primary capitalize">{cat.name}</span>
              <span className="text-sky font-semibold">{cat.percentage}% ({cat.minutes}m)</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
