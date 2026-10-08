import React from 'react';
import { Trash2, AlertTriangle, X, Loader2 } from 'lucide-react';

interface DeleteConfirmModalProps {
  isOpen: boolean;
  title: string;
  message: string;
  details?: string;
  confirmLabel?: string;
  isDeleting?: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}

export const DeleteConfirmModal: React.FC<DeleteConfirmModalProps> = ({
  isOpen,
  title,
  message,
  details,
  confirmLabel = 'Delete Permanently',
  isDeleting = false,
  onConfirm,
  onCancel,
}) => {
  if (!isOpen) return null;

  return (
    <div
      role="dialog"
      aria-modal="true"
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-fade-in"
      onClick={(e) => {
        if (e.target === e.currentTarget && !isDeleting) {
          onCancel();
        }
      }}
    >
      <div className="relative w-full max-w-md bg-[#151D33] border-2 border-[#1E294B] rounded-[32px] p-6 sm:p-7 shadow-2xl text-white animate-scale-up">
        {/* Close Button */}
        <button
          type="button"
          onClick={onCancel}
          disabled={isDeleting}
          aria-label="Close dialog"
          className="absolute top-4 right-4 p-2 rounded-full text-[#94A3B8] hover:text-white hover:bg-[#1E294B] transition-colors disabled:opacity-40"
        >
          <X className="w-4 h-4" />
        </button>

        {/* Warning Icon Badge */}
        <div className="flex items-center gap-3.5 mb-4">
          <div className="w-12 h-12 rounded-2xl bg-[#FF5E62]/15 border-2 border-[#FF5E62]/30 flex items-center justify-center shrink-0 text-[#FF5E62] shadow-md shadow-[#FF5E62]/10">
            <Trash2 className="w-5 h-5" />
          </div>
          <div>
            <h3 className="text-xl font-display font-black text-white tracking-wide">{title}</h3>
            <span className="text-[10px] uppercase tracking-wider font-black text-[#FF5E62]">Irreversible Action</span>
          </div>
        </div>

        {/* Description Message */}
        <p className="text-xs text-[#94A3B8] leading-relaxed mb-3 font-medium">{message}</p>

        {details && (
          <div className="bg-[#0B0F19] border-2 border-[#1E294B] rounded-2xl p-3.5 mb-5 text-xs text-[#94A3B8] flex items-start gap-2.5">
            <AlertTriangle className="w-4 h-4 text-[#FFB300] shrink-0 mt-0.5" />
            <span className="leading-snug">{details}</span>
          </div>
        )}

        {/* Action Buttons */}
        <div className="flex items-center justify-end gap-3 pt-2">
          <button
            type="button"
            onClick={onCancel}
            disabled={isDeleting}
            className="px-4 py-2.5 rounded-full text-xs font-bold text-[#94A3B8] bg-[#0B0F19] hover:bg-[#1E294B] hover:text-white border border-[#1E294B] transition-colors cursor-pointer disabled:opacity-50"
          >
            Cancel
          </button>
          <button
            type="button"
            onClick={onConfirm}
            disabled={isDeleting}
            className="px-5 py-2.5 rounded-full text-xs font-display font-black text-white bg-gradient-to-r from-[#FF5E62] to-[#FF8E53] hover:from-[#FF8E53] hover:to-[#FF5E62] transition-all flex items-center gap-2 cursor-pointer shadow-lg shadow-[#FF5E62]/30 disabled:opacity-60 border border-white/10 active:scale-95"
          >
            {isDeleting ? (
              <>
                <Loader2 className="w-4 h-4 animate-spin" />
                <span>Deleting...</span>
              </>
            ) : (
              <>
                <Trash2 className="w-4 h-4" />
                <span>{confirmLabel}</span>
              </>
            )}
          </button>
        </div>
      </div>
    </div>
  );
};
