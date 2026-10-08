import React from 'react';
import {
  KeyRound,
  RefreshCw,
  Check,
  CheckCircle,
  AlertCircle,
  X,
} from 'lucide-react';

interface SecurityPinGateCardProps {
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
}

export const SecurityPinGateCard: React.FC<SecurityPinGateCardProps> = ({
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
}) => {
  return (
    <div className="p-6 bg-[#161616] border border-[#262626] rounded-2xl space-y-5">
      <div className="flex items-start justify-between">
        <div className="flex items-center gap-3">
          <div className="p-2.5 rounded-xl bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
            <KeyRound className="w-6 h-6" />
          </div>
          <div>
            <h3 className="text-[16px] font-bold text-white">Child Gate & Tablet PIN</h3>
            <p className="text-[12px] text-[#888888]">
              This 4–6 digit numerical PIN secures Studio access and video management on shared family tablets.
            </p>
          </div>
        </div>
        <span
          className={`px-2.5 py-1 rounded-full text-[11px] font-medium border ${
            pinStatus?.hasCustomPin
              ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20'
              : 'bg-amber-500/10 text-amber-400 border-amber-500/20'
          }`}
        >
          {pinStatus?.hasCustomPin ? 'Custom PIN Active' : 'Default PIN (1234)'}
        </span>
      </div>

      <form onSubmit={onUpdatePin} className="p-4 bg-[#111111] border border-[#222222] rounded-xl space-y-4 max-w-lg">
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div>
            <label className="block text-[11px] font-semibold text-[#AAAAAA] uppercase tracking-wider mb-1.5">
              New PIN (4–6 Digits)
            </label>
            <div className="relative">
              <input
                type={showPin ? 'text' : 'password'}
                value={newPin}
                onChange={(e) => onNewPinChange(e.target.value.replace(/\D/g, '').slice(0, 6))}
                placeholder="••••"
                maxLength={6}
                className="w-full px-3.5 py-2.5 bg-[#181818] border border-[#333333] rounded-xl text-white font-mono text-[16px] tracking-widest focus:outline-none focus:border-emerald-500"
              />
            </div>
          </div>
          <div>
            <label className="block text-[11px] font-semibold text-[#AAAAAA] uppercase tracking-wider mb-1.5">
              Confirm New PIN
            </label>
            <div className="relative">
              <input
                type={showPin ? 'text' : 'password'}
                value={confirmPin}
                onChange={(e) => onConfirmPinChange(e.target.value.replace(/\D/g, '').slice(0, 6))}
                placeholder="••••"
                maxLength={6}
                className="w-full px-3.5 py-2.5 bg-[#181818] border border-[#333333] rounded-xl text-white font-mono text-[16px] tracking-widest focus:outline-none focus:border-emerald-500"
              />
            </div>
          </div>
        </div>

        <div className="flex items-center justify-between pt-1">
          <button
            type="button"
            onClick={onToggleShowPin}
            className="text-[11px] text-[#888888] hover:text-white transition-colors cursor-pointer"
          >
            {showPin ? 'Hide PIN numbers' : 'Show PIN numbers'}
          </button>

          <button
            type="submit"
            disabled={isUpdatingPin || newPin.length < 4 || newPin !== confirmPin}
            className="flex items-center gap-2 px-4 py-2 bg-emerald-600 hover:bg-emerald-500 disabled:opacity-50 text-white text-[12px] font-semibold rounded-xl transition-all cursor-pointer shadow-md shadow-emerald-600/20"
          >
            {isUpdatingPin ? (
              <>
                <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                Saving...
              </>
            ) : (
              <>
                <Check className="w-3.5 h-3.5" />
                Save New PIN
              </>
            )}
          </button>
        </div>
      </form>

      {pinNotice && (
        <div
          className={`p-3 rounded-xl text-[12px] flex items-center justify-between ${
            pinNotice.type === 'success'
              ? 'bg-emerald-500/10 border border-emerald-500/20 text-emerald-300'
              : 'bg-red-500/10 border border-red-500/20 text-red-300'
          }`}
        >
          <div className="flex items-center gap-2">
            {pinNotice.type === 'success' ? (
              <CheckCircle className="w-4 h-4 shrink-0" />
            ) : (
              <AlertCircle className="w-4 h-4 shrink-0" />
            )}
            <span>{pinNotice.message}</span>
          </div>
          <button onClick={onDismissPinNotice} className="text-white/60 hover:text-white">
            <X className="w-3.5 h-3.5" />
          </button>
        </div>
      )}
    </div>
  );
};
