import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import 'parent_dashboard_screen.dart';
import 'parent_security_screen.dart';

class ParentGateDialog extends StatefulWidget {
  final bool isVerificationOnly;

  const ParentGateDialog({
    super.key,
    this.isVerificationOnly = false,
  });

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const ParentGateDialog(),
    );
  }

  static Future<bool> showChallenge(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const ParentGateDialog(isVerificationOnly: true),
    );
    return result ?? false;
  }

  @override
  State<ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<ParentGateDialog> {
  late int _num1;
  late int _num2;
  late int _expectedAnswer;
  final TextEditingController _answerController = TextEditingController();
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    final random = Random();
    _num1 = random.nextInt(8) + 3; // 3 to 10
    _num2 = random.nextInt(8) + 2; // 2 to 9
    _expectedAnswer = _num1 * _num2;
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final entered = int.tryParse(_answerController.text.trim());
    final provider = Provider.of<AppProvider>(context, listen: false);

    // Also accepts the saved salted PIN via secure verification
    final enteredStr = _answerController.text.trim();
    final isPinValid = await provider.verifyParentPin(enteredStr);
    if (!mounted) return;

    if (entered == _expectedAnswer || isPinValid) {
      final nav = Navigator.of(context);
      if (widget.isVerificationOnly) {
        nav.pop(true);
        return;
      }
      final isDefaultPin = await provider.isUsingDefaultPin();
      if (!mounted) return;
      nav.pop();
      if (isDefaultPin) {
        // Fresh install / default PIN active: block parent dashboard access until PIN is changed
        nav.push(
          MaterialPageRoute(
            builder: (context) => const ParentSecurityScreen(isForceChange: true),
          ),
        );
      } else {
        nav.push(
          MaterialPageRoute(builder: (context) => const ParentDashboardScreen()),
        );
      }
    } else {
      setState(() {
        _errorMessage = 'Incorrect answer. Try again!';
      });
      _answerController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: KidColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: KidColors.borderDark, width: 1.0),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_outlined, color: KidColors.primary, size: 44),
            const SizedBox(height: 12),
            const Text(
              'Grown-Ups Only',
              style: TextStyle(
                fontFamily: 'Roboto',
                color: KidColors.textLight,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please solve this problem or enter PIN to continue:',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Roboto', color: KidColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: KidColors.bgDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: KidColors.borderDark),
              ),
              child: Text(
                '$_num1 × $_num2 = ?',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: KidColors.accent,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _answerController,
              keyboardType: TextInputType.number,
              autofocus: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Roboto', color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                hintText: 'Answer or PIN',
                hintStyle: const TextStyle(color: KidColors.textMuted),
                filled: true,
                fillColor: KidColors.bgDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: KidColors.borderDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: KidColors.primary),
                ),
              ),
              onSubmitted: (_) => _verify(),
            ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage,
                style: const TextStyle(fontFamily: 'Roboto', color: KidColors.red, fontSize: 12),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel', style: TextStyle(fontFamily: 'Roboto', color: KidColors.textMuted)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KidColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _verify,
                    child: const Text(
                      'Enter',
                      style: TextStyle(fontFamily: 'Roboto', color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
