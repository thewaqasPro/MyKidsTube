import React, { useState, useEffect, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ActivityIndicator,
  TextInput,
  Modal,
  ScrollView,
} from 'react-native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { RootStackParamList } from '../types/navigation';
import { useAppStore } from '../store/useAppStore';
import { securityService } from '../services/SecurityService';
import { KidColors } from '../theme/colors';

type Props = NativeStackScreenProps<RootStackParamList, 'DevicePairing'>;

export const DevicePairingScreen: React.FC<Props> = ({ navigation }) => {
  const {
    pairingCode,
    requestDevicePairing,
    checkPairingStatus,
    vpsUrl,
    setVpsUrl,
  } = useAppStore();

  const [isRequesting, setIsRequesting] = useState(false);
  const [isExpired, setIsExpired] = useState(false);
  const [isTimedOut, setIsTimedOut] = useState(false);
  const [serverModalVisible, setServerModalVisible] = useState(false);
  const [customUrlInput, setCustomUrlInput] = useState(vpsUrl);

  const pollTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const pollIntervalRef = useRef(2500);
  const totalElapsedRef = useRef(0);

  useEffect(() => {
    startPairing();
    return () => {
      if (pollTimerRef.current) {
        clearTimeout(pollTimerRef.current);
      }
    };
  }, []);

  const startPairing = async () => {
    if (pollTimerRef.current) {
      clearTimeout(pollTimerRef.current);
    }
    setIsRequesting(true);
    setIsExpired(false);
    setIsTimedOut(false);
    pollIntervalRef.current = 2500;
    totalElapsedRef.current = 0;

    const code = await requestDevicePairing('Kids Tablet');
    setIsRequesting(false);

    if (code) {
      schedulePoll();
    } else {
      setIsExpired(true);
    }
  };

  const schedulePoll = () => {
    if (pollTimerRef.current) {
      clearTimeout(pollTimerRef.current);
    }

    pollTimerRef.current = setTimeout(async () => {
      totalElapsedRef.current += Math.ceil(pollIntervalRef.current / 1000);

      // 5-minute timeout cap (300 seconds)
      if (totalElapsedRef.current >= 300) {
        setIsTimedOut(true);
        return;
      }

      const status = await checkPairingStatus();
      if (status === 'paired') {
        const isDefault = await securityService.isUsingDefaultPin();
        if (isDefault) {
          navigation.replace('ParentSecurity', {
            isForceChange: true,
            destinationOnSuccess: 'KidHome',
          });
        } else {
          navigation.replace('KidHome');
        }
        return;
      } else if (status === 'expired') {
        setIsExpired(true);
        return;
      }

      // Exponential backoff capped at 10 seconds
      pollIntervalRef.current = Math.min(
        10000,
        Math.round(pollIntervalRef.current * 1.25)
      );
      schedulePoll();
    }, pollIntervalRef.current);
  };

  const formatCode = (code: string | null) => {
    if (!code) return '--- ---';
    if (code.length === 6) {
      return `${code.slice(0, 3)} - ${code.slice(3)}`;
    }
    return code;
  };

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <View style={styles.card}>
        <Text style={styles.appIcon}>📺</Text>
        <Text style={styles.title}>Pair This Tablet</Text>
        <Text style={styles.subtitle}>
          Open the Parent Portal on your phone or computer and enter this code to connect:
        </Text>

        {/* Pairing Code Display */}
        <View style={styles.codeContainer}>
          {isRequesting ? (
            <ActivityIndicator size="large" color={KidColors.primary} />
          ) : (
            <Text style={styles.codeText}>{formatCode(pairingCode)}</Text>
          )}
        </View>

        {/* Status Messages */}
        {isTimedOut ? (
          <View style={styles.statusBox}>
            <Text style={styles.statusError}>Pairing timed out (5 minutes).</Text>
            <TouchableOpacity
              onPress={startPairing}
              style={styles.actionButton}
            >
              <Text style={styles.actionButtonText}>Generate New Code</Text>
            </TouchableOpacity>
          </View>
        ) : isExpired ? (
          <View style={styles.statusBox}>
            <Text style={styles.statusError}>
              Pairing code expired or server unreachable.
            </Text>
            <TouchableOpacity
              onPress={startPairing}
              style={styles.actionButton}
            >
              <Text style={styles.actionButtonText}>Generate New Code</Text>
            </TouchableOpacity>
          </View>
        ) : (
          <View style={styles.pollingBox}>
            <ActivityIndicator size="small" color={KidColors.accent} />
            <Text style={styles.pollingText}>
              Waiting for parent authorization...
            </Text>
          </View>
        )}

        {/* Server Endpoint Config Link */}
        <TouchableOpacity
          onPress={() => {
            setCustomUrlInput(vpsUrl);
            setServerModalVisible(true);
          }}
          style={styles.serverLink}
        >
          <Text style={styles.serverLinkText}>⚙️ Server: {vpsUrl}</Text>
        </TouchableOpacity>
      </View>

      {/* Server URL Change Modal */}
      <Modal
        visible={serverModalVisible}
        transparent
        animationType="fade"
        onRequestClose={() => setServerModalVisible(false)}
      >
        <View style={styles.modalBackdrop}>
          <View style={styles.modalCard}>
            <Text style={styles.modalTitle}>Configure Server URL</Text>
            <Text style={styles.modalSubtitle}>
              Default is Cloudflare edge API. You can change this to your custom host:
            </Text>
            <TextInput
              style={styles.modalInput}
              value={customUrlInput}
              onChangeText={setCustomUrlInput}
              autoCapitalize="none"
              autoCorrect={false}
              placeholder="https://mykidstube.kidstube.workers.dev"
              placeholderTextColor={KidColors.textTertiary}
            />
            <View style={styles.modalButtonRow}>
              <TouchableOpacity
                onPress={() => setServerModalVisible(false)}
                style={[styles.modalBtn, styles.modalCancelBtn]}
              >
                <Text style={styles.modalCancelText}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity
                onPress={async () => {
                  await setVpsUrl(customUrlInput);
                  setServerModalVisible(false);
                  startPairing();
                }}
                style={[styles.modalBtn, styles.modalSaveBtn]}
              >
                <Text style={styles.modalSaveText}>Save & Reconnect</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flexGrow: 1,
    backgroundColor: KidColors.bgDark,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
  },
  card: {
    backgroundColor: KidColors.cardDark,
    borderRadius: 28,
    padding: 28,
    width: '100%',
    maxWidth: 420,
    alignItems: 'center',
    borderWidth: 1.5,
    borderColor: KidColors.borderDark,
    shadowColor: '#000',
    shadowOpacity: 0.6,
    shadowRadius: 20,
    elevation: 12,
  },
  appIcon: {
    fontSize: 56,
    marginBottom: 12,
  },
  title: {
    color: KidColors.textLight,
    fontSize: 24,
    fontWeight: '800',
    marginBottom: 8,
  },
  subtitle: {
    color: KidColors.textMuted,
    fontSize: 14,
    textAlign: 'center',
    marginBottom: 24,
    lineHeight: 20,
  },
  codeContainer: {
    backgroundColor: KidColors.cardElevated,
    borderRadius: 20,
    borderWidth: 2,
    borderColor: KidColors.sky,
    paddingVertical: 18,
    paddingHorizontal: 28,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 24,
    width: '100%',
  },
  codeText: {
    color: KidColors.textLight,
    fontSize: 34,
    fontWeight: '900',
    letterSpacing: 4,
    fontFamily: 'monospace',
  },
  pollingBox: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    marginBottom: 20,
  },
  pollingText: {
    color: KidColors.textMuted,
    fontSize: 13,
    fontWeight: '600',
  },
  statusBox: {
    alignItems: 'center',
    marginBottom: 20,
    width: '100%',
  },
  statusError: {
    color: KidColors.primary,
    fontSize: 13,
    fontWeight: '700',
    marginBottom: 12,
    textAlign: 'center',
  },
  actionButton: {
    backgroundColor: KidColors.primary,
    paddingVertical: 12,
    paddingHorizontal: 24,
    borderRadius: 16,
  },
  actionButtonText: {
    color: '#FFF',
    fontWeight: '800',
    fontSize: 14,
  },
  serverLink: {
    marginTop: 8,
    padding: 6,
  },
  serverLinkText: {
    color: KidColors.textTertiary,
    fontSize: 12,
    textDecorationLine: 'underline',
  },
  modalBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.75)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
  },
  modalCard: {
    backgroundColor: KidColors.cardDark,
    borderRadius: 24,
    padding: 24,
    width: '100%',
    maxWidth: 380,
    borderWidth: 1.2,
    borderColor: KidColors.borderDark,
  },
  modalTitle: {
    color: KidColors.textLight,
    fontSize: 18,
    fontWeight: '800',
    marginBottom: 8,
  },
  modalSubtitle: {
    color: KidColors.textMuted,
    fontSize: 13,
    marginBottom: 16,
    lineHeight: 18,
  },
  modalInput: {
    backgroundColor: KidColors.bgDark,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: KidColors.borderDark,
    padding: 12,
    color: KidColors.textLight,
    fontSize: 14,
    marginBottom: 18,
  },
  modalButtonRow: {
    flexDirection: 'row',
    gap: 12,
  },
  modalBtn: {
    flex: 1,
    height: 44,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  modalCancelBtn: {
    backgroundColor: KidColors.cardElevated,
    borderWidth: 1,
    borderColor: KidColors.borderDark,
  },
  modalCancelText: {
    color: KidColors.textMuted,
    fontWeight: '700',
  },
  modalSaveBtn: {
    backgroundColor: KidColors.sky,
  },
  modalSaveText: {
    color: KidColors.bgDark,
    fontWeight: '800',
  },
});
