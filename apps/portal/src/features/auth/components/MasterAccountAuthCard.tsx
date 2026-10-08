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
          className="w-full mb-4 py-3 px-4 bg-gradient-to-r from-[#202020] to-[#282828] hover:from-[#262626] hover:to-[#333333] border border-[#3E3E3E] text-white rounded-2xl text-[13.5px] font-bold flex items-center justify-center gap-2.5 transition-all shadow-md active:scale-[0.98] cursor-pointer"
        >
          <Fingerprint className="w-5 h-5 text-[#3EA6FF]" />
          <span>Sign in with Passkey / FaceID</span>
        </button>
      )}

      {!isRegistering && (
        <div className="flex items-center gap-3 my-3">
          <div className="flex-1 h-px bg-[#262626]" />
          <span className="text-[11px] text-[#666666] font-semibold uppercase tracking-wider">or with password</span>
          <div className="flex-1 h-px bg-[#262626]" />
        </div>
      )}

      <form onSubmit={isRegistering ? handleEmailSignUp : handleEmailSignIn} className="space-y-3">
        {isRegistering && (
          <div>
            <label className="block text-[11.5px] font-semibold text-[#888888] mb-1">Parent Name</label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g. Sarah"
              className="w-full bg-[#0F0F0F] border border-[#2D2D2D] rounded-xl px-3.5 py-2.5 text-white text-[13.5px] focus:outline-none focus:border-[#3EA6FF]"
              required
            />
          </div>
        )}

        <div>
          <label className="block text-[11.5px] font-semibold text-[#888888] mb-1">Email Address</label>
          <div className="relative">
            <Mail className="w-4 h-4 text-[#666666] absolute left-3.5 top-3" />
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="parent@example.com"
              className="w-full bg-[#0F0F0F] border border-[#2D2D2D] rounded-xl pl-10 pr-3.5 py-2.5 text-white text-[13.5px] focus:outline-none focus:border-[#3EA6FF]"
              required
            />
          </div>
        </div>

        <div>
          <label className="block text-[11.5px] font-semibold text-[#888888] mb-1">Password</label>
          <div className="relative">
            <Lock className="w-4 h-4 text-[#666666] absolute left-3.5 top-3" />
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              className="w-full bg-[#0F0F0F] border border-[#2D2D2D] rounded-xl pl-10 pr-3.5 py-2.5 text-white text-[13.5px] focus:outline-none focus:border-[#3EA6FF]"
              required
            />
          </div>
        </div>

        <button
          type="submit"
          disabled={loading}
          className="w-full mt-2 py-3 bg-[#3EA6FF] hover:bg-[#2995EE] disabled:opacity-40 text-black font-bold text-[13.5px] rounded-xl transition-all cursor-pointer shadow-md shadow-[#3EA6FF]/20 flex items-center justify-center gap-2"
        >
          {loading ? (
            <span>Authenticating...</span>
          ) : (
            <>
              <span>{isRegistering ? 'Create Master Account' : 'Sign In to Studio'}</span>
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
          className="text-[12px] text-[#AAAAAA] hover:text-[#3EA6FF] font-medium transition-colors cursor-pointer"
        >
          {isRegistering
            ? 'Already have an account? Sign In'
            : 'First time setup? Create Master Parent Account'}
        </button>
      </div>
    </div>
  );
};
