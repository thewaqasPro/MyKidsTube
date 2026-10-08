import React from 'react';
import { ArrowRight } from 'lucide-react';

interface QuickPinKeypadCardProps {
  pin: string;
  loading: boolean;
  handleDigit: (d: string) => void;
  handleBackspace: () => void;
  handlePinSubmit: (e?: React.FormEvent) => void;
}

export const QuickPinKeypadCard: React.FC<QuickPinKeypadCardProps> = ({
  pin,
  loading,
  handleDigit,
  handleBackspace,
  handlePinSubmit,
}) => {
  return (
    <div className="w-full flex flex-col items-center">
      {/* PIN Display Dots */}
      <div className="flex items-center justify-center gap-3.5 my-4">
        {[0, 1, 2, 3].map((idx) => {
          const hasDigit = pin.length > idx;
          return (
            <div
              key={idx}
              className={`w-4 h-4 rounded-full transition-all duration-200 ${
                hasDigit
                  ? 'bg-gradient-to-tr from-[#FF5E62] to-[#FFB300] scale-125 shadow-md shadow-[#FF5E62]/50'
                  : 'bg-[#0B0F19] border-2 border-[#1E294B]'
              }`}
            />
          );
        })}
      </div>

      {/* Keypad */}
      <div className="grid grid-cols-3 gap-3 w-full my-3">
        {['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((digit) => (
          <button
            key={digit}
            type="button"
            onClick={() => handleDigit(digit)}
            className="h-13 rounded-2xl bg-[#0B0F19] hover:bg-[#1E294B] active:translate-y-0.5 active:scale-95 font-display font-black text-xl text-white border-2 border-[#1E294B] hover:border-[#38BDF8] transition-all cursor-pointer select-none shadow-sm"
          >
            {digit}
          </button>
        ))}
        <button
          type="button"
          onClick={handleBackspace}
          className="h-13 rounded-2xl bg-[#0B0F19] hover:bg-[#1E294B] text-xs font-bold text-[#94A3B8] hover:text-white border-2 border-[#1E294B] transition-all cursor-pointer select-none flex items-center justify-center active:scale-95"
        >
          Delete
        </button>
        <button
          type="button"
          onClick={() => handleDigit('0')}
          className="h-13 rounded-2xl bg-[#0B0F19] hover:bg-[#1E294B] active:translate-y-0.5 active:scale-95 font-display font-black text-xl text-white border-2 border-[#1E294B] hover:border-[#38BDF8] transition-all cursor-pointer select-none shadow-sm"
        >
          0
        </button>
        <button
          type="button"
          onClick={() => handlePinSubmit()}
          disabled={pin.length < 4 || loading}
          className="h-13 rounded-2xl bg-gradient-to-r from-[#FF5E62] to-[#FF8E53] hover:from-[#FF8E53] hover:to-[#FF5E62] disabled:opacity-20 disabled:pointer-events-none active:scale-95 text-xs font-display font-black text-white transition-all cursor-pointer select-none flex items-center justify-center shadow-lg shadow-[#FF5E62]/30 border-2 border-white/10"
        >
          <ArrowRight className="w-5 h-5" />
        </button>
      </div>
    </div>
  );
};
