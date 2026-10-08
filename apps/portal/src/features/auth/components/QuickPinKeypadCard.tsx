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
                  ? 'bg-gradient-to-tr from-coral to-sun scale-125 shadow-md shadow-coral/50'
                  : 'bg-canvas-deep border-2 border-border'
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
            className="h-13 rounded-2xl bg-canvas-deep hover:bg-surface-hover active:translate-y-0.5 active:scale-95 font-display font-black text-xl text-white border-2 border-border hover:border-sky transition-all cursor-pointer select-none shadow-sm"
          >
            {digit}
          </button>
        ))}
        <button
          type="button"
          onClick={handleBackspace}
          className="h-13 rounded-2xl bg-canvas-deep hover:bg-surface-hover text-xs font-bold text-text-secondary hover:text-white border-2 border-border transition-all cursor-pointer select-none flex items-center justify-center active:scale-95"
        >
          Delete
        </button>
        <button
          type="button"
          onClick={() => handleDigit('0')}
          className="h-13 rounded-2xl bg-canvas-deep hover:bg-surface-hover active:translate-y-0.5 active:scale-95 font-display font-black text-xl text-white border-2 border-border hover:border-sky transition-all cursor-pointer select-none shadow-sm"
        >
          0
        </button>
        <button
          type="button"
          onClick={() => handlePinSubmit()}
          disabled={pin.length < 4 || loading}
          className="h-13 rounded-2xl bg-gradient-to-r from-coral to-coral-hover hover:from-coral-hover hover:to-coral disabled:opacity-20 disabled:pointer-events-none active:scale-95 text-xs font-display font-black text-white transition-all cursor-pointer select-none flex items-center justify-center shadow-lg shadow-coral/30 border-2 border-white/10"
        >
          <ArrowRight className="w-5 h-5" />
        </button>
      </div>
    </div>
  );
};
