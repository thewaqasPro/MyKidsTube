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
    <div className="p-6 bg-[#181818] border border-[#262626] rounded-2xl shadow-sm flex flex-col justify-between">
      <div>
        <div className="flex items-center gap-2">
          <TrendingUp className="w-4 h-4 text-emerald-400" />
          <h2 className="text-[15px] font-bold text-white uppercase tracking-wider">
            Attention Funnel
          </h2>
        </div>
        <p className="text-[12.5px] text-[#888888] mt-1">
          How long videos hold this child's focus.
        </p>
      </div>

      <div className="space-y-4 my-6">
        {retentionFunnel.map((item, i) => (
          <div key={i} className="space-y-1.5">
            <div className="flex justify-between text-[12.5px]">
              <span className="text-white font-medium flex items-center gap-1.5">
                <span className="w-2 h-2 rounded-full" style={{ backgroundColor: item.color }} />
                {item.label}
              </span>
              <span className="text-[#AAAAAA] font-mono">
                {item.percentage}% ({item.count})
              </span>
            </div>
            <div className="h-2.5 w-full bg-[#121212] rounded-full overflow-hidden border border-[#262626]">
              <div
                className="h-full rounded-full transition-all duration-500"
                style={{ width: `${item.percentage}%`, backgroundColor: item.color }}
              />
            </div>
          </div>
        ))}
      </div>

      {/* Category Shares Breakdown */}
      <div className="pt-4 border-t border-[#262626]">
        <h3 className="text-[12px] font-semibold text-[#888888] uppercase tracking-wider mb-2">
          Top Categories
        </h3>
        <div className="space-y-2">
          {categoryShares.slice(0, 3).map((cat, i) => (
            <div key={i} className="flex justify-between items-center text-[12px]">
              <span className="text-white capitalize">{cat.name}</span>
              <span className="text-[#3EA6FF] font-semibold">{cat.percentage}% ({cat.minutes}m)</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
