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
      <div className="relative w-full max-w-md bg-[#1F1F1F] border border-[#333333] rounded-2xl p-6 shadow-2xl shadow-black/90 text-white animate-scale-up">
        {/* Close Button */}
        <button
          type="button"
          onClick={onCancel}
          disabled={isDeleting}
          aria-label="Close dialog"
          className="absolute top-4 right-4 p-1.5 rounded-full text-[#888888] hover:text-white hover:bg-[#2A2A2A] transition-colors disabled:opacity-40"
        >
          <X className="w-4 h-4" />
        </button>

        {/* Warning Icon Badge */}
        <div className="flex items-center gap-3.5 mb-4">
          <div className="w-11 h-11 rounded-full bg-red-500/15 border border-red-500/30 flex items-center justify-center shrink-0 text-red-500">
            <Trash2 className="w-5 h-5" />
          </div>
          <div>
            <h3 className="text-lg font-bold text-[#F1F1F1] tracking-tight">{title}</h3>
            <span className="text-[11px] uppercase tracking-wider font-semibold text-red-400">Irreversible Action</span>
          </div>
        </div>

        {/* Description Message */}
        <p className="text-sm text-[#AAAAAA] leading-relaxed mb-3">{message}</p>

        {details && (
          <div className="bg-[#141414] border border-[#2B2B2B] rounded-xl p-3 mb-5 text-[12px] text-[#888888] flex items-start gap-2.5">
            <AlertTriangle className="w-4 h-4 text-amber-400 shrink-0 mt-0.5" />
            <span className="leading-snug">{details}</span>
          </div>
        )}

        {/* Action Buttons */}
        <div className="flex items-center justify-end gap-3 pt-2">
          <button
            type="button"
            onClick={onCancel}
            disabled={isDeleting}
            className="px-4 py-2 rounded-full text-sm font-medium text-[#D1D1D1] bg-[#2A2A2A] hover:bg-[#333333] transition-colors cursor-pointer disabled:opacity-50"
          >
            Cancel
          </button>
          <button
            type="button"
            onClick={onConfirm}
            disabled={isDeleting}
            className="px-5 py-2 rounded-full text-sm font-semibold text-white bg-[#FF0000] hover:bg-[#D90000] transition-colors flex items-center gap-2 cursor-pointer shadow-lg shadow-red-950/40 disabled:opacity-60"
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
