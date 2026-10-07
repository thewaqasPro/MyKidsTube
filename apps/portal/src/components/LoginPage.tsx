import React, { useState } from 'react';
import { ShieldCheck, Lock, ArrowRight, Play, AlertCircle } from 'lucide-react';

interface LoginPageProps {
  redirectTo?: string;
}

export const LoginPage: React.FC<LoginPageProps> = ({ redirectTo = '/studio' }) => {
  const [pin, setPin] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!pin.trim()) return;

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
      setPin((prev) => prev + d);
    }
  };

  const handleBackspace = () => {
    setPin((prev) => prev.slice(0, -1));
  };

  return (
    <div className="min-h-screen bg-[#0A0A0A] text-white flex flex-col justify-center items-center p-4">
      {/* Brand Mark */}
      <div className="flex items-center gap-2 mb-8 select-none">
        <div className="flex items-center justify-center w-10 h-7.5 bg-[#FF0000] rounded-lg shadow-sm">
          <Play className="w-4 h-4 text-white fill-current ml-0.5" />
        </div>
        <span className="text-[22px] font-bold tracking-tight text-white font-sans">
          Kids<span className="text-[#FF0000]">Tube</span>
        </span>
      </div>

      {/* Card */}
      <div className="w-full max-w-sm bg-[#161616] border border-[#2A2A2A] rounded-3xl p-6 sm:p-8 shadow-2xl flex flex-col items-center text-center">
        <div className="w-14 h-14 rounded-2xl bg-[#FF0000]/10 border border-[#FF0000]/25 flex items-center justify-center text-[#FF0000] mb-4">
          <Lock className="w-6 h-6" />
        </div>

        <h2 className="text-[20px] font-bold text-white">Parental Gate</h2>
        <p className="text-[12px] text-[#888888] mt-1 max-w-[260px]">
          Enter your 4-digit Parent PIN to access YouTube Studio and video management.
        </p>

        {/* PIN Display Dots */}
        <div className="flex items-center justify-center gap-3 my-6">
          {[0, 1, 2, 3].map((idx) => {
            const hasDigit = pin.length > idx;
            return (
              <div
                key={idx}
                className={`w-4 h-4 rounded-full transition-all duration-150 ${
                  hasDigit
                    ? 'bg-[#3EA6FF] scale-110 shadow-sm shadow-[#3EA6FF]/50'
                    : 'bg-[#262626] border border-[#3A3A3A]'
                }`}
              />
            );
          })}
        </div>

        {error && (
          <div className="mb-4 w-full p-2.5 bg-red-950/60 border border-red-800 text-red-200 rounded-xl text-[12px] flex items-center justify-center gap-1.5">
            <AlertCircle className="w-4 h-4 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        {/* Keypad */}
        <div className="grid grid-cols-3 gap-3 w-full mb-6">
          {['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((digit) => (
            <button
              key={digit}
              type="button"
              onClick={() => handleDigit(digit)}
              className="h-13 rounded-2xl bg-[#1E1E1E] hover:bg-[#2A2A2A] active:bg-[#333333] active:scale-95 text-[18px] font-bold text-white border border-[#2D2D2D] transition-all cursor-pointer select-none"
            >
              {digit}
            </button>
          ))}
          <button
            type="button"
            onClick={handleBackspace}
            className="h-13 rounded-2xl bg-[#1E1E1E] hover:bg-[#2A2A2A] text-[13px] font-medium text-[#AAAAAA] hover:text-white border border-[#2D2D2D] transition-all cursor-pointer select-none flex items-center justify-center"
          >
            Delete
          </button>
          <button
            type="button"
            onClick={() => handleDigit('0')}
            className="h-13 rounded-2xl bg-[#1E1E1E] hover:bg-[#2A2A2A] active:bg-[#333333] active:scale-95 text-[18px] font-bold text-white border border-[#2D2D2D] transition-all cursor-pointer select-none"
          >
            0
          </button>
          <button
            type="button"
            onClick={handleSubmit}
            disabled={pin.length < 4 || loading}
            className="h-13 rounded-2xl bg-[#3EA6FF] hover:bg-[#2995EE] disabled:opacity-30 disabled:pointer-events-none active:scale-95 text-[13px] font-bold text-black transition-all cursor-pointer select-none flex items-center justify-center shadow-md shadow-[#3EA6FF]/20"
          >
            <ArrowRight className="w-5 h-5" />
          </button>
        </div>

        <div className="text-[11px] text-[#777777] flex items-center gap-1">
          <ShieldCheck className="w-3.5 h-3.5 text-emerald-400" />
          <span>Protected parental management session</span>
        </div>
      </div>
    </div>
  );
};
