import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  TextInput,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { RootStackParamList } from '../types/navigation';
import { useAppStore } from '../store/useAppStore';
import { vpsApiService } from '../services/VpsApiService';
import { securityService } from '../services/SecurityService';
import { KidColors } from '../theme/colors';
import { DEFAULT_VPS_URL, normalizeServerUrl } from '../utils/urlHelpers';

type Props = NativeStackScreenProps<RootStackParamList, 'ParentServer'>;

export const ParentServerScreen: React.FC<Props> = ({ navigation }) => {
  const { vpsUrl, setVpsUrl, isDevicePaired } = useAppStore();

  const [inputUrl, setInputUrl] = useState(vpsUrl);
  const [isPinging, setIsPinging] = useState(false);
  const [pingResult, setPingResult] = useState<{
    latencyMs: number | null;
    success: boolean;
  } | null>(null);
  const [hasAuthToken, setHasAuthToken] = useState(false);

  useEffect(() => {
    checkToken();
    runPing(vpsUrl);
  }, []);

  const checkToken = async () => {
    const token = await securityService.getAuthToken();
    setHasAuthToken(!!token);
  };

  const runPing = async (urlToTest: string) => {
    setIsPinging(true);
    setPingResult(null);
    const latency = await vpsApiService.pingHealth(urlToTest);
    setIsPinging(false);
    if (latency !== null) {
      setPingResult({ latencyMs: latency, success: true });
    } else {
      setPingResult({ latencyMs: null, success: false });
    }
  };

  const handleSave = async () => {
    const normalized = normalizeServerUrl(inputUrl);
    await setVpsUrl(normalized);
    Alert.alert('Server Updated', `Active API URL updated to:\n${normalized}`);
    runPing(normalized);
  };

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity
          onPress={() => navigation.goBack()}
          style={styles.backButton}
        >
          <Text style={styles.backText}>← Back</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Server & Network</Text>
        <View style={{ width: 44 }} />
      </View>

      <ScrollView contentContainerStyle={styles.scrollContent}>
        {/* Status Card */}
        <View style={styles.statusCard}>
          <Text style={styles.cardHeading}>Connection Status</Text>
          <View style={styles.row}>
            <Text style={styles.label}>Paired Status:</Text>
            <Text
              style={[
                styles.val,
                { color: isDevicePaired ? KidColors.mint : KidColors.primary },
              ]}
            >
              {isDevicePaired ? 'Connected (Paired)' : 'Unpaired'}
            </Text>
          </View>
          <View style={styles.row}>
            <Text style={styles.label}>Device Auth Token:</Text>
            <Text
              style={[
                styles.val,
                { color: hasAuthToken ? KidColors.sky : KidColors.textTertiary },
              ]}
            >
              {hasAuthToken ? 'Active (Bearer)' : 'None'}
            </Text>
          </View>
          <View style={styles.row}>
            <Text style={styles.label}>API Latency:</Text>
            {isPinging ? (
              <ActivityIndicator size="small" color={KidColors.accent} />
            ) : pingResult?.success ? (
              <Text style={[styles.val, { color: KidColors.mint }]}>
                {pingResult.latencyMs} ms (Healthy)
              </Text>
            ) : (
              <Text style={[styles.val, { color: KidColors.primary }]}>
                Unreachable
              </Text>
            )}
          </View>
        </View>

        {/* URL Configuration */}
        <View style={styles.configCard}>
          <Text style={styles.cardHeading}>Server URL Endpoint</Text>
          <Text style={styles.cardSub}>
            The tablet connects to this API for catalog sync, video metadata, and pairing status:
          </Text>

          <TextInput
            style={styles.input}
            value={inputUrl}
            onChangeText={setInputUrl}
            autoCapitalize="none"
            autoCorrect={false}
            placeholder="https://..."
            placeholderTextColor={KidColors.textTertiary}
          />

          {inputUrl.startsWith('http://') && (
            <View style={styles.warnBox}>
              <Text style={styles.warnText}>
                ⚠️ Warning: Cleartext HTTP is allowed for development only. Production requires HTTPS.
              </Text>
            </View>
          )}

          {/* Quick Presets */}
          <Text style={styles.presetLabel}>Quick Presets:</Text>
          <View style={styles.presetRow}>
            <TouchableOpacity
              onPress={() => setInputUrl(DEFAULT_VPS_URL)}
              style={styles.presetBtn}
            >
              <Text style={styles.presetText}>Edge Production</Text>
            </TouchableOpacity>
            <TouchableOpacity
              onPress={() => setInputUrl('http://10.0.2.2:4321')}
              style={styles.presetBtn}
            >
              <Text style={styles.presetText}>Android Emulator</Text>
            </TouchableOpacity>
            <TouchableOpacity
              onPress={() => setInputUrl('http://localhost:4321')}
              style={styles.presetBtn}
            >
              <Text style={styles.presetText}>iOS Simulator</Text>
            </TouchableOpacity>
          </View>

          {/* Buttons */}
          <View style={styles.btnRow}>
            <TouchableOpacity
              onPress={() => runPing(inputUrl)}
              style={styles.testBtn}
            >
              <Text style={styles.testBtnText}>Test Ping</Text>
            </TouchableOpacity>
            <TouchableOpacity
              onPress={handleSave}
              style={styles.saveBtn}
            >
              <Text style={styles.saveBtnText}>Save Endpoint</Text>
            </TouchableOpacity>
          </View>
        </View>
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: KidColors.bgDark,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingTop: 16,
    paddingBottom: 12,
    borderBottomWidth: 1,
    borderColor: KidColors.borderDark,
  },
  backButton: {
    padding: 6,
  },
  backText: {
    color: KidColors.sky,
    fontWeight: '700',
    fontSize: 15,
  },
  headerTitle: {
    color: KidColors.textLight,
    fontSize: 18,
    fontWeight: '800',
  },
  scrollContent: {
    padding: 20,
    paddingBottom: 40,
  },
  statusCard: {
    backgroundColor: KidColors.cardDark,
    borderRadius: 22,
    padding: 20,
    borderWidth: 1.2,
    borderColor: KidColors.borderDark,
    marginBottom: 20,
  },
  cardHeading: {
    color: KidColors.textLight,
    fontSize: 17,
    fontWeight: '800',
    marginBottom: 14,
  },
  cardSub: {
    color: KidColors.textMuted,
    fontSize: 13,
    marginBottom: 16,
    lineHeight: 18,
  },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderColor: 'rgba(255,255,255,0.05)',
  },
  label: {
    color: KidColors.textMuted,
    fontSize: 13,
  },
  val: {
    fontWeight: '700',
    fontSize: 13,
  },
  configCard: {
    backgroundColor: KidColors.cardDark,
    borderRadius: 22,
    padding: 20,
    borderWidth: 1.2,
    borderColor: KidColors.borderDark,
  },
  input: {
    backgroundColor: KidColors.bgDark,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: KidColors.borderDark,
    paddingHorizontal: 14,
    height: 48,
    color: KidColors.textLight,
    fontSize: 14,
    marginBottom: 14,
  },
  warnBox: {
    backgroundColor: 'rgba(245, 158, 11, 0.1)',
    borderRadius: 12,
    padding: 10,
    borderWidth: 1,
    borderColor: 'rgba(245, 158, 11, 0.4)',
    marginBottom: 14,
  },
  warnText: {
    color: KidColors.accent,
    fontSize: 12,
    lineHeight: 16,
  },
  presetLabel: {
    color: KidColors.textMuted,
    fontSize: 12,
    fontWeight: '700',
    marginBottom: 8,
  },
  presetRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginBottom: 20,
  },
  presetBtn: {
    backgroundColor: KidColors.cardElevated,
    borderRadius: 12,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderWidth: 1,
    borderColor: KidColors.borderDark,
  },
  presetText: {
    color: KidColors.textMuted,
    fontSize: 12,
    fontWeight: '600',
  },
  btnRow: {
    flexDirection: 'row',
    gap: 12,
  },
  testBtn: {
    flex: 1,
    height: 48,
    borderRadius: 16,
    backgroundColor: KidColors.cardElevated,
    borderWidth: 1,
    borderColor: KidColors.borderDark,
    justifyContent: 'center',
    alignItems: 'center',
  },
  testBtnText: {
    color: KidColors.textLight,
    fontWeight: '700',
    fontSize: 14,
  },
  saveBtn: {
    flex: 1,
    height: 48,
    borderRadius: 16,
    backgroundColor: KidColors.sky,
    justifyContent: 'center',
    alignItems: 'center',
  },
  saveBtnText: {
    color: KidColors.bgDark,
    fontWeight: '800',
    fontSize: 14,
  },
});
