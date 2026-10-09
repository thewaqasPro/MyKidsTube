import 'package:flutter_test/flutter_test.dart';
import 'package:safe_tube/utils/format_utils.dart';

void main() {
  group('FormatUtils Unit Tests', () {
    test('formatBytes formats bytes into KB, MB, and GB', () {
      expect(FormatUtils.formatBytes(512), '0.5 KB');
      expect(FormatUtils.formatBytes(1024 * 500), '500.0 KB');
      expect(FormatUtils.formatBytes(1024 * 1024 * 15), '15.0 MB');
      expect(FormatUtils.formatBytes(1024 * 1024 * 1024 * 2), '2.00 GB');
    });

    test('formatWatchTime formats seconds into compact hours and minutes', () {
      expect(FormatUtils.formatWatchTime(0), '0m');
      expect(FormatUtils.formatWatchTime(-5), '0m');
      expect(FormatUtils.formatWatchTime(45), '0m');
      expect(FormatUtils.formatWatchTime(120), '2m');
      expect(FormatUtils.formatWatchTime(3600), '1h 0m');
      expect(FormatUtils.formatWatchTime(5400), '1h 30m');
    });

    test('formatAnalyticsDuration includes seconds for short watch intervals', () {
      expect(FormatUtils.formatAnalyticsDuration(0), '0m');
      expect(FormatUtils.formatAnalyticsDuration(45), '45s');
      expect(FormatUtils.formatAnalyticsDuration(120), '2m');
      expect(FormatUtils.formatAnalyticsDuration(150), '2m 30s');
      expect(FormatUtils.formatAnalyticsDuration(3660), '1h 1m');
    });

    test('formatClock formats duration into MM:SS and HH:MM:SS', () {
      expect(FormatUtils.formatClock(0), '00:00');
      expect(FormatUtils.formatClock(9), '00:09');
      expect(FormatUtils.formatClock(65), '01:05');
      expect(FormatUtils.formatClock(3665), '01:01:05');
    });

    test('extractChannelName and cleanVideoTitle handle compound and simple titles', () {
      const compoundTitle = 'Super Fun Cartoon • Episode 42: The Adventure';
      expect(FormatUtils.extractChannelName(null, compoundTitle), 'Super Fun Cartoon');
      expect(FormatUtils.cleanVideoTitle(compoundTitle), 'Episode 42: The Adventure');

      const plainTitle = 'Standalone Bedtime Song';
      expect(FormatUtils.extractChannelName(null, plainTitle), 'KidsTube');
      expect(FormatUtils.cleanVideoTitle(plainTitle), 'Standalone Bedtime Song');

      expect(FormatUtils.extractChannelName('Custom Channel', plainTitle), 'Custom Channel');
    });
  });
}
