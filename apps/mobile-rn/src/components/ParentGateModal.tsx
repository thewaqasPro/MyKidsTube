import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  TextInput,
  StyleSheet,
  Modal,
  TouchableOpacity,
} from 'react-native';
import { securityService } from '../services/SecurityService';
import { KidColors } from '../theme/colors';

interface Props {
  visible: boolean;
  onClose: () => void;
  onSuccess: (isForcePinChangeRequired: boolean) => void;
}

export const ParentGateModal: React.FC<Props> = ({
  visible,
  onClose,
  onSuccess,
}) => {
  const [num1, setNum1] = useState(4);
  const [num2, setNum2] = useState(7);
  const [answerInput, setAnswerInput] = useState('');
  const [errorMessage, setErrorMessage] = useState('');

  useEffect(() => {
    if (visible) {
      const n1 = Math.floor(Math.random() * 8) + 3; // 3 to 10
      const n2 = Math.floor(Math.random() * 8) + 2; // 2 to 9
      setNum1(n1);
      setNum2(n2);
      setAnswerInput('');
      setErrorMessage('');
    }
  }, [visible]);

  const handleVerify = async () => {
    const trimmed = answerInput.trim();
    const expectedMath = num1 * num2;
    const isMathCorrect = parseInt(trimmed, 10) === expectedMath;

    // Also accepts the saved salted PIN via secure verification
    const isPinCorrect = await securityService.verifyPin(trimmed);

    if (isMathCorrect || isPinCorrect) {
      const isDefault = await securityService.isUsingDefaultPin();
      setAnswerInput('');
      setErrorMessage('');
      onSuccess(isDefault);
    } else {
      setErrorMessage('Incorrect answer. Please try again!');
      setAnswerInput('');
    }
  };

  return (
    <Modal
      visible={visible}
      transparent
      animationType="fade"
      onRequestClose={onClose}
    >
      <View style={styles.backdrop}>
        <View style={styles.card}>
          <Text style={styles.shieldIcon}>🛡️</Text>
          <Text style={styles.title}>Grown-Ups Only</Text>
          <Text style={styles.subtitle}>
            Please solve the math question or enter your Parent PIN:
          </Text>

          <View style={styles.mathContainer}>
            <Text style={styles.mathEquation}>
              {num1} × {num2} = ?
            </Text>
          </View>

          <TextInput
            style={styles.input}
            value={answerInput}
            onChangeText={setAnswerInput}
            placeholder="Answer or PIN"
            placeholderTextColor={KidColors.textTertiary}
            keyboardType="number-pad"
            autoFocus
            secureTextEntry={false}
          />

          {errorMessage.length > 0 && (
            <Text style={styles.errorText}>{errorMessage}</Text>
          )}

          <View style={styles.buttonRow}>
            <TouchableOpacity
              onPress={onClose}
              style={[styles.button, styles.cancelButton]}
            >
              <Text style={styles.cancelButtonText}>Cancel</Text>
            </TouchableOpacity>

            <TouchableOpacity
              onPress={handleVerify}
              style={[styles.button, styles.verifyButton]}
            >
              <Text style={styles.verifyButtonText}>Verify</Text>
            </TouchableOpacity>
          </View>
        </View>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  backdrop: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.7)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
  },
  card: {
    backgroundColor: KidColors.cardDark,
    borderRadius: 24,
    padding: 24,
    width: '100%',
    maxWidth: 360,
    alignItems: 'center',
    borderWidth: 1.2,
    borderColor: KidColors.borderDark,
    shadowColor: '#000',
    shadowOpacity: 0.5,
    shadowRadius: 16,
    elevation: 8,
  },
  shieldIcon: {
    fontSize: 44,
    marginBottom: 8,
  },
  title: {
    color: KidColors.textLight,
    fontSize: 20,
    fontWeight: '800',
    marginBottom: 6,
  },
  subtitle: {
    color: KidColors.textMuted,
    fontSize: 13,
    textAlign: 'center',
    marginBottom: 16,
    lineHeight: 18,
  },
  mathContainer: {
    backgroundColor: KidColors.cardElevated,
    paddingHorizontal: 20,
    paddingVertical: 10,
    borderRadius: 16,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: KidColors.borderDark,
  },
  mathEquation: {
    color: KidColors.accent,
    fontSize: 22,
    fontWeight: '800',
  },
  input: {
    width: '100%',
    height: 48,
    backgroundColor: KidColors.bgDark,
    borderRadius: 14,
    borderWidth: 1.2,
    borderColor: KidColors.borderDark,
    paddingHorizontal: 16,
    color: KidColors.textLight,
    fontSize: 16,
    fontWeight: '700',
    textAlign: 'center',
    marginBottom: 12,
  },
  errorText: {
    color: KidColors.primary,
    fontSize: 12,
    fontWeight: '700',
    marginBottom: 12,
  },
  buttonRow: {
    flexDirection: 'row',
    width: '100%',
    gap: 12,
    marginTop: 6,
  },
  button: {
    flex: 1,
    height: 46,
    borderRadius: 14,
    justifyContent: 'center',
    alignItems: 'center',
  },
  cancelButton: {
    backgroundColor: KidColors.cardElevated,
    borderWidth: 1,
    borderColor: KidColors.borderDark,
  },
  cancelButtonText: {
    color: KidColors.textMuted,
    fontWeight: '700',
    fontSize: 14,
  },
  verifyButton: {
    backgroundColor: KidColors.primary,
  },
  verifyButtonText: {
    color: '#FFF',
    fontWeight: '800',
    fontSize: 14,
  },
});
