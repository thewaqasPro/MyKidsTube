import React from 'react';
import { Laptop, RefreshCw } from 'lucide-react';

interface SecuritySessionsCardProps {
  sessionsList: any[];
  loadingSessions: boolean;
  onRefreshSessions: () => void;
  onRevokeSession: (token: string) => void;
  onRevokeOtherSessions: () => void;
  revokingSessionId: string | null;
}

export const SecuritySessionsCard: React.FC<SecuritySessionsCardProps> = ({
  sessionsList,
  loadingSessions,
  onRefreshSessions,
  onRevokeSession,
  onRevokeOtherSessions,
  revokingSessionId,
}) => {
  return (
    <div className="p-6 bg-[#161616] border border-[#262626] rounded-2xl space-y-5">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <div className="p-2.5 rounded-xl bg-cyan-500/10 text-cyan-400 border border-cyan-500/20">
            <Laptop className="w-6 h-6" />
          </div>
          <div>
            <h3 className="text-[16px] font-bold text-white">Active Parent Sessions</h3>
            <p className="text-[12px] text-[#888888]">
              Review and revoke active sessions across computers, tablets, and phones.
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={onRevokeOtherSessions}
            className="px-3.5 py-2 bg-[#222222] hover:bg-[#2A2A2A] text-white text-[12px] font-medium rounded-xl border border-[#333333] transition-colors cursor-pointer"
          >
            Revoke Other Devices
          </button>
          <button
            onClick={onRefreshSessions}
            disabled={loadingSessions}
            className="p-2 bg-[#222222] hover:bg-[#2C2C2C] text-[#AAAAAA] hover:text-white rounded-xl border border-[#333333] transition-colors cursor-pointer"
            title="Refresh sessions"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${loadingSessions ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      {loadingSessions ? (
        <div className="p-6 text-center text-[#888888] text-[12px]">Loading active sessions...</div>
      ) : sessionsList.length === 0 ? (
        <div className="p-6 bg-[#111111] border border-[#222222] rounded-xl text-center text-[12px] text-[#777777]">
          Current session active.
        </div>
      ) : (
        <div className="space-y-2.5">
          {sessionsList.map((s: any) => (
            <div
              key={s.id || s.token}
              className="p-3.5 bg-[#111111] border border-[#222222] rounded-xl flex items-center justify-between gap-3"
            >
              <div className="flex items-center gap-3 min-w-0">
                <div className="p-2 rounded-lg bg-cyan-500/10 text-cyan-400 shrink-0">
                  <Laptop className="w-4 h-4" />
                </div>
                <div className="min-w-0">
                  <p className="text-[12px] font-medium text-white truncate font-mono">
                    {s.userAgent ? s.userAgent.slice(0, 48) : 'Web Browser Session'}
                  </p>
                  <p className="text-[11px] text-[#777777]">
                    IP: {s.ipAddress || '127.0.0.1'} •{' '}
                    {s.createdAt ? `Logged in ${new Date(s.createdAt).toLocaleDateString()}` : 'Active'}
                  </p>
                </div>
              </div>
              <button
                onClick={() => onRevokeSession(s.token)}
                disabled={revokingSessionId === s.token}
                className="px-3 py-1.5 text-[11px] text-red-400 hover:bg-red-500/10 rounded-lg border border-red-500/20 transition-colors cursor-pointer"
              >
                Revoke
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
