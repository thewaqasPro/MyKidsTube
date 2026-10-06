import React, { useState, useEffect } from 'react';
import { X, Cookie, CheckCircle, AlertTriangle, Upload, RefreshCw } from 'lucide-react';

interface CookiesModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const CookiesModal: React.FC<CookiesModalProps> = ({ isOpen, onClose }) => {
  const [status, setStatus] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [cookiesText, setCookiesText] = useState('');
  const [actionMsg, setActionMsg] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  const fetchStatus = async () => {
    setLoading(true);
    try {
      const res = await fetch('/api/cookies');
      const data = await res.json();
      setStatus(data);
    } catch {
      setStatus({ configured: false, valid_cookies_count: 0 });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (isOpen) {
      fetchStatus();
      setActionMsg(null);
    }
  }, [isOpen]);

  if (!isOpen) return null;

  const handleUpload = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!cookiesText.trim()) return;

    setLoading(true);
    try {
      const res = await fetch('/api/cookies', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ cookies_content: cookiesText }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.detail || 'Failed to save cookies');
      setActionMsg({ type: 'success', text: 'Cookies uploaded and saved to backend!' });
      setCookiesText('');
      fetchStatus();
    } catch (err: any) {
      setActionMsg({ type: 'error', text: err.message || 'Failed to save cookies' });
    } finally {
      setLoading(false);
    }
  };

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (event) => {
      const content = event.target?.result as string;
      if (content) setCookiesText(content);
    };
    reader.readAsText(file);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm p-4">
      <div className="w-full max-w-lg bg-[#1F1F1F] border border-[#333333] rounded-2xl shadow-2xl p-6 text-white animate-in fade-in zoom-in-95 duration-150">
        <div className="flex items-center justify-between pb-4 border-b border-[#2C2C2C]">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-amber-500/20 text-amber-400 flex items-center justify-center">
              <Cookie className="w-4 h-4" />
            </div>
            <div>
              <h3 className="text-[17px] font-bold">YouTube Cookies Manager</h3>
              <p className="text-[12px] text-[#AAAAAA]">Bypasses bot verification & age-restrictions</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1 rounded-full text-[#AAAAAA] hover:text-white hover:bg-[#2A2A2A] transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Current Status Box */}
        <div className="mt-4 p-4 rounded-xl bg-[#141414] border border-[#2E2E2E] flex items-center justify-between">
          <div className="flex items-center gap-3">
            {status?.configured ? (
              <CheckCircle className="w-6 h-6 text-emerald-400 shrink-0" />
            ) : (
              <AlertTriangle className="w-6 h-6 text-amber-400 shrink-0" />
            )}
            <div>
              <h4 className="text-[14px] font-semibold text-white">
                {status?.configured ? 'Cookies Active' : 'No Cookies Active'}
              </h4>
              <p className="text-[12px] text-[#AAAAAA]">
                {status?.configured
                  ? `${status.valid_cookies_count} cookie lines loaded into yt-dlp`
                  : 'Add cookies.txt to prevent bot detection'}
              </p>
            </div>
          </div>
          <button
            onClick={fetchStatus}
            disabled={loading}
            className="p-2 rounded-lg bg-[#222222] hover:bg-[#2C2C2C] text-[#AAAAAA] hover:text-white transition-colors"
            title="Refresh status"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>

        {actionMsg && (
          <div
            className={`mt-3 p-3 rounded-xl text-[13px] border ${
              actionMsg.type === 'success'
                ? 'bg-emerald-950/40 border-emerald-800 text-emerald-400'
                : 'bg-rose-950/40 border-rose-800 text-rose-400'
            }`}
          >
            {actionMsg.text}
          </div>
        )}

        {/* Upload form */}
        <form onSubmit={handleUpload} className="mt-4 space-y-4">
          <div>
            <div className="flex items-center justify-between mb-1.5">
              <label className="text-[13px] font-medium text-[#DDDDDD]">
                Upload or Paste cookies.txt
              </label>
              <label className="cursor-pointer text-[12px] text-[#3EA6FF] hover:underline flex items-center gap-1">
                <Upload className="w-3.5 h-3.5" />
                <span>Choose file</span>
                <input
                  type="file"
                  accept=".txt"
                  onChange={handleFileUpload}
                  className="hidden"
                />
              </label>
            </div>
            <textarea
              rows={5}
              value={cookiesText}
              onChange={(e) => setCookiesText(e.target.value)}
              placeholder="# Netscape HTTP Cookie File&#10;.youtube.com TRUE / FALSE 1789000000 ..."
              className="w-full p-3 bg-[#141414] border border-[#3A3A3A] focus:border-[#3EA6FF] text-[12px] font-mono text-white rounded-xl outline-none resize-none transition-colors"
            />
          </div>

          <div className="pt-2 flex justify-end gap-2.5">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2.5 rounded-xl text-[13px] font-medium text-[#AAAAAA] hover:text-white hover:bg-[#2A2A2A] transition-colors"
            >
              Close
            </button>
            <button
              type="submit"
              disabled={loading || !cookiesText.trim()}
              className="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-amber-500 hover:bg-amber-600 active:scale-95 text-black font-semibold text-[13px] transition-all cursor-pointer disabled:opacity-50"
            >
              <Cookie className="w-4 h-4" />
              <span>Save Cookies</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
