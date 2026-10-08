import React from 'react';
import { Trash2, Loader2, CheckCircle2, AlertCircle, X, StopCircle } from 'lucide-react';

export interface BulkDeleteProgressItem {
  id: string;
  title: string;
  status: 'pending' | 'deleting' | 'success' | 'error';
  error?: string;
}

interface BulkDeleteProgressModalProps {
  isOpen: boolean;
  total: number;
  current: number;
  currentTitle: string;
  isProcessing: boolean;
  successCount: number;
  failedCount: number;
  errors: Array<{ id: string; title: string; error: string }>;
  onCancel: () => void;
  onClose: () => void;
}

export const BulkDeleteProgressModal: React.FC<BulkDeleteProgressModalProps> = ({
  isOpen,
  total,
  current,
  currentTitle,
  isProcessing,
  successCount,
  failedCount,
  errors,
  onCancel,
  onClose,
}) => {
  if (!isOpen) return null;

  const percent = total > 0 ? Math.min(100, Math.round((current / total) * 100)) : 0;
  const isFinished = !isProcessing && (current >= total || failedCount + successCount >= total);

  return (
    <div
      role="dialog"
      aria-modal="true"
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-fade-in"
    >
      <div className="relative w-full max-w-lg bg-surface border-2 border-border rounded-[32px] p-6 sm:p-7 shadow-2xl text-white animate-scale-up">
        {/* Close Button when finished */}
        {isFinished && (
          <button
            type="button"
            onClick={onClose}
            aria-label="Close dialog"
            className="absolute top-4 right-4 p-2 rounded-full text-text-secondary hover:text-white hover:bg-surface-hover transition-colors"
          >
            <X className="w-4 h-4" />
          </button>
        )}

        {/* Header */}
        <div className="flex items-center gap-3.5 mb-5">
          <div
            className={`w-12 h-12 rounded-2xl flex items-center justify-center shrink-0 border-2 shadow-md transition-all ${
              isFinished && failedCount === 0
                ? 'bg-emerald-500/15 border-emerald-500/30 text-emerald-400 shadow-emerald-500/10'
                : failedCount > 0 && isFinished
                ? 'bg-amber-500/15 border-amber-500/30 text-amber-400 shadow-amber-500/10'
                : 'bg-coral/15 border-coral/30 text-coral shadow-coral/10'
            }`}
          >
            {isFinished ? (
              failedCount === 0 ? (
                <CheckCircle2 className="w-6 h-6 text-emerald-400" />
              ) : (
                <AlertCircle className="w-6 h-6 text-amber-400" />
              )
            ) : (
              <Trash2 className="w-6 h-6" />
            )}
          </div>
          <div className="flex-1 min-w-0">
            <h3 className="text-xl font-display font-black text-white tracking-wide truncate">
              {isFinished ? 'Deletion Completed' : 'Deleting Videos from Catalog'}
            </h3>
            <p className="text-xs text-text-secondary font-medium">
              {isFinished
                ? `${successCount} video(s) permanently removed.`
                : `Deleting one by one to ensure database consistency (${current} of ${total})...`}
            </p>
          </div>
        </div>

        {/* Progress Bar Container */}
        <div className="bg-canvas-deep border border-border rounded-2xl p-4 mb-4">
          <div className="flex items-center justify-between text-xs font-bold mb-2">
            <span className="text-text-secondary">Progress</span>
            <span className="text-coral font-black">{percent}%</span>
          </div>

          <div className="w-full h-3 bg-surface rounded-full overflow-hidden border border-border/50 relative">
            <div
              className="h-full bg-gradient-to-r from-coral via-coral-hover to-sun transition-all duration-300 ease-out rounded-full"
              style={{ width: `${percent}%` }}
            />
          </div>

          {/* Current Video being processed */}
          {isProcessing && currentTitle && (
            <div className="mt-3.5 flex items-center gap-2.5 text-xs text-text-secondary truncate">
              <Loader2 className="w-3.5 h-3.5 text-coral animate-spin shrink-0" />
              <span className="truncate">
                Current: <strong className="text-white font-medium">{currentTitle}</strong>
              </span>
            </div>
          )}
        </div>

        {/* Stats Summary Pills */}
        <div className="grid grid-cols-3 gap-2.5 mb-5 text-center">
          <div className="bg-canvas-deep border border-border rounded-xl p-2.5">
            <div className="text-[11px] uppercase tracking-wider text-text-secondary font-bold">Total</div>
            <div className="text-base font-display font-black text-white">{total}</div>
          </div>
          <div className="bg-canvas-deep border border-emerald-500/20 rounded-xl p-2.5">
            <div className="text-[11px] uppercase tracking-wider text-emerald-400 font-bold">Deleted</div>
            <div className="text-base font-display font-black text-emerald-400">{successCount}</div>
          </div>
          <div className="bg-canvas-deep border border-coral/20 rounded-xl p-2.5">
            <div className="text-[11px] uppercase tracking-wider text-coral font-bold">Failed</div>
            <div className="text-base font-display font-black text-coral">{failedCount}</div>
          </div>
        </div>

        {/* Errors list if any failed */}
        {errors.length > 0 && (
          <div className="mb-5 max-h-36 overflow-y-auto space-y-1.5 p-3 rounded-2xl bg-red-950/30 border border-red-500/20 text-xs">
            <div className="font-bold text-red-300 mb-1 flex items-center gap-1.5">
              <AlertCircle className="w-3.5 h-3.5" />
              <span>Failed to delete {errors.length} video(s):</span>
            </div>
            {errors.map((err, i) => (
              <div key={i} className="text-text-secondary flex items-start gap-1.5 text-[11px]">
                <span className="text-red-400 font-bold">•</span>
                <span className="text-white font-medium truncate max-w-[200px]">{err.title}:</span>
                <span className="text-red-300 truncate">{err.error}</span>
              </div>
            ))}
          </div>
        )}

        {/* Action Buttons */}
        <div className="flex items-center justify-end gap-3 pt-1 border-t border-border/50">
          {isProcessing ? (
            <button
              type="button"
              onClick={onCancel}
              className="px-4 py-2.5 rounded-full text-xs font-bold text-coral bg-coral/10 hover:bg-coral/20 border border-coral/30 transition-colors flex items-center gap-1.5 cursor-pointer"
            >
              <StopCircle className="w-4 h-4" />
              <span>Stop Remaining</span>
            </button>
          ) : (
            <button
              type="button"
              onClick={onClose}
              className="px-6 py-2.5 rounded-full text-xs font-display font-black text-white bg-gradient-to-r from-coral to-coral-hover hover:from-coral-hover hover:to-coral transition-all cursor-pointer shadow-lg shadow-coral/30"
            >
              Done
            </button>
          )}
        </div>
      </div>
    </div>
  );
};
