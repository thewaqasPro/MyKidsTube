import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Prompt F3 & F4 — Fullscreen Orientation Flow & Dead Zoom Removal Tests', () {
    late String playerContent;
    late String shortsContent;
    late String embedContent;

    setUpAll(() {
      playerContent = File('lib/screens/kid_player_screen.dart').readAsStringSync();
      shortsContent = File('lib/screens/kid_shorts_feed_screen.dart').readAsStringSync();
      embedContent = File('lib/widgets/kid_embed_player.dart').readAsStringSync();
    });

    test('Prompt F3: _buildPortraitControls saves orientation and wasLandscape before entering landscape', () {
      final portraitControlsIdx = playerContent.indexOf('Widget _buildPortraitControls');
      final endControlsIdx = playerContent.indexOf('Widget _buildPortraitDetailsAndPlaylist', portraitControlsIdx);
      final portraitBlock = playerContent.substring(portraitControlsIdx, endControlsIdx);

      expect(portraitBlock.contains('_orientationModeBeforeFullscreen = provider.orientationMode;'), isTrue,
          reason: '_buildPortraitControls must save orientation mode before forcing landscape');
      expect(portraitBlock.contains('_wasLandscapeBeforeFullscreen = false;'), isTrue,
          reason: '_buildPortraitControls must record that it originated from portrait mode');
      expect(portraitBlock.contains('_toggleOrientation(toLandscape: true);'), isTrue,
          reason: 'Must toggle orientation to landscape');
      expect(portraitBlock.contains('setState(() => _isImmersiveLandscape = true);'), isTrue,
          reason: 'Must set immersive landscape state');
    });

    test('Prompt F3: _exitFullscreen restores _orientationModeBeforeFullscreen from either entry path', () {
      final exitIdx = playerContent.indexOf('void _exitFullscreen()');
      final endExitIdx = playerContent.indexOf('String _formatDuration', exitIdx);
      final exitBlock = playerContent.substring(exitIdx, endExitIdx);

      expect(exitBlock.contains('if (_orientationModeBeforeFullscreen != null)'), isTrue,
          reason: '_exitFullscreen must check saved orientation mode before fullscreen');
      expect(exitBlock.contains('provider.setOrientationMode(_orientationModeBeforeFullscreen!);'), isTrue,
          reason: '_exitFullscreen must restore the saved mode so auto mode survives round-trip');
      expect(exitBlock.contains('_orientationModeBeforeFullscreen = null;'), isTrue,
          reason: '_orientationModeBeforeFullscreen must be cleared after restore');
    });

    test('Prompt F3: Shorts feed dispose re-applies user saved preference instead of hardcoded set', () {
      final disposeIdx = shortsContent.indexOf('void dispose() {');
      final endDisposeIdx = shortsContent.indexOf('void _initControllersForWindow', disposeIdx);
      final disposeBlock = shortsContent.substring(disposeIdx, endDisposeIdx);

      // Verify didChangeDependencies caches user preference
      expect(shortsContent.contains('AppOrientationMode _savedOrientationMode = AppOrientationMode.auto;'), isTrue,
          reason: 'Shorts feed must declare _savedOrientationMode state field');
      expect(shortsContent.contains('_savedOrientationMode = provider.orientationMode;'), isTrue,
          reason: 'didChangeDependencies must cache active orientationMode');

      // Verify dispose applies saved preference dynamically
      expect(disposeBlock.contains('switch (_savedOrientationMode)'), isTrue,
          reason: 'Shorts dispose must branch dynamically on saved preference');
      expect(disposeBlock.contains('provider.applyCurrentOrientationMode();'), isTrue,
          reason: 'Shorts dispose must re-apply provider preference');
    });

    test('Prompt F4: No zoom reference remains in apps/mobile', () {
      expect(embedContent.contains('zoom'), isFalse,
          reason: 'kid_embed_player.dart must have zero zoom references');
      expect(playerContent.contains('zoom'), isFalse,
          reason: 'kid_player_screen.dart must have zero zoom references');
      expect(shortsContent.contains('zoom'), isFalse,
          reason: 'kid_shorts_feed_screen.dart must have zero zoom references');
    });

    test('Prompt F4: Preserves 1.14 scale crop, controls=0, and shield coverage', () {
      expect(embedContent.contains('scale'), isTrue,
          reason: 'KidEmbedPlayer must retain scale parameter');
      expect(playerContent.contains('scale: 1.14'), isTrue,
          reason: 'kid_player_screen.dart must pass scale: 1.14');
      expect(shortsContent.contains('scale: 1.14'), isTrue,
          reason: 'kid_shorts_feed_screen.dart must pass scale: 1.14');
      expect(embedContent.contains('controls=0'), isTrue,
          reason: 'Embed iframe URL must retain controls=0');
      expect(embedContent.contains('SHIELD 1: Dynamic Top'), isTrue,
          reason: 'Top frosted shield must remain active');
      expect(embedContent.contains('SHIELD 2: Dynamic Bottom'), isTrue,
          reason: 'Bottom frosted shield must remain active');
    });
  });
}
