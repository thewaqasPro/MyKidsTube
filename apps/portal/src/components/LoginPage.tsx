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
      const res = await authClient.signIn.passkey();
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

      const data = (await res.json()) as { error?: string };
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
    <div className="min-h-screen bg-canvas-deep text-text-primary flex flex-col justify-center items-center p-4">
      {/* Brand Mark: WonderKids TubeStar */}
      <a href="/" className="flex items-center gap-3 mb-6 select-none group no-underline">
        <div className="relative flex items-center justify-center w-12 h-10 rounded-2xl bg-gradient-to-tr from-coral via-coral-hover to-sun text-white shadow-lg shadow-coral/30 group-hover:scale-105 group-hover:rotate-2 transition-transform">
          {/* Antenna */}
          <div className="absolute -top-2 left-1/2 -translate-x-1/2 w-1 h-2 bg-sun rounded-full" />
          <div className="absolute -top-3 left-1/2 -translate-x-1/2 w-2 h-2 rounded-full bg-sky shadow-sm" />
          <Play className="w-5 h-5 fill-current ml-0.5 drop-shadow" />
        </div>
        <div className="flex flex-col">
          <span className="font-display font-black text-2xl tracking-wide bg-gradient-to-r from-white via-slate-100 to-sky bg-clip-text text-transparent">
            MyKids<span className="text-coral">Tube</span>
          </span>
          <span className="text-[10px] text-text-secondary font-bold tracking-widest uppercase">
            Safe • Fun • Spark Joy
          </span>
        </div>
      </a>

      {/* Main Card */}
      <div className="w-full max-w-md bg-surface border-2 border-border rounded-[32px] p-6 sm:p-8 shadow-2xl flex flex-col items-center">
        {/* Header Icon */}
        <div className="w-14 h-14 rounded-2xl bg-gradient-to-tr from-sky/20 to-violet/20 border-2 border-sky/30 flex items-center justify-center text-sky mb-3 shadow-md shadow-sky/10">
          <Lock className="w-6 h-6" />
        </div>

        <h2 className="text-2xl font-display font-black text-white text-center tracking-wide">
          {authMode === 'account' ? (isRegistering ? 'Create Master Account' : 'Parent Control Center') : 'Quick Parent PIN'}
        </h2>
        <p className="text-xs text-text-secondary mt-1.5 text-center max-w-[280px] font-medium">
          {authMode === 'account'
            ? 'Sign in to access parental settings, video controls, and playlists'
            : 'Enter your 4-digit PIN for instant access'}
        </p>

        {/* Auth Mode Toggle Pill */}
        <div className="flex bg-canvas-deep p-1.5 rounded-2xl border-2 border-border my-5 w-full max-w-[320px]">
          <button
            type="button"
            onClick={() => {
              setAuthMode('account');
              setError('');
            }}
            className={`flex-1 py-2 px-3 rounded-xl text-xs font-bold transition-all cursor-pointer flex items-center justify-center gap-1.5 ${
              authMode === 'account'
                ? 'bg-gradient-to-r from-sky to-sky-hover text-white shadow-md'
                : 'text-text-secondary hover:text-white'
            }`}
          >
            <KeyRound className="w-3.5 h-3.5" />
            Master Account
          </button>
          <button
            type="button"
            onClick={() => {
              setAuthMode('pin');
              setError('');
            }}
            className={`flex-1 py-2 px-3 rounded-xl text-xs font-bold transition-all cursor-pointer flex items-center justify-center gap-1.5 ${
              authMode === 'pin'
                ? 'bg-gradient-to-r from-coral to-coral-hover text-white shadow-md'
                : 'text-text-secondary hover:text-white'
            }`}
          >
            <Sparkles className="w-3.5 h-3.5" />
            Quick PIN
          </button>
        </div>

        {/* Error Alert */}
        {error && (
          <div className="mb-4 w-full p-3 bg-red-950/60 border border-red-800 text-red-200 rounded-2xl text-xs font-semibold flex items-center justify-center gap-2">
            <AlertCircle className="w-4 h-4 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        {/* Success Alert */}
        {successMsg && (
          <div className="mb-4 w-full p-3 bg-emerald-950/60 border border-emerald-800 text-emerald-200 rounded-2xl text-xs font-semibold flex items-center justify-center gap-2">
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

        <div className="mt-6 text-xs text-text-secondary font-bold flex items-center gap-1.5">
          <ShieldCheck className="w-4 h-4 text-mint" />
          <span>Protected parental management session</span>
        </div>
      </div>
    </div>
  );
};
