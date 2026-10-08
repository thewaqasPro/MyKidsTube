import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';

import 'parent_dashboard_screen.dart';

class ParentSecurityScreen extends StatefulWidget {
  final bool isForceChange;
  final Widget? destinationOnSuccess;

  const ParentSecurityScreen({
    super.key,
    this.isForceChange = false,
    this.destinationOnSuccess,
  });

  @override
  State<ParentSecurityScreen> createState() => _ParentSecurityScreenState();
}

class _ParentSecurityScreenState extends State<ParentSecurityScreen> {
  final TextEditingController _currentPinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;
  bool _isUsingDefaultPin = false;

  @override
  void initState() {
    super.initState();
    if (widget.isForceChange) {
      _currentPinController.text = '1234';
    }
    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.isUsingDefaultPin().then((isDefault) {
      if (mounted) setState(() => _isUsingDefaultPin = isDefault);
    });
  }

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _changePin() async {
    final current = _currentPinController.text.trim();
    final newPin = _newPinController.text.trim();
    final confirm = _confirmPinController.text.trim();

    if (current.isEmpty || newPin.isEmpty || confirm.isEmpty) {
      _showMessage('Please fill in all PIN fields.', isError: true);
      return;
    }

    if (newPin.length < 4 || !RegExp(r'^\d+$').hasMatch(newPin)) {
      _showMessage('New PIN must be at least 4 numeric digits.', isError: true);
      return;
    }

    if (newPin != confirm) {
      _showMessage('New PIN and confirmation do not match.', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    final provider = Provider.of<AppProvider>(context, listen: false);
    final success = await provider.changeParentPin(currentPin: current, newPin: newPin);
    setState(() => _isSaving = false);

    if (!mounted) return;

    if (success) {
      _currentPinController.clear();
      _newPinController.clear();
      _confirmPinController.clear();
      setState(() => _isUsingDefaultPin = false);
      _showMessage('Parent PIN successfully updated!');
      if (widget.isForceChange) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        if (widget.destinationOnSuccess != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => widget.destinationOnSuccess!),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ParentDashboardScreen()),
          );
        }
      }
    } else {
      _showMessage('Incorrect current PIN. Please try again.', isError: true);
    }
  }

  void _showMessage(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? KidColors.red : KidColors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KidColors.bgDark,
      appBar: AppBar(
        title: const Text(
          'PIN & Security Settings',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: KidColors.bgDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mandatory Setup Warning Banner
            if (widget.isForceChange) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: KidColors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: KidColors.red.withValues(alpha: 0.5)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_reset_rounded, color: KidColors.red, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mandatory PIN Setup',
                            style: TextStyle(
                              color: KidColors.red,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'The default PIN (1234) must be replaced before accessing parental controls.',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Status Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isUsingDefaultPin
                    ? KidColors.yellow.withValues(alpha: 0.12)
                    : KidColors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isUsingDefaultPin
                      ? KidColors.yellow.withValues(alpha: 0.4)
                      : KidColors.green.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isUsingDefaultPin ? Icons.warning_amber_rounded : Icons.verified_user_rounded,
                    color: _isUsingDefaultPin ? KidColors.yellow : KidColors.green,
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isUsingDefaultPin ? 'Default PIN Active' : 'Parent Gate Secured',
                          style: TextStyle(
                            color: _isUsingDefaultPin ? KidColors.yellow : KidColors.green,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isUsingDefaultPin
                              ? 'Your app is protected only by the factory default PIN (1234). We strongly recommend setting a personal PIN.'
                              : 'Your parent controls are securely protected with salted cryptographic storage.',
                          style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Form Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: KidColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KidColors.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.password_rounded, color: KidColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Change Parent PIN',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Set a 4+ digit numeric code. This PIN will be required to access settings, delete videos, or change servers.',
                    style: TextStyle(color: KidColors.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // Current PIN
                  TextField(
                    controller: _currentPinController,
                    obscureText: _obscureCurrent,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      labelText: 'Current PIN',
                      labelStyle: const TextStyle(color: KidColors.textMuted),
                      hintText: _isUsingDefaultPin ? 'Default is 1234' : '••••',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: KidColors.bgDark,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCurrent ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: KidColors.textMuted,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: KidColors.borderDark),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: KidColors.borderDark),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: KidColors.primary),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // New PIN
                  TextField(
                    controller: _newPinController,
                    obscureText: _obscureNew,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      labelText: 'New PIN (4+ Digits)',
                      labelStyle: const TextStyle(color: KidColors.textMuted),
                      hintText: '••••',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: KidColors.bgDark,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNew ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: KidColors.textMuted,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscureNew = !_obscureNew),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: KidColors.borderDark),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: KidColors.borderDark),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: KidColors.primary),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Confirm PIN
                  TextField(
                    controller: _confirmPinController,
                    obscureText: _obscureConfirm,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      labelText: 'Confirm New PIN',
                      labelStyle: const TextStyle(color: KidColors.textMuted),
                      hintText: '••••',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: KidColors.bgDark,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: KidColors.textMuted,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: KidColors.borderDark),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: KidColors.borderDark),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: KidColors.primary),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Submit button in single full-width button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KidColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _isSaving ? null : _changePin,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_outline_rounded, size: 20),
                      label: Text(
                        _isSaving ? 'Updating Security...' : 'Save New PIN',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Security Explainer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KidColors.cardDark.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: KidColors.borderDark),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_outlined, color: KidColors.accent, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'How It Protects Your Child',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• PIN is salted with 16 random cryptographic bytes and hashed with SHA-256.\n'
                    '• Plaintext PINs are never stored on disk or sent across the network.\n'
                    '• The Parent Gate challenge prevents accidental app exits or unapproved video browsing.',
                    style: TextStyle(color: KidColors.textMuted, fontSize: 12, height: 1.45),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
