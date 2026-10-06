import React, { useState } from 'react';
import { X, Tv, CheckCircle, AlertCircle, Loader2 } from 'lucide-react';
import type { ChildProfile } from '../types/video';

interface PairModalProps {
  isOpen: boolean;
  onClose: () => void;
  profiles: ChildProfile[];
}

export const PairModal: React.FC<PairModalProps> = ({ isOpen, onClose, profiles }) => {
  const [code, setCode] = useState('');
  const [profileId, setProfileId] = useState(profiles[0]?.id || 'kids_all');
  const [status, setStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle');
  const [statusMsg, setStatusMsg] = useState('');

  if (!isOpen) return null;

  const handlePair = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!code.trim()) return;

    setStatus('loading');
    setStatusMsg('Verifying pairing code...');

    try {
      const res = await fetch('/api/pair', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          pairing_code: code.trim().toUpperCase(),
          profile_id: profileId,
          family_id: 'default_family',
        }),
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.detail || data.message || 'Pairing failed. Check the code.');
      }

      setStatus('success');
      setStatusMsg(`Success! Device "${data.device_name || 'Kids Device'}" is now paired!`);
      setCode('');
    } catch (err: any) {
      setStatus('error');
      setStatusMsg(err.message || 'Failed to connect to backend pairing service.');
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm p-4">
      <div className="w-full max-w-md bg-[#1F1F1F] border border-[#333333] rounded-2xl shadow-2xl p-6 text-white animate-in fade-in zoom-in-95 duration-150">
        <div className="flex items-center justify-between pb-4 border-b border-[#2C2C2C]">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-[#3EA6FF] flex items-center justify-center text-black">
              <Tv className="w-4 h-4 fill-current" />
            </div>
            <div>
              <h3 className="text-[17px] font-bold">Pair TV or Tablet</h3>
              <p className="text-[12px] text-[#AAAAAA]">Connect kid's device with a 6-digit code</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1 rounded-full text-[#AAAAAA] hover:text-white hover:bg-[#2A2A2A] transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handlePair} className="mt-5 space-y-4">
          <div>
            <label className="block text-[13px] font-medium text-[#DDDDDD] mb-1.5">
              Enter 6-Digit Pairing Code
            </label>
            <input
              type="text"
              maxLength={6}
              required
              value={code}
              onChange={(e) => setCode(e.target.value.toUpperCase())}
              placeholder="e.g. 782491"
              className="w-full h-12 px-4 bg-[#141414] border border-[#3A3A3A] focus:border-[#3EA6FF] text-[20px] font-mono tracking-widest text-center text-white rounded-xl outline-none uppercase transition-colors"
            />
          </div>

          <div>
            <label className="block text-[13px] font-medium text-[#DDDDDD] mb-1.5">
              Assign to Child Profile
            </label>
            <select
              value={profileId}
              onChange={(e) => setProfileId(e.target.value)}
              className="w-full h-11 px-3 bg-[#141414] border border-[#3A3A3A] focus:border-[#3EA6FF] text-[14px] text-white rounded-xl outline-none transition-colors cursor-pointer"
            >
              {profiles.map((p) => (
                <option key={p.id} value={p.id}>
                  {p.name}
                </option>
              ))}
            </select>
          </div>

          {status === 'loading' && (
            <div className="flex items-center gap-2 p-3 rounded-xl bg-[#222222] text-[#3EA6FF] text-[13px]">
              <Loader2 className="w-4 h-4 animate-spin" />
              <span>{statusMsg}</span>
            </div>
          )}

          {status === 'success' && (
            <div className="flex items-center gap-2 p-3 rounded-xl bg-emerald-950/40 border border-emerald-800 text-emerald-400 text-[13px]">
              <CheckCircle className="w-4 h-4 shrink-0" />
              <span>{statusMsg}</span>
            </div>
          )}

          {status === 'error' && (
            <div className="flex items-center gap-2 p-3 rounded-xl bg-rose-950/40 border border-rose-800 text-rose-400 text-[13px]">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <span>{statusMsg}</span>
            </div>
          )}

          <div className="pt-2 flex justify-end gap-2.5">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2.5 rounded-xl text-[13px] font-medium text-[#AAAAAA] hover:text-white hover:bg-[#2A2A2A] transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={status === 'loading'}
              className="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-[#3EA6FF] hover:bg-[#288EE0] active:scale-95 text-black font-semibold text-[13px] transition-all cursor-pointer disabled:opacity-50"
            >
              <Tv className="w-4 h-4" />
              <span>Confirm Pairing</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
