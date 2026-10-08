import React from 'react';
import {
  Fingerprint,
  Plus,
  RefreshCw,
  X,
  CheckCircle,
  AlertCircle,
  Trash2,
} from 'lucide-react';

interface SecurityPasskeysCardProps {
  passkeysList: any[];
  loadingPasskeys: boolean;
  isAddingPasskeyOpen: boolean;
  onToggleAddingPasskeyOpen: () => void;
  newPasskeyName: string;
  onNewPasskeyNameChange: (val: string) => void;
  registeringPasskey: boolean;
  onRegisterPasskey: (e: React.FormEvent) => void;
  onDeletePasskey: (id: string, name: string) => void;
  onRefreshPasskeys: () => void;
  passkeyNotice: { message: string; type: 'success' | 'error' } | null;
  onDismissPasskeyNotice: () => void;
}

export const SecurityPasskeysCard: React.FC<SecurityPasskeysCardProps> = ({
  passkeysList,
  loadingPasskeys,
  isAddingPasskeyOpen,
  onToggleAddingPasskeyOpen,
  newPasskeyName,
  onNewPasskeyNameChange,
  registeringPasskey,
  onRegisterPasskey,
  onDeletePasskey,
  onRefreshPasskeys,
  passkeyNotice,
  onDismissPasskeyNotice,
}) => {
  return (
    <div className="p-6 bg-surface border border-border rounded-2xl space-y-5">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <div className="p-2.5 rounded-xl bg-sky/10 text-sky border border-sky/20">
            <Fingerprint className="w-6 h-6" />
          </div>
          <div>
            <h3 className="text-[16px] font-bold text-white">Biometric Passkeys (FaceID / TouchID / Windows Hello)</h3>
            <p className="text-[12px] text-text-muted">
              Sign in instantly with a touch or glance using FIDO2 WebAuthn encryption. No passwords to remember.
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={onToggleAddingPasskeyOpen}
            className="flex items-center gap-1.5 px-3.5 py-2 bg-coral hover:bg-coral-hover text-[12px] font-semibold text-white rounded-xl shadow-md shadow-coral/20 transition-all cursor-pointer"
          >
            <Plus className="w-3.5 h-3.5" />
            Register New Passkey
          </button>
          <button
            onClick={onRefreshPasskeys}
            disabled={loadingPasskeys}
            className="p-2 bg-canvas-deep hover:bg-surface text-text-secondary hover:text-white rounded-xl border border-border transition-colors cursor-pointer"
            title="Refresh passkeys list"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${loadingPasskeys ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      {/* Inline Register Passkey Form */}
      {isAddingPasskeyOpen && (
        <form onSubmit={onRegisterPasskey} className="p-4 bg-canvas-deep border border-sky/30 rounded-xl space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-[12px] font-semibold text-white">Device or Key Name:</span>
            <button
              type="button"
              onClick={onToggleAddingPasskeyOpen}
              className="text-text-muted hover:text-white text-[12px]"
            >
              Cancel
            </button>
          </div>
          <div className="flex flex-col sm:flex-row gap-2.5">
            <input
              type="text"
              value={newPasskeyName}
              onChange={(e) => onNewPasskeyNameChange(e.target.value)}
              placeholder="e.g. MacBook Pro TouchID, Dad's iPhone FaceID"
              maxLength={50}
              className="flex-1 px-3.5 py-2 bg-surface border border-border rounded-xl text-white text-[13px] placeholder-text-muted focus:outline-none focus:border-sky"
            />
            <button
              type="submit"
              disabled={registeringPasskey}
              className="flex items-center justify-center gap-2 px-5 py-2 bg-coral hover:bg-coral-hover disabled:opacity-50 text-white text-[12px] font-semibold rounded-xl transition-all cursor-pointer shrink-0"
            >
              {registeringPasskey ? (
                <>
                  <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                  Authorizing Sensor...
                </>
              ) : (
                <>
                  <Fingerprint className="w-3.5 h-3.5" />
                  Enroll Biometrics
                </>
              )}
            </button>
          </div>
          <p className="text-[11px] text-text-muted">
            Your browser will prompt your system authenticator (TouchID, FaceID, or security key).
          </p>
        </form>
      )}

      {passkeyNotice && (
        <div
          className={`p-3 rounded-xl text-[12px] flex items-center justify-between ${
            passkeyNotice.type === 'success'
              ? 'bg-emerald-500/10 border border-emerald-500/20 text-emerald-300'
              : 'bg-red-500/10 border border-red-500/20 text-red-300'
          }`}
        >
          <div className="flex items-center gap-2">
            {passkeyNotice.type === 'success' ? (
              <CheckCircle className="w-4 h-4 shrink-0" />
            ) : (
              <AlertCircle className="w-4 h-4 shrink-0" />
            )}
            <span>{passkeyNotice.message}</span>
          </div>
          <button onClick={onDismissPasskeyNotice} className="text-white/60 hover:text-white">
            <X className="w-3.5 h-3.5" />
          </button>
        </div>
      )}

      {/* Passkeys List */}
      {loadingPasskeys ? (
        <div className="p-6 text-center text-text-muted text-[12px]">Loading registered passkeys...</div>
      ) : passkeysList.length === 0 ? (
        <div className="p-6 bg-canvas-deep border border-border rounded-xl text-center space-y-1.5">
          <p className="text-[13px] text-text-primary font-medium">No biometric passkeys registered yet</p>
          <p className="text-[11px] text-text-muted">
            Click "Register New Passkey" above to activate Touch ID or Face ID for fast 1-tap sign-in on this device.
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          {passkeysList.map((pk: any) => (
            <div
              key={pk.id}
              className="p-4 bg-canvas-deep border border-border rounded-xl flex items-center justify-between gap-3"
            >
              <div className="flex items-center gap-3 min-w-0">
                <div className="p-2 rounded-lg bg-sky/10 text-sky shrink-0">
                  <Fingerprint className="w-4 h-4" />
                </div>
                <div className="min-w-0">
                  <p className="text-[13px] font-semibold text-white truncate">{pk.name || 'Biometric Passkey'}</p>
                  <p className="text-[11px] text-text-secondary truncate">
                    {pk.createdAt ? `Enrolled ${new Date(pk.createdAt).toLocaleDateString()}` : 'Registered hardware credential'}
                  </p>
                </div>
              </div>
              <button
                onClick={() => onDeletePasskey(pk.id, pk.name)}
                className="p-1.5 text-text-muted hover:text-red-400 hover:bg-red-500/10 rounded-lg transition-colors cursor-pointer"
                title="Revoke passkey"
              >
                <Trash2 className="w-4 h-4" />
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
