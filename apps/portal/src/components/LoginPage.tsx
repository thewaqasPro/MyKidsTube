import React, { useState } from 'react';
import {
  ShieldCheck,
  Lock,
  Play,
  AlertCircle,
  KeyRound,
  Sparkles,
} from 'lucide-react';
import { authClient } from '@/lib/auth-client';
import { MasterAccountAuthCard } from '@/features/auth/components/MasterAccountAuthCard';
import { QuickPinKeypadCard } from '@/features/auth/components/QuickPinKeypadCard';

interface LoginPageProps {
  redirectTo?: string;
}

export const LoginPage: React.FC<LoginPageProps> = ({ redirectTo = '/studio' }) => {
  const [authMode, setAuthMode] = useState<'account' | 'pin'>('account');
  const [isRegistering, setIsRegistering] = useState(false);

  // Account form state
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  // PIN form state
  const [pin, setPin] = useState('');

  // UI state
  const [error, setError] = useState('');
  const [successMsg, setSuccessMsg] = useState('');
  const [loading, setLoading] = useState(false);

  // 1. Password Sign In
  const handleEmailSignIn = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim() || !password.trim()) {
      setError('Please provide both email and password.');
      return;
    }

    setError('');
    setLoading(true);

    try {
      const res = await authClient.signIn.email({
        email: email.trim(),
        password: password.trim(),
      });

      if (res.error) {
        throw new Error(res.error.message || 'Invalid email or password.');
      }

      window.location.href = redirectTo;
    } catch (err: any) {
      setError(err.message || 'Authentication failed.');
    } finally {
      setLoading(false);
    }
  };

  // 2. Email Sign Up (First-time parent setup)
  const handleEmailSignUp = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim() || !email.trim() || !password.trim()) {
      setError('Please fill in all fields.');
      return;
    }

    if (password.length < 8) {
      setError('Password must be at least 8 characters.');
      return;
    }

    setError('');
    setLoading(true);

    try {
      const res = await authClient.signUp.email({
        name: name.trim(),
        email: email.trim(),
        password: password.trim(),
      });

      if (res.error) {
        throw new Error(res.error.message || 'Account registration failed.');
      }

      window.location.href = redirectTo;
    } catch (err: any) {
      setError(err.message || 'Registration failed.');
    } finally {
      setLoading(false);
    }
  };

  // 3. Biometric Passkey Sign In (FaceID / TouchID / Windows Hello)
  const handlePasskeySignIn = async () => {
    setError('');
    setLoading(true);

    try {
      const res = await authClient.passkey.signIn();
      if (res?.error) {
        throw new Error(res.error.message || 'Passkey verification failed.');
      }
      window.location.href = redirectTo;
    } catch (err: any) {
      console.warn('Passkey error:', err);
      setError(err.message || 'No passkey found or biometric verification cancelled.');
    } finally {
      setLoading(false);
    }
  };

  // 4. Quick PIN Submission
  const handlePinSubmit = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (!pin.trim() || pin.length < 4) return;

    setError('');
    setLoading(true);

    try {
      const res = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ pin: pin.trim() }),
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || 'Incorrect Parent PIN');
      }

      window.location.href = redirectTo;
    } catch (err: any) {
      setError(err.message || 'Incorrect PIN');
      setPin('');
    } finally {
      setLoading(false);
    }
  };

  const handleDigit = (d: string) => {
    if (pin.length < 4) {
      const next = pin + d;
      setPin(next);
      if (next.length === 4) {
        setTimeout(() => {
          handlePinSubmit();
        }, 80);
      }
    }
  };

  const handleBackspace = () => {
    setPin((prev) => prev.slice(0, -1));
  };

  return (
    <div className="min-h-screen bg-[#0A0A0A] text-white flex flex-col justify-center items-center p-4">
      {/* Brand Mark */}
      <div className="flex items-center gap-2 mb-6 select-none">
        <div className="flex items-center justify-center w-10 h-7.5 bg-[#FF0000] rounded-lg shadow-sm">
          <Play className="w-4 h-4 text-white fill-current ml-0.5" />
        </div>
        <span className="text-[22px] font-bold tracking-tight text-white font-sans">
          Kids<span className="text-[#FF0000]">Tube</span>
        </span>
      </div>

      {/* Main Card */}
      <div className="w-full max-w-md bg-[#161616] border border-[#2A2A2A] rounded-3xl p-6 sm:p-8 shadow-2xl flex flex-col items-center">
        {/* Header Icon */}
        <div className="w-13 h-13 rounded-2xl bg-[#FF0000]/10 border border-[#FF0000]/25 flex items-center justify-center text-[#FF0000] mb-3">
          <Lock className="w-6 h-6" />
        </div>

        <h2 className="text-[21px] font-bold text-white text-center">
          {authMode === 'account' ? (isRegistering ? 'Create Master Account' : 'Parent Authentication') : 'Quick Parent PIN'}
        </h2>
        <p className="text-[12.5px] text-[#888888] mt-1 text-center max-w-[280px]">
          {authMode === 'account'
            ? 'Sign in to access KidsTube Studio & administration'
            : 'Enter your 4-digit PIN for quick local access'}
        </p>

        {/* Auth Mode Toggle Pill */}
        <div className="flex bg-[#0F0F0F] p-1 rounded-2xl border border-[#2A2A2A] my-5 w-full max-w-[320px]">
          <button
            type="button"
            onClick={() => {
              setAuthMode('account');
              setError('');
            }}
            className={`flex-1 py-1.5 px-3 rounded-xl text-[12px] font-bold transition-all cursor-pointer flex items-center justify-center gap-1.5 ${
              authMode === 'account'
                ? 'bg-[#2A2A2A] text-white shadow-sm'
                : 'text-[#888888] hover:text-white'
            }`}
          >
            <KeyRound className="w-3.5 h-3.5 text-[#3EA6FF]" />
            Master Account
          </button>
          <button
            type="button"
            onClick={() => {
              setAuthMode('pin');
              setError('');
            }}
            className={`flex-1 py-1.5 px-3 rounded-xl text-[12px] font-bold transition-all cursor-pointer flex items-center justify-center gap-1.5 ${
              authMode === 'pin'
                ? 'bg-[#2A2A2A] text-white shadow-sm'
                : 'text-[#888888] hover:text-white'
            }`}
          >
            <Sparkles className="w-3.5 h-3.5 text-[#FF0000]" />
            Quick PIN
          </button>
        </div>

        {/* Error Alert */}
        {error && (
          <div className="mb-4 w-full p-2.5 bg-red-950/60 border border-red-800 text-red-200 rounded-xl text-[12px] flex items-center justify-center gap-1.5">
            <AlertCircle className="w-4 h-4 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        {/* Success Alert */}
        {successMsg && (
          <div className="mb-4 w-full p-2.5 bg-emerald-950/60 border border-emerald-800 text-emerald-200 rounded-xl text-[12px] flex items-center justify-center gap-1.5">
            <ShieldCheck className="w-4 h-4 shrink-0" />
            <span>{successMsg}</span>
          </div>
        )}

        {authMode === 'account' ? (
          <MasterAccountAuthCard
            isRegistering={isRegistering}
            setIsRegistering={setIsRegistering}
            name={name}
            setName={setName}
            email={email}
            setEmail={setEmail}
            password={password}
            setPassword={setPassword}
            loading={loading}
            handleEmailSignIn={handleEmailSignIn}
            handleEmailSignUp={handleEmailSignUp}
            handlePasskeySignIn={handlePasskeySignIn}
            setError={setError}
          />
        ) : (
          <QuickPinKeypadCard
            pin={pin}
            loading={loading}
            handleDigit={handleDigit}
            handleBackspace={handleBackspace}
            handlePinSubmit={handlePinSubmit}
          />
        )}

        <div className="mt-5 text-[11px] text-[#777777] flex items-center gap-1">
          <ShieldCheck className="w-3.5 h-3.5 text-emerald-400" />
          <span>Protected parental management session</span>
        </div>
      </div>
    </div>
  );
};
