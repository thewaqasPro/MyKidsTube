import React from 'react';
import type { ChildProfile } from '@/types/video';
import {
  Smartphone,
  Tablet,
  Plus,
  RefreshCw,
  X,
  ShieldCheck,
  AlertCircle,
  CheckCircle,
  Trash2,
} from 'lucide-react';

export interface StudioDevicesTabProps {
  devicesList: any[];
  loadingDevices: boolean;
  isPairingOpen: boolean;
  onTogglePairingOpen: () => void;
  pairCode: string;
  onPairCodeChange: (val: string) => void;
  pairProfileId: string;
  onPairProfileIdChange: (val: string) => void;
  pairDeviceName: string;
  onPairDeviceNameChange: (val: string) => void;
  isSubmittingPair: boolean;
  pairError: string | null;
  pairSuccess: string | null;
  onPairSubmit: (e: React.FormEvent) => void;
  onUnpair: (id: string, name: string) => void;
  deletingDeviceId: string | null;
  onRefresh: () => void;
  initialProfiles: ChildProfile[];
}

export const StudioDevicesTab: React.FC<StudioDevicesTabProps> = ({
  devicesList,
  loadingDevices,
  isPairingOpen,
  onTogglePairingOpen,
  pairCode,
  onPairCodeChange,
  pairProfileId,
  onPairProfileIdChange,
  pairDeviceName,
  onPairDeviceNameChange,
  isSubmittingPair,
  pairError,
  pairSuccess,
  onPairSubmit,
  onUnpair,
  deletingDeviceId,
  onRefresh,
  initialProfiles,
}) => {
  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-[22px] font-bold text-white tracking-tight">Kid Tablet & Phone Devices</h1>
          <p className="text-[13px] text-text-muted">Pair and manage mobile apps running MyKidsTube on phones or tablets.</p>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={onTogglePairingOpen}
            className="flex items-center gap-2 px-4 py-2 bg-coral hover:bg-coral-hover text-[13px] font-semibold text-white rounded-xl shadow-lg shadow-coral/20 transition-all cursor-pointer"
          >
            <Plus className="w-4 h-4" />
            Pair New Device
          </button>
          <button
            onClick={onRefresh}
            disabled={loadingDevices}
            className="flex items-center gap-2 px-3.5 py-2 bg-surface hover:bg-surface-hover text-[12px] font-medium text-white rounded-xl border border-border transition-colors cursor-pointer"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${loadingDevices ? 'animate-spin' : ''}`} />
            Refresh
          </button>
        </div>
      </div>

      {/* PAIR NEW DEVICE FORM / CARD */}
      {(isPairingOpen || devicesList.length === 0) && (
        <div className="p-6 bg-surface border-2 border-border rounded-2xl shadow-xl space-y-5">
          <div className="flex items-start justify-between">
            <div className="flex items-center gap-3">
              <div className="p-2.5 rounded-xl bg-sky/10 text-sky border border-sky/20">
                <Smartphone className="w-6 h-6" />
              </div>
              <div>
                <h2 className="text-[16px] font-bold text-white">Connect Device by Pairing Code</h2>
                <p className="text-[12px] text-text-secondary">
                  Open MyKidsTube on your kid's phone or tablet to find the 6-character code (e.g. ABC-234).
                </p>
              </div>
            </div>
            {devicesList.length > 0 && (
              <button
                onClick={onTogglePairingOpen}
                className="text-text-muted hover:text-white p-1 rounded-lg hover:bg-white/5 transition-colors cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            )}
          </div>

          <form onSubmit={onPairSubmit} className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {/* Code Input */}
              <div>
                <label className="block text-[11px] font-semibold text-text-secondary uppercase tracking-wider mb-1.5">
                  Pairing Code *
                </label>
                <input
                  type="text"
                  value={pairCode}
                  onChange={(e) => {
                    let val = e.target.value.toUpperCase().replace(/[^A-Z0-9-]/g, '');
                    if (val.length === 3 && !val.includes('-') && !e.target.value.endsWith('-')) {
                      val = val + '-';
                    }
                    if (val.length > 7) val = val.slice(0, 7);
                    onPairCodeChange(val);
                  }}
                  placeholder="ABC-234"
                  maxLength={7}
                  className="w-full px-4 py-2.5 bg-canvas-deep border border-border rounded-xl text-white font-mono text-[18px] tracking-wider text-center focus:outline-none focus:border-sky focus:ring-1 focus:ring-sky transition-colors uppercase placeholder-text-muted"
                />
              </div>

              {/* Child Profile */}
              <div>
                <label className="block text-[11px] font-semibold text-text-secondary uppercase tracking-wider mb-1.5">
                  Child Profile
                </label>
                <select
                  value={pairProfileId}
                  onChange={(e) => onPairProfileIdChange(e.target.value)}
                  className="w-full px-3.5 py-3 bg-canvas-deep border border-border rounded-xl text-white text-[13px] focus:outline-none focus:border-sky focus:ring-1 focus:ring-sky transition-colors cursor-pointer"
                >
                  {(initialProfiles && initialProfiles.length > 0
                    ? initialProfiles
                    : [{ id: 'kids_all', name: 'All Kids' }, { id: 'kids_toddler', name: 'Little Kids' }]
                  ).map((p) => (
                    <option key={p.id} value={p.id}>
                      {p.name} {p.age_bracket ? `(${p.age_bracket})` : ''}
                    </option>
                  ))}
                </select>
              </div>

              {/* Device Name */}
              <div>
                <label className="block text-[11px] font-semibold text-text-secondary uppercase tracking-wider mb-1.5">
                  Device Name (Optional)
                </label>
                <input
                  type="text"
                  value={pairDeviceName}
                  onChange={(e) => onPairDeviceNameChange(e.target.value)}
                  placeholder="e.g. Emma's iPad, Kids Phone"
                  maxLength={64}
                  className="w-full px-4 py-3 bg-canvas-deep border border-border rounded-xl text-white text-[13px] focus:outline-none focus:border-sky focus:ring-1 focus:ring-sky transition-colors placeholder-text-muted"
                />
              </div>
            </div>

            {pairError && (
              <div className="p-3 rounded-xl bg-red-500/10 border border-red-500/20 text-red-400 text-[12px] flex items-center gap-2">
                <AlertCircle className="w-4 h-4 flex-shrink-0" />
                <span>{pairError}</span>
              </div>
            )}

            {pairSuccess && (
              <div className="p-3 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-[12px] flex items-center gap-2">
                <CheckCircle className="w-4 h-4 flex-shrink-0" />
                <span>{pairSuccess}</span>
              </div>
            )}

            <div className="flex items-center justify-end gap-3 pt-2">
              <button
                type="submit"
                disabled={isSubmittingPair || !pairCode.trim()}
                className="flex items-center gap-2 px-5 py-2.5 bg-coral hover:bg-coral-hover disabled:opacity-50 disabled:cursor-not-allowed text-white font-semibold text-[13px] rounded-xl shadow-lg shadow-coral/30 transition-all cursor-pointer"
              >
                {isSubmittingPair ? (
                  <>
                    <RefreshCw className="w-4 h-4 animate-spin" />
                    Authorizing Device...
                  </>
                ) : (
                  <>
                    <ShieldCheck className="w-4 h-4" />
                    Authorize & Connect Device
                  </>
                )}
              </button>
            </div>
          </form>
        </div>
      )}

      {/* DEVICES LIST */}
      {loadingDevices ? (
        <div className="p-12 text-center text-text-muted text-[13px]">Loading paired devices...</div>
      ) : devicesList.length === 0 ? (
        <div className="p-8 bg-surface border border-border rounded-2xl text-center space-y-2">
          <p className="text-[13px] text-text-secondary">
            Enter the 6-character code from your phone or tablet above to link your first device.
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {devicesList.map((dev: any) => (
            <div key={dev.id} className="p-6 bg-surface border border-border rounded-2xl space-y-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div
                    className={`p-2.5 rounded-xl ${
                      dev.status === 'paired'
                        ? 'bg-emerald-500/10 text-emerald-400'
                        : 'bg-amber-500/10 text-amber-400'
                    }`}
                  >
                    <Tablet className="w-6 h-6" />
                  </div>
                  <div>
                    <h3 className="font-semibold text-white">{dev.device_name || 'Kids Device'}</h3>
                    <p className="text-[12px] text-text-secondary">
                      Status:{' '}
                      <span
                        className={
                          dev.status === 'paired'
                            ? 'text-emerald-400 font-medium'
                            : 'text-amber-400 font-medium'
                        }
                      >
                        {dev.status === 'paired' ? 'Paired & Active' : 'Pending Authorization'}
                      </span>
                    </p>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  {dev.pairing_code && (
                    <span className="text-[11px] font-mono px-2 py-0.5 rounded bg-canvas-deep text-text-secondary border border-border">
                      {dev.pairing_code}
                    </span>
                  )}
                  <button
                    onClick={() => onUnpair(dev.id, dev.device_name || 'Kids Device')}
                    disabled={deletingDeviceId === dev.id}
                    className="p-1.5 text-text-muted hover:text-red-400 hover:bg-red-500/10 rounded-lg transition-colors cursor-pointer"
                    title="Unpair Device"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
              <div className="p-4 rounded-xl bg-canvas-deep border border-border text-[12px] space-y-2">
                <div className="flex justify-between">
                  <span className="text-text-secondary">Profile Assigned:</span>
                  <span className="text-white font-medium">{dev.profile_name || 'All Kids'}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-text-secondary">Device Token:</span>
                  <span className="font-mono text-emerald-400">
                    {dev.has_token ? 'Issued & Secured (SHA-256)' : 'None'}
                  </span>
                </div>
                {dev.created_at && (
                  <div className="flex justify-between">
                    <span className="text-text-secondary">Registered:</span>
                    <span className="text-text-secondary">{new Date(dev.created_at).toLocaleDateString()}</span>
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
