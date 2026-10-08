import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/child_profile.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import 'child_avatar.dart';

class KidProfileSwitcherSheet extends StatelessWidget {
  const KidProfileSwitcherSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const KidProfileSwitcherSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final profiles = provider.availableProfiles;
        final active = provider.activeProfile;

        return Container(
          decoration: const BoxDecoration(
            color: KidColors.cardDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pull handle
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 18),

                // Sheet Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Who's Watching? 🎈",
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Tap your avatar to switch your fun feed',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: KidColors.textMuted,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // Profiles Grid / List
                if (profiles.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No child profiles configured yet.',
                      style: TextStyle(color: KidColors.textMuted),
                    ),
                  )
                else
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: profiles.map((p) {
                      final isSelected = active?.id == p.id;

                      return GestureDetector(
                        onTap: () {
                          provider.switchProfile(p);
                          Navigator.of(context).pop();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 104,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? KidColors.primary.withValues(alpha: 0.22)
                                : KidColors.bgDark,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected ? KidColors.primary : KidColors.borderDark,
                              width: isSelected ? 2.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: KidColors.primary.withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  ChildAvatar(
                                    avatarIcon: p.avatarIcon,
                                    radius: 28,
                                    showBorder: isSelected,
                                  ),
                                  if (isSelected)
                                    Positioned(
                                      right: -2,
                                      bottom: -2,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: KidColors.green,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 13,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  color: isSelected ? Colors.white : KidColors.textMuted,
                                  fontSize: 13.5,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isSelected ? 'Active Now' : p.ageBracket.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  color: isSelected ? KidColors.primary : Colors.white38,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 26),
                const Divider(color: KidColors.borderDark, height: 1),
                const SizedBox(height: 14),

                // Parent Management Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: KidColors.accent,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                      label: const Text(
                        'Add Kid Profile',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      onPressed: () => _promptAddProfile(context, provider),
                    ),
                    Text(
                      'Parent PIN Required for Edit',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _promptAddProfile(BuildContext context, AppProvider provider) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: KidColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Parent Verification',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your 4-digit Parent PIN to add a child profile:',
              style: TextStyle(color: KidColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 4),
              decoration: InputDecoration(
                hintText: '••••',
                hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 4),
                filled: true,
                fillColor: KidColors.bgDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: KidColors.borderDark),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: KidColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KidColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final pin = pinController.text.trim();
              final ok = await provider.verifyParentPin(pin);
              if (!dialogCtx.mounted) return;
              if (ok) {
                Navigator.of(dialogCtx).pop();
                if (context.mounted) {
                  _showCreateProfileDialog(context, provider);
                }
              } else {
                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                  const SnackBar(
                    content: Text('Incorrect Parent PIN. Default is 1234.'),
                    backgroundColor: KidColors.red,
                  ),
                );
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _showCreateProfileDialog(BuildContext context, AppProvider provider) {
    final nameController = TextEditingController();
    String selectedIcon = 'bear';
    String selectedAge = 'all';

    final avatarOptions = ['bear', 'unicorn', 'lion', 'rocket', 'panda', 'star', 'teddy'];

    showDialog(
      context: context,
      builder: (createCtx) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          backgroundColor: KidColors.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text(
            'New Child Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Child Name:', style: TextStyle(color: KidColors.textMuted, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g. Maya, Zayd',
                    hintStyle: const TextStyle(color: Colors.white30),
                    filled: true,
                    fillColor: KidColors.bgDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: KidColors.borderDark),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Choose Avatar:', style: TextStyle(color: KidColors.textMuted, fontSize: 13)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: avatarOptions.map((iconKey) {
                    final isSel = selectedIcon == iconKey;
                    return GestureDetector(
                      onTap: () => setLocalState(() => selectedIcon = iconKey),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSel ? KidColors.primary : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: ChildAvatar(avatarIcon: iconKey, radius: 18),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                const Text('Age Bracket:', style: TextStyle(color: KidColors.textMuted, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildAgeChip('preschool', 'Preschool', selectedAge, (val) => setLocalState(() => selectedAge = val)),
                    const SizedBox(width: 8),
                    _buildAgeChip('elementary', 'Elementary', selectedAge, (val) => setLocalState(() => selectedAge = val)),
                    const SizedBox(width: 8),
                    _buildAgeChip('all', 'All Ages', selectedAge, (val) => setLocalState(() => selectedAge = val)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(createCtx).pop(),
              child: const Text('Cancel', style: TextStyle(color: KidColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: KidColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final newProfile = ChildProfile(
                  id: 'kid_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  avatarIcon: selectedIcon,
                  ageBracket: selectedAge,
                );

                await provider.addLocalProfile(newProfile);
                await provider.switchProfile(newProfile);
                if (createCtx.mounted) {
                  Navigator.of(createCtx).pop();
                }
                if (context.mounted) {
                  Navigator.of(context).pop(); // Dismiss bottom sheet too
                }
              },
              child: const Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeChip(String value, String label, String selected, ValueChanged<String> onSelected) {
    final isSel = value == selected;
    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? KidColors.primary.withValues(alpha: 0.25) : KidColors.bgDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSel ? KidColors.primary : KidColors.borderDark,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSel ? KidColors.primary : Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
