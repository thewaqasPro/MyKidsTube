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
    <div className="p-6 bg-surface border border-border rounded-2xl space-y-5">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <div className="p-2.5 rounded-xl bg-sky/10 text-sky border border-sky/20">
            <Laptop className="w-6 h-6" />
          </div>
          <div>
            <h3 className="text-[16px] font-bold text-white">Active Parent Sessions</h3>
            <p className="text-[12px] text-text-muted">
              Review and revoke active sessions across computers, tablets, and phones.
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={onRevokeOtherSessions}
            className="px-3.5 py-2 bg-canvas-deep hover:bg-surface text-white text-[12px] font-medium rounded-xl border border-border transition-colors cursor-pointer"
          >
            Revoke Other Devices
          </button>
          <button
            onClick={onRefreshSessions}
            disabled={loadingSessions}
            className="p-2 bg-canvas-deep hover:bg-surface text-text-secondary hover:text-white rounded-xl border border-border transition-colors cursor-pointer"
            title="Refresh sessions"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${loadingSessions ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      {loadingSessions ? (
        <div className="p-6 text-center text-text-muted text-[12px]">Loading active sessions...</div>
      ) : sessionsList.length === 0 ? (
        <div className="p-6 bg-canvas-deep border border-border rounded-xl text-center text-[12px] text-text-muted">
          Current session active.
        </div>
      ) : (
        <div className="space-y-2.5">
          {sessionsList.map((s: any) => (
            <div
              key={s.id || s.token}
              className="p-3.5 bg-canvas-deep border border-border rounded-xl flex items-center justify-between gap-3"
            >
              <div className="flex items-center gap-3 min-w-0">
                <div className="p-2 rounded-lg bg-sky/10 text-sky shrink-0">
                  <Laptop className="w-4 h-4" />
                </div>
                <div className="min-w-0">
                  <p className="text-[12px] font-medium text-white truncate font-mono">
                    {s.userAgent ? s.userAgent.slice(0, 48) : 'Web Browser Session'}
                  </p>
                  <p className="text-[11px] text-text-muted">
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
