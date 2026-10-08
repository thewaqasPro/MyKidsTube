import React from 'react';
import {
  ShieldCheck,
  AlertCircle,
  LogOut,
} from 'lucide-react';
import { SecurityPasskeysCard } from './SecurityPasskeysCard';
import { SecurityPinGateCard } from './SecurityPinGateCard';
import { SecuritySessionsCard } from './SecuritySessionsCard';

export interface StudioSecurityTabProps {
  currentUser?: {
    id: string;
    name?: string;
    email?: string;
    role?: string;
  } | null;
  onSignOut: () => void;
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
  pinStatus: { hasCustomPin: boolean; pinLength: number } | null;
  newPin: string;
  onNewPinChange: (val: string) => void;
  confirmPin: string;
  onConfirmPinChange: (val: string) => void;
  showPin: boolean;
  onToggleShowPin: () => void;
  isUpdatingPin: boolean;
  onUpdatePin: (e: React.FormEvent) => void;
  pinNotice: { message: string; type: 'success' | 'error' } | null;
  onDismissPinNotice: () => void;
  sessionsList: any[];
  loadingSessions: boolean;
  onRefreshSessions: () => void;
  onRevokeSession: (token: string) => void;
  onRevokeOtherSessions: () => void;
  revokingSessionId: string | null;
}

export const StudioSecurityTab: React.FC<StudioSecurityTabProps> = ({
  currentUser,
  onSignOut,
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
  pinStatus,
  newPin,
  onNewPinChange,
  confirmPin,
  onConfirmPinChange,
  showPin,
  onToggleShowPin,
  isUpdatingPin,
  onUpdatePin,
  pinNotice,
  onDismissPinNotice,
  sessionsList,
  loadingSessions,
  onRefreshSessions,
  onRevokeSession,
  onRevokeOtherSessions,
  revokingSessionId,
}) => {
  return (
    <div className="space-y-6 max-w-5xl">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-[22px] font-bold text-white tracking-tight">Parent Security & Access Control</h1>
          <p className="text-[13px] text-text-muted">
            Manage Master Parent login, Biometric Passkeys (FaceID/TouchID), and 4-digit tablet Child Gate PIN.
          </p>
        </div>
        <button
          onClick={onSignOut}
          className="inline-flex items-center gap-2 px-4 py-2 bg-red-950/60 hover:bg-red-900/80 text-red-300 border border-red-800/60 rounded-xl text-[12px] font-semibold transition-all cursor-pointer shadow-sm"
          title="Sign out of Parent Studio"
        >
          <LogOut className="w-3.5 h-3.5" />
          Sign Out
        </button>
      </div>

      {/* Master Account Profile Header Card */}
      <div className="p-6 bg-surface border border-border rounded-2xl shadow-lg flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
        <div className="flex items-center gap-4">
          <div className="w-14 h-14 rounded-2xl bg-gradient-to-tr from-coral to-sun flex items-center justify-center text-white text-[20px] font-bold shadow-lg shadow-coral/20 border border-coral/30 shrink-0">
            {currentUser?.name ? currentUser.name.charAt(0).toUpperCase() : <ShieldCheck className="w-7 h-7" />}
          </div>
          <div>
            <div className="flex items-center gap-2.5">
              <h2 className="text-[17px] font-bold text-white">
                {currentUser?.name || 'Primary Parent Administrator'}
              </h2>
              <span className="px-2.5 py-0.5 rounded-full text-[10px] font-semibold bg-emerald-500/15 text-emerald-400 border border-emerald-500/30 uppercase tracking-wider">
                {currentUser?.role || 'Parent'}
              </span>
            </div>
            <p className="text-[13px] text-text-secondary font-mono mt-0.5">
              {currentUser?.email || 'parent@kidstube.local'}
            </p>
            <div className="flex items-center gap-3 mt-2 text-[11px] text-text-muted">
              <span>
                Authentication:{' '}
                <strong className="text-white font-medium">
                  {currentUser?.id === 'legacy_parent' ? 'Quick PIN Keypad' : 'Better Auth Master Account'}
                </strong>
              </span>
              <span>•</span>
              <span>
                Protection: <strong className="text-emerald-400 font-medium">Active</strong>
              </span>
            </div>
          </div>
        </div>

        {currentUser?.id === 'legacy_parent' && (
          <div className="p-3.5 bg-amber-500/10 border border-amber-500/20 rounded-xl text-amber-300 text-[12px] max-w-sm space-y-1">
            <div className="font-semibold flex items-center gap-1.5">
              <AlertCircle className="w-3.5 h-3.5" />
              Quick PIN Session Active
            </div>
            <p className="text-[11px] text-amber-200/80 leading-relaxed">
              You unlocked via 4-digit PIN. To enroll FaceID / TouchID biometric passkeys, please sign up or log in
              with your primary email & password.
            </p>
          </div>
        )}
      </div>

      {/* SECTION 1: BIOMETRIC PASSKEYS */}
      <SecurityPasskeysCard
        passkeysList={passkeysList}
        loadingPasskeys={loadingPasskeys}
        isAddingPasskeyOpen={isAddingPasskeyOpen}
        onToggleAddingPasskeyOpen={onToggleAddingPasskeyOpen}
        newPasskeyName={newPasskeyName}
        onNewPasskeyNameChange={onNewPasskeyNameChange}
        registeringPasskey={registeringPasskey}
        onRegisterPasskey={onRegisterPasskey}
        onDeletePasskey={onDeletePasskey}
        onRefreshPasskeys={onRefreshPasskeys}
        passkeyNotice={passkeyNotice}
        onDismissPasskeyNotice={onDismissPasskeyNotice}
      />

      {/* SECTION 2: TABLET & CHILD GATE PIN */}
      <SecurityPinGateCard
        pinStatus={pinStatus}
        newPin={newPin}
        onNewPinChange={onNewPinChange}
        confirmPin={confirmPin}
        onConfirmPinChange={onConfirmPinChange}
        showPin={showPin}
        onToggleShowPin={onToggleShowPin}
        isUpdatingPin={isUpdatingPin}
        onUpdatePin={onUpdatePin}
        pinNotice={pinNotice}
        onDismissPinNotice={onDismissPinNotice}
      />

      {/* SECTION 3: ACTIVE PARENT SESSIONS */}
      <SecuritySessionsCard
        sessionsList={sessionsList}
        loadingSessions={loadingSessions}
        onRefreshSessions={onRefreshSessions}
        onRevokeSession={onRevokeSession}
        onRevokeOtherSessions={onRevokeOtherSessions}
        revokingSessionId={revokingSessionId}
      />
    </div>
  );
};
