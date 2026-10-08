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
      <div className="flex items-center justify-center gap-3 my-4">
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

      {/* Keypad */}
      <div className="grid grid-cols-3 gap-3 w-full my-3">
        {['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((digit) => (
          <button
            key={digit}
            type="button"
            onClick={() => handleDigit(digit)}
            className="h-12 rounded-2xl bg-[#1E1E1E] hover:bg-[#2A2A2A] active:bg-[#333333] active:scale-95 text-[18px] font-bold text-white border border-[#2D2D2D] transition-all cursor-pointer select-none"
          >
            {digit}
          </button>
        ))}
        <button
          type="button"
          onClick={handleBackspace}
          className="h-12 rounded-2xl bg-[#1E1E1E] hover:bg-[#2A2A2A] text-[13px] font-medium text-[#AAAAAA] hover:text-white border border-[#2D2D2D] transition-all cursor-pointer select-none flex items-center justify-center"
        >
          Delete
        </button>
        <button
          type="button"
          onClick={() => handleDigit('0')}
          className="h-12 rounded-2xl bg-[#1E1E1E] hover:bg-[#2A2A2A] active:bg-[#333333] active:scale-95 text-[18px] font-bold text-white border border-[#2D2D2D] transition-all cursor-pointer select-none"
        >
          0
        </button>
        <button
          type="button"
          onClick={() => handlePinSubmit()}
          disabled={pin.length < 4 || loading}
          className="h-12 rounded-2xl bg-[#3EA6FF] hover:bg-[#2995EE] disabled:opacity-30 disabled:pointer-events-none active:scale-95 text-[13px] font-bold text-black transition-all cursor-pointer select-none flex items-center justify-center shadow-md shadow-[#3EA6FF]/20"
        >
          <ArrowRight className="w-5 h-5" />
        </button>
      </div>
    </div>
  );
};
