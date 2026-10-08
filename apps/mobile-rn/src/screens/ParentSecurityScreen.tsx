import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  Alert,
} from 'react-native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { RootStackParamList } from '../types/navigation';
import { securityService } from '../services/SecurityService';
import { KidColors } from '../theme/colors';

type Props = NativeStackScreenProps<RootStackParamList, 'ParentSecurity'>;

export const ParentSecurityScreen: React.FC<Props> = ({ route, navigation }) => {
  const isForceChange = route.params?.isForceChange ?? false;
  const destinationOnSuccess = route.params?.destinationOnSuccess ?? 'ParentDashboard';

  const [currentPin, setCurrentPin] = useState('');
  const [newPin, setNewPin] = useState('');
  const [confirmPin, setConfirmPin] = useState('');
  const [errorMessage, setErrorMessage] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async () => {
    setErrorMessage('');

    if (!isForceChange) {
      if (!currentPin) {
        setErrorMessage('Please enter your current PIN.');
        return;
      }
      const isCurrentValid = await securityService.verifyPin(currentPin);
      if (!isCurrentValid) {
        setErrorMessage('Current PIN is incorrect.');
        return;
      }
    }

    if (!newPin || newPin.trim().length < 4) {
      setErrorMessage('New PIN must be at least 4 digits.');
      return;
    }

    if (newPin !== confirmPin) {
      setErrorMessage('New PIN and confirmation do not match.');
      return;
    }

    if (newPin === '1234') {
      setErrorMessage('Please choose a PIN other than the default 1234.');
      return;
    }

    try {
      setIsSubmitting(true);
      await securityService.changePin(newPin);
      setIsSubmitting(false);

      Alert.alert(
        'PIN Updated',
        'Your secure parent PIN has been successfully saved.',
        [
          {
            text: 'Continue',
            onPress: () => {
              if (destinationOnSuccess === 'KidHome') {
                navigation.replace('KidHome');
              } else {
                navigation.replace('ParentDashboard');
              }
            },
          },
        ]
      );
    } catch (e: any) {
      setIsSubmitting(false);
      setErrorMessage(e?.message || 'Failed to update PIN.');
    }
  };

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <View style={styles.card}>
        <Text style={styles.icon}>{isForceChange ? '🔐' : '🛡️'}</Text>
        <Text style={styles.title}>
          {isForceChange ? 'Set Your Secure PIN' : 'Parent Security & PIN'}
        </Text>
        <Text style={styles.subtitle}>
          {isForceChange
            ? 'For your child’s safety, you must set a private Parent PIN before continuing.'
            : 'Your parent controls are securely protected with salted cryptographic storage.'}
        </Text>

        {/* Security Info Box */}
        <View style={styles.infoBox}>
          <Text style={styles.infoText}>
            • PIN is salted with 16 random cryptographic bytes and hashed with SHA-256.
          </Text>
          <Text style={styles.infoText}>
            • Plaintext PIN is never stored or logged anywhere on device.
          </Text>
          <Text style={styles.infoText}>
            • Minimum 4 digits required for parental control gate.
          </Text>
        </View>

        {/* Form Inputs */}
        {!isForceChange && (
          <View style={styles.fieldGroup}>
            <Text style={styles.fieldLabel}>Current PIN</Text>
            <TextInput
              style={styles.input}
              value={currentPin}
              onChangeText={setCurrentPin}
              placeholder="Enter current PIN"
              placeholderTextColor={KidColors.textTertiary}
              keyboardType="number-pad"
              secureTextEntry
              maxLength={8}
            />
          </View>
        )}

        <View style={styles.fieldGroup}>
          <Text style={styles.fieldLabel}>New PIN (min 4 digits)</Text>
          <TextInput
            style={styles.input}
            value={newPin}
            onChangeText={setNewPin}
            placeholder="Enter new PIN"
            placeholderTextColor={KidColors.textTertiary}
            keyboardType="number-pad"
            secureTextEntry
            maxLength={8}
          />
        </View>

        <View style={styles.fieldGroup}>
          <Text style={styles.fieldLabel}>Confirm New PIN</Text>
          <TextInput
            style={styles.input}
            value={confirmPin}
            onChangeText={setConfirmPin}
            placeholder="Re-enter new PIN"
            placeholderTextColor={KidColors.textTertiary}
            keyboardType="number-pad"
            secureTextEntry
            maxLength={8}
          />
        </View>

        {errorMessage.length > 0 && (
          <Text style={styles.errorText}>{errorMessage}</Text>
        )}

        <TouchableOpacity
          disabled={isSubmitting}
          onPress={handleSubmit}
          style={[styles.submitButton, isSubmitting && { opacity: 0.6 }]}
        >
          <Text style={styles.submitButtonText}>
            {isForceChange ? 'Save PIN & Enter App' : 'Save New PIN'}
          </Text>
        </TouchableOpacity>

        {!isForceChange && (
          <TouchableOpacity
            onPress={() => navigation.goBack()}
            style={styles.cancelLink}
          >
            <Text style={styles.cancelLinkText}>Back to Dashboard</Text>
          </TouchableOpacity>
        )}
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flexGrow: 1,
    backgroundColor: KidColors.bgDark,
    padding: 24,
    justifyContent: 'center',
    alignItems: 'center',
  },
  card: {
    backgroundColor: KidColors.cardDark,
    borderRadius: 28,
    padding: 28,
    width: '100%',
    maxWidth: 440,
    borderWidth: 1.2,
    borderColor: KidColors.borderDark,
    alignItems: 'center',
  },
  icon: {
    fontSize: 48,
    marginBottom: 8,
  },
  title: {
    color: KidColors.textLight,
    fontSize: 22,
    fontWeight: '800',
    marginBottom: 6,
    textAlign: 'center',
  },
  subtitle: {
    color: KidColors.textMuted,
    fontSize: 13,
    textAlign: 'center',
    marginBottom: 20,
    lineHeight: 18,
  },
  infoBox: {
    backgroundColor: KidColors.cardElevated,
    borderRadius: 16,
    padding: 14,
    borderWidth: 1,
    borderColor: KidColors.borderDark,
    marginBottom: 20,
    width: '100%',
    gap: 6,
  },
  infoText: {
    color: KidColors.textMuted,
    fontSize: 12,
    lineHeight: 16,
  },
  fieldGroup: {
    width: '100%',
    marginBottom: 14,
  },
  fieldLabel: {
    color: KidColors.textLight,
    fontSize: 13,
    fontWeight: '700',
    marginBottom: 6,
  },
  input: {
    width: '100%',
    height: 48,
    backgroundColor: KidColors.bgDark,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: KidColors.borderDark,
    paddingHorizontal: 16,
    color: KidColors.textLight,
    fontSize: 16,
  },
  errorText: {
    color: KidColors.primary,
    fontSize: 13,
    fontWeight: '700',
    marginBottom: 14,
    textAlign: 'center',
  },
  submitButton: {
    width: '100%',
    height: 50,
    backgroundColor: KidColors.primary,
    borderRadius: 16,
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 8,
  },
  submitButtonText: {
    color: '#FFF',
    fontSize: 15,
    fontWeight: '800',
  },
  cancelLink: {
    marginTop: 16,
    padding: 6,
  },
  cancelLinkText: {
    color: KidColors.textTertiary,
    fontSize: 13,
    fontWeight: '600',
  },
});
