import { useState } from 'react';
import { authClient } from '@/lib/auth-client';

export function useStudioSecurity() {
  const [passkeysList, setPasskeysList] = useState<any[]>([]);
  const [loadingPasskeys, setLoadingPasskeys] = useState(false);
  const [registeringPasskey, setRegisteringPasskey] = useState(false);
  const [newPasskeyName, setNewPasskeyName] = useState('');
  const [isAddingPasskeyOpen, setIsAddingPasskeyOpen] = useState(false);
  const [passkeyNotice, setPasskeyNotice] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  const [sessionsList, setSessionsList] = useState<any[]>([]);
  const [loadingSessions, setLoadingSessions] = useState(false);
  const [revokingSessionId, setRevokingSessionId] = useState<string | null>(null);

  const [pinStatus, setPinStatus] = useState<{ hasCustomPin: boolean; pinLength: number } | null>(null);
  const [newPin, setNewPin] = useState('');
  const [confirmPin, setConfirmPin] = useState('');
  const [showPin, setShowPin] = useState(false);
  const [isUpdatingPin, setIsUpdatingPin] = useState(false);
  const [pinNotice, setPinNotice] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  const fetchPasskeys = async () => {
    setLoadingPasskeys(true);
    try {
      const res = await authClient.passkey.listUserPasskeys();
      if (res && 'data' in res && Array.isArray(res.data)) {
        setPasskeysList(res.data);
      }
    } catch (err) {
      console.warn('Could not list passkeys:', err);
    } finally {
      setLoadingPasskeys(false);
    }
  };

  const fetchSessions = async () => {
    setLoadingSessions(true);
    try {
      const res = await authClient.listSessions();
      if (res && 'data' in res && Array.isArray(res.data)) {
        setSessionsList(res.data);
      }
    } catch (err) {
      console.warn('Could not list sessions:', err);
    } finally {
      setLoadingSessions(false);
    }
  };

  const fetchPinStatus = async () => {
    try {
      const res = await fetch('/api/studio/pin');
      if (res.ok) setPinStatus(await res.json());
    } catch (err) {
      console.warn('Could not fetch pin status:', err);
    }
  };

  const handleRegisterPasskey = async (e: React.FormEvent) => {
    e.preventDefault();
    setRegisteringPasskey(true);
    setPasskeyNotice(null);
    try {
      const res = await authClient.passkey.addPasskey({
        name: newPasskeyName.trim() || 'My Passkey',
      });
      if (res?.error) throw new Error(res.error.message || 'Registration failed.');
      setPasskeyNotice({ message: 'Passkey registered successfully! You can now use FaceID/TouchID.', type: 'success' });
      setNewPasskeyName('');
      setIsAddingPasskeyOpen(false);
      fetchPasskeys();
    } catch (err: any) {
      setPasskeyNotice({ message: err.message || 'Passkey enrollment failed.', type: 'error' });
    } finally {
      setRegisteringPasskey(false);
    }
  };

  const handleDeletePasskey = async (id: string, name: string) => {
    try {
      const res = await authClient.passkey.deletePasskey({ id });
      if (res?.error) throw new Error(res.error.message);
      setPasskeysList((prev) => prev.filter((p) => p.id !== id));
      setPasskeyNotice({ message: `Passkey "${name}" removed.`, type: 'success' });
    } catch (err: any) {
      setPasskeyNotice({ message: err.message || 'Could not delete passkey.', type: 'error' });
    }
  };

  const handleUpdatePin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!/^\d{4,6}$/.test(newPin)) return setPinNotice({ message: 'PIN must be 4–6 digits.', type: 'error' });
    if (newPin !== confirmPin) return setPinNotice({ message: 'PINs do not match.', type: 'error' });
    setIsUpdatingPin(true);
    setPinNotice(null);
    try {
      const res = await fetch('/api/studio/pin', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ pin: newPin }),
      });
      if (!res.ok) {
        const errData = (await res.json().catch(() => ({}))) as { error?: string };
        throw new Error(errData.error || 'Failed to update PIN.');
      }
      setPinNotice({ message: 'Parent PIN updated successfully!', type: 'success' });
      setNewPin('');
      setConfirmPin('');
      fetchPinStatus();
    } catch (err: any) {
      setPinNotice({ message: err.message || 'Failed to update PIN.', type: 'error' });
    } finally {
      setIsUpdatingPin(false);
    }
  };

  const handleRevokeSession = async (token: string) => {
    setRevokingSessionId(token);
    try {
      await authClient.revokeSession({ token });
      setSessionsList((prev) => prev.filter((s) => s.token !== token));
    } finally {
      setRevokingSessionId(null);
    }
  };

  const handleRevokeOtherSessions = async () => {
    await authClient.revokeOtherSessions();
    fetchSessions();
  };

  const handleSignOut = async () => {
    try {
      await authClient.signOut();
    } catch {}
    document.cookie = 'kidstube_parent_session=; Path=/; Expires=Thu, 01 Jan 1970 00:00:01 GMT;';
    window.location.href = '/login';
  };

  return {
    passkeysList,
    loadingPasskeys,
    registeringPasskey,
    newPasskeyName,
    setNewPasskeyName,
    isAddingPasskeyOpen,
    setIsAddingPasskeyOpen,
    passkeyNotice,
    setPasskeyNotice,
    sessionsList,
    loadingSessions,
    revokingSessionId,
    pinStatus,
    newPin,
    setNewPin,
    confirmPin,
    setConfirmPin,
    showPin,
    setShowPin,
    isUpdatingPin,
    pinNotice,
    setPinNotice,
    fetchPasskeys,
    fetchSessions,
    fetchPinStatus,
    handleRegisterPasskey,
    handleDeletePasskey,
    handleUpdatePin,
    handleRevokeSession,
    handleRevokeOtherSessions,
    handleSignOut,
  };
}
