import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_update_info.dart';

/// Modal dialog presenting app update information to parents with options
/// to download APK directly or view GitHub release notes.
class AppUpdateDialog extends StatelessWidget {
  final AppUpdateInfo info;
  final Future<bool> Function(String url)? onLaunchUrlOverride;

  const AppUpdateDialog({
    super.key,
    required this.info,
    this.onLaunchUrlOverride,
  });

  static Future<void> show(
    BuildContext context, {
    required AppUpdateInfo info,
    Future<bool> Function(String url)? onLaunchUrlOverride,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AppUpdateDialog(
        info: info,
        onLaunchUrlOverride: onLaunchUrlOverride,
      ),
    );
  }

  Future<void> _launchUrlString(BuildContext context, String urlString) async {
    if (urlString.isEmpty) return;

    if (onLaunchUrlOverride != null) {
      await onLaunchUrlOverride!(urlString);
      return;
    }

    try {
      final uri = Uri.parse(urlString);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link: $urlString'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening link: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!info.hasUpdate) {
      return _buildUpToDateDialog(context);
    }
    return _buildUpdateAvailableDialog(context);
  }

  Widget _buildUpToDateDialog(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Colors.white12),
      ),
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.greenAccent.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_circle_outline_rounded,
          color: Colors.greenAccent,
          size: 40,
        ),
      ),
      title: const Text(
        "You're Up to Date!",
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
      content: Text(
        'You are running version ${info.currentVersion}, which is the latest version available.',
        style: const TextStyle(color: Colors.white70, fontSize: 13.5),
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white12,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildUpdateAvailableDialog(BuildContext context) {
    final downloadTargetUrl =
        info.apkDownloadUrl.isNotEmpty ? info.apkDownloadUrl : info.downloadPageUrl;

    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Colors.white12),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amberAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.system_update_rounded, color: Colors.amberAccent, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Update Available',
                  style: TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'v${info.currentVersion}  →  v${info.latestVersion}',
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 280),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (info.releaseTitle.isNotEmpty) ...[
                Text(
                  info.releaseTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (info.releaseNotes.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    info.releaseNotes,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        Row(
          children: [
            if (info.downloadPageUrl.isNotEmpty) ...[
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white54,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                onPressed: () => _launchUrlString(context, info.downloadPageUrl),
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: const Text('View on GitHub', style: TextStyle(fontSize: 11.5)),
              ),
            ],
            const Spacer(),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white54,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
            const SizedBox(width: 6),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amberAccent,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onPressed: () {
                _launchUrlString(context, downloadTargetUrl);
              },
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text(
                'Download & Install Update',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
