import React from 'react';
import { Fingerprint, Mail, Lock, ArrowRight } from 'lucide-react';

interface MasterAccountAuthCardProps {
  isRegistering: boolean;
  setIsRegistering: (val: boolean) => void;
  name: string;
  setName: (val: string) => void;
  email: string;
  setEmail: (val: string) => void;
  password: string;
  setPassword: (val: string) => void;
  loading: boolean;
  handleEmailSignIn: (e: React.FormEvent) => void;
  handleEmailSignUp: (e: React.FormEvent) => void;
  handlePasskeySignIn: () => void;
  setError: (err: string) => void;
}

export const MasterAccountAuthCard: React.FC<MasterAccountAuthCardProps> = ({
  isRegistering,
  setIsRegistering,
  name,
  setName,
  email,
  setEmail,
  password,
  setPassword,
  loading,
  handleEmailSignIn,
  handleEmailSignUp,
  handlePasskeySignIn,
  setError,
}) => {
  return (
    <div className="w-full">
      {/* Biometric Passkey Button */}
      {!isRegistering && (
        <button
          type="button"
          onClick={handlePasskeySignIn}
          disabled={loading}
          className="w-full mb-4 py-3.5 px-4 bg-gradient-to-r from-[#151D33] to-[#1E294B] hover:from-[#1E294B] hover:to-[#2A375E] border-2 border-[#38BDF8]/40 hover:border-[#38BDF8] text-white rounded-2xl text-xs font-black flex items-center justify-center gap-2.5 transition-all shadow-md active:scale-[0.98] cursor-pointer"
        >
          <Fingerprint className="w-5 h-5 text-[#38BDF8]" />
          <span>Sign in with Passkey / FaceID</span>
        </button>
      )}

      {!isRegistering && (
        <div className="flex items-center gap-3 my-4">
          <div className="flex-1 h-px bg-[#1E294B]" />
          <span className="text-[11px] text-[#94A3B8] font-bold uppercase tracking-wider">or with master password</span>
          <div className="flex-1 h-px bg-[#1E294B]" />
        </div>
      )}

      <form onSubmit={isRegistering ? handleEmailSignUp : handleEmailSignIn} className="space-y-3.5">
        {isRegistering && (
          <div>
            <label className="block text-xs font-bold text-[#94A3B8] mb-1">Parent Name</label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g. Sarah"
              className="w-full bg-[#0B0F19] border-2 border-[#1E294B] focus:border-[#38BDF8] rounded-xl px-4 py-3 text-white text-xs outline-none transition-colors"
              required
            />
          </div>
        )}

        <div>
          <label className="block text-xs font-bold text-[#94A3B8] mb-1">Email Address</label>
          <div className="relative">
            <Mail className="w-4 h-4 text-[#94A3B8] absolute left-3.5 top-3.5" />
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="parent@example.com"
              className="w-full bg-[#0B0F19] border-2 border-[#1E294B] focus:border-[#38BDF8] rounded-xl pl-10 pr-4 py-3 text-white text-xs outline-none transition-colors"
              required
            />
          </div>
        </div>

        <div>
          <label className="block text-xs font-bold text-[#94A3B8] mb-1">Master Password</label>
          <div className="relative">
            <Lock className="w-4 h-4 text-[#94A3B8] absolute left-3.5 top-3.5" />
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              className="w-full bg-[#0B0F19] border-2 border-[#1E294B] focus:border-[#38BDF8] rounded-xl pl-10 pr-4 py-3 text-white text-xs outline-none transition-colors"
              required
            />
          </div>
        </div>

        <button
          type="submit"
          disabled={loading}
          className="w-full mt-2 py-3.5 bg-gradient-to-r from-[#FF5E62] to-[#FF8E53] hover:from-[#FF8E53] hover:to-[#FF5E62] disabled:opacity-40 text-white font-display font-black text-xs tracking-wide rounded-2xl transition-all cursor-pointer shadow-lg shadow-[#FF5E62]/25 flex items-center justify-center gap-2 border-2 border-white/10 active:scale-95"
        >
          {loading ? (
            <span>Securing session...</span>
          ) : (
            <>
              <span>{isRegistering ? 'Create Master Account' : 'Sign In to Control Center'}</span>
              <ArrowRight className="w-4 h-4" />
            </>
          )}
        </button>
      </form>

      {/* Toggle Register / Login */}
      <div className="mt-4 text-center">
        <button
          type="button"
          onClick={() => {
            setIsRegistering(!isRegistering);
            setError('');
          }}
          className="text-xs text-[#94A3B8] hover:text-[#38BDF8] font-bold transition-colors cursor-pointer"
        >
          {isRegistering
            ? 'Already have an account? Sign In'
            : 'First time setup? Create Master Parent Account'}
        </button>
      </div>
    </div>
  );
};
