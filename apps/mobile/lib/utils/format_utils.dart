/// Centralized formatting utilities for MyKidsTube (SafeTube)
class FormatUtils {
  /// Formats byte sizes into human-readable strings (KB, MB, GB)
  static String formatBytes(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// Formats watch duration in seconds into human-readable compact hours/minutes
  /// e.g. 7200 -> '2h 0m', 150 -> '2m', 0 -> '0m'
  static String formatWatchTime(int seconds) {
    if (seconds <= 0) return '0m';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  /// Formats analytics duration including seconds for short intervals
  /// e.g. 3665 -> '1h 1m', 150 -> '2m', 45 -> '45s', 0 -> '0m'
  static String formatAnalyticsDuration(int seconds) {
    if (seconds <= 0) return '0m';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSecs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return remainingSecs > 0 ? '${minutes}m ${remainingSecs}s' : '${minutes}m';
    } else {
      return '${remainingSecs}s';
    }
  }

  /// Formats seconds into digital clock display (e.g. 65 -> '01:05', 3665 -> '01:01:05')
  static String formatClock(int seconds) {
    if (seconds <= 0) return '00:00';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;

    final mStr = m.toString().padLeft(2, '0');
    final sStr = s.toString().padLeft(2, '0');

    if (h > 0) {
      final hStr = h.toString().padLeft(2, '0');
      return '$hStr:$mStr:$sStr';
    }
    return '$mStr:$sStr';
  }

  /// Extracts channel prefix from compound title (e.g., "Channel • Video Name")
  static String extractChannelName(String? rawChannel, String title) {
    if (rawChannel != null && rawChannel.isNotEmpty) {
      return rawChannel;
    }
    if (title.contains('•')) {
      return title.split('•').first.trim();
    }
    return 'KidsTube';
  }

  /// Extracts video title without channel prefix (e.g., "Channel • Video Name" -> "Video Name")
  static String cleanVideoTitle(String title) {
    if (title.contains('•')) {
      return title.split('•').last.trim();
    }
    return title;
  }
}
