import { useState } from 'react';

interface UseStudioDevicesProps {
  initialProfiles?: any[];
  setModalConfig: React.Dispatch<React.SetStateAction<{
    isOpen: boolean;
    title: string;
    message: string;
    details?: string;
    confirmLabel?: string;
    action: () => Promise<void>;
  }>>;
  setNotification: React.Dispatch<React.SetStateAction<{ message: string; type: 'success' | 'error' } | null>>;
}

export function useStudioDevices({
  initialProfiles = [],
  setModalConfig,
  setNotification,
}: UseStudioDevicesProps) {
  const [devicesList, setDevicesList] = useState<any[]>([]);
  const [loadingDevices, setLoadingDevices] = useState(false);
  const [isPairingOpen, setIsPairingOpen] = useState(false);
  const [pairCode, setPairCode] = useState('');
  const [pairProfileId, setPairProfileId] = useState(
    initialProfiles && initialProfiles.length > 0 ? initialProfiles[0].id : 'kids_all'
  );
  const [pairDeviceName, setPairDeviceName] = useState('');
  const [isSubmittingPair, setIsSubmittingPair] = useState(false);
  const [pairError, setPairError] = useState<string | null>(null);
  const [pairSuccess, setPairSuccess] = useState<string | null>(null);
  const [deletingDeviceId, setDeletingDeviceId] = useState<string | null>(null);

  const fetchDevices = () => {
    setLoadingDevices(true);
    fetch('/api/studio/devices')
      .then((res) => (res.ok ? res.json() : []))
      .then((data: any) => setDevicesList(Array.isArray(data) ? data : []))
      .catch(() => setDevicesList([]))
      .finally(() => setLoadingDevices(false));
  };

  const handlePairDevice = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!pairCode.trim()) return setPairError('Please enter the pairing code.');
    setIsSubmittingPair(true);
    setPairError(null);
    setPairSuccess(null);
    try {
      const res = await fetch('/api/pair', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          pairing_code: pairCode.trim(),
          profile_id: pairProfileId,
          device_name: pairDeviceName.trim() || 'Kids Tablet',
        }),
      });
      const data = (await res.json().catch(() => ({}))) as { error?: string };
      if (!res.ok) setPairError(data.error || 'Failed to pair device.');
      else {
        setPairSuccess(`Device paired successfully!`);
        setPairCode('');
        setPairDeviceName('');
        fetchDevices();
      }
    } finally {
      setIsSubmittingPair(false);
    }
  };

  const handleUnpairDevice = (deviceId: string, devName: string) => {
    setModalConfig({
      isOpen: true,
      title: 'Unpair Tablet / Device?',
      message: `Are you sure you want to disconnect "${devName}"?`,
      confirmLabel: 'Unpair Device',
      action: async () => {
        setDeletingDeviceId(deviceId);
        try {
          const res = await fetch('/api/studio/devices', {
            method: 'DELETE',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ id: deviceId }),
          });
          if (res.ok) {
            setDevicesList((prev) => prev.filter((d) => d.id !== deviceId));
            setNotification({ message: `Device "${devName}" unpaired.`, type: 'success' });
            setTimeout(() => setNotification(null), 4000);
          }
        } finally {
          setDeletingDeviceId(null);
        }
      },
    });
  };

  return {
    devicesList,
    loadingDevices,
    isPairingOpen,
    setIsPairingOpen,
    pairCode,
    setPairCode,
    pairProfileId,
    setPairProfileId,
    pairDeviceName,
    setPairDeviceName,
    isSubmittingPair,
    pairError,
    pairSuccess,
    deletingDeviceId,
    fetchDevices,
    handlePairDevice,
    handleUnpairDevice,
  };
}
