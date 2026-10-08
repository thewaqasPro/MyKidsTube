import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../widgets/child_avatar.dart';
import '../widgets/kid_profile_switcher_sheet.dart';

class ProfileSelectorDialog extends StatelessWidget {
  const ProfileSelectorDialog({super.key});

  static Future<void> show(BuildContext context) {
    return KidProfileSwitcherSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final profiles = provider.availableProfiles;

        return Dialog(
          backgroundColor: KidColors.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Who is Watching?',
                  style: TextStyle(
                    color: KidColors.textLight,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select your child profile to load their videos:',
                  style: TextStyle(color: KidColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 24),
                if (profiles.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('No profiles found on server.', style: TextStyle(color: KidColors.textMuted)),
                  )
                else
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: profiles.map((p) {
                      final isSelected = provider.activeProfile?.id == p.id;

                      return GestureDetector(
                        onTap: () {
                          provider.switchProfile(p);
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 100,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? KidColors.primary.withValues(alpha: 0.2) : KidColors.bgDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? KidColors.primary : KidColors.borderDark,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ChildAvatar(avatarIcon: p.avatarIcon, radius: 24),
                              const SizedBox(height: 8),
                              Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSelected ? KidColors.primary : Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: KidColors.textMuted)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
