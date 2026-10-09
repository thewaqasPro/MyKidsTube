import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_tube/widgets/kid_embed_player.dart';

void main() {
  group('Prompt F1 — YouTube End-Screen Escape & Kid Safety Tests', () {
    test('KidEmbedPlayer accepts onEnded, onVideoChanged, and onUnknownVideoDetected callbacks', () {
      bool endedCalled = false;
      String? changedId;
      String? unknownDetectedId;

      final player = KidEmbedPlayer(
        youtubeId: 'curated12345',
        onEnded: () => endedCalled = true,
        onVideoChanged: (id) => changedId = id,
        onUnknownVideoDetected: (id) => unknownDetectedId = id,
      );

      expect(player.youtubeId, equals('curated12345'));
      expect(player.onEnded, isNotNull);
      expect(player.onVideoChanged, isNotNull);
      expect(player.onUnknownVideoDetected, isNotNull);

      player.onEnded!();
      player.onVideoChanged!('escape999');
      player.onUnknownVideoDetected!('escape999');

      expect(endedCalled, isTrue);
      expect(changedId, equals('escape999'));
      expect(unknownDetectedId, equals('escape999'));
    });

    test('kid_embed_player.dart contains onStateChange and expectedId wire in YT.Player', () {
      final content = File('lib/widgets/kid_embed_player.dart').readAsStringSync();

      // 1. Must define expectedId variable matching the curated prop
      expect(content.contains('var expectedId = "\$id";'), isTrue,
          reason: 'Expected curated video ID must be defined in the iframe script');

      // 2. Must wire onStateChange in YT.Player events
      expect(content.contains("'onStateChange': onPlayerStateChange"), isTrue,
          reason: 'onStateChange must be registered in YT.Player configuration');

      // 3. Must check for escape and stop playback on unknown ID
      expect(content.contains('checkVideoEscape(event.target)'), isTrue,
          reason: 'onStateChange must check for video ID changes');
      expect(content.contains('p.stopVideo()'), isTrue,
          reason: 'Must immediately stop video when an uncurated ID is detected');

      // 4. Must post videoChanged JSON event
      expect(content.contains("event: 'videoChanged'"), isTrue,
          reason: 'Must post videoChanged event when uncurated video is detected');

      // 5. Must post ended JSON event on state 0
      expect(content.contains("event.data === 0"), isTrue,
          reason: 'Must detect state 0 (ENDED)');
      expect(content.contains("event: 'ended'"), isTrue,
          reason: 'Must post ended event to KidsTubeBridge');
    });

    test('kid_embed_player.dart preserves critical constraints: controls=0, time bridge, no wildcard origin', () {
      final content = File('lib/widgets/kid_embed_player.dart').readAsStringSync();

      // controls=0
      expect(content.contains('controls=0'), isTrue,
          reason: 'Embed iframe URL must specify controls=0');

      // origin scoping
      expect(content.contains("https://www.youtube-nocookie.com"), isTrue,
          reason: 'Must scope to youtube-nocookie');
      expect(content.contains("postMessage('{\"event\":\"command\",\"func\":\"playVideo\",\"args\":\"\"}', '*')"), isFalse,
          reason: 'Wildcard * origin postMessage must not be used');

      // Time bridge preservation
      expect(content.contains('window.KidsTubeBridge.postMessage(t.toString())'), isTrue,
          reason: 'Time reporting must continue posting elapsed seconds');
      expect(content.contains('double.tryParse(raw)'), isTrue,
          reason: 'Dart side must parse raw numeric timestamps');

      // NavigationDelegate blocking
      expect(content.contains('onNavigationRequest: (NavigationRequest request)'), isTrue,
          reason: 'Navigation delegate must guard against web navigation');
      expect(content.contains('NavigationDecision.prevent'), isTrue,
          reason: 'Navigation delegate must prevent external navigation');
    });

    test('kid_player_screen.dart wires onVideoChanged/onUnknownVideoDetected and onEnded', () {
      final content = File('lib/screens/kid_player_screen.dart').readAsStringSync();

      // Wires onEnded
      expect(content.contains('onEnded: _handleEmbedEnded'), isTrue,
          reason: 'kid_player_screen must wire onEnded callback');

      // Wires onVideoChanged and onUnknownVideoDetected
      expect(content.contains('onVideoChanged: _handleEmbedVideoChanged'), isTrue,
          reason: 'kid_player_screen must wire onVideoChanged callback');
      expect(content.contains('onUnknownVideoDetected: _handleEmbedVideoChanged'), isTrue,
          reason: 'kid_player_screen must wire onUnknownVideoDetected callback');

      // Handles uncurated video by stopping and showing error card
      expect(content.contains('_handleEmbedVideoChanged(String unknownId)'), isTrue,
          reason: 'kid_player_screen must define _handleEmbedVideoChanged');
      expect(content.contains('_errorMessage = \'Uncurated video blocked for child safety.\''), isTrue,
          reason: 'Must set error message when unknown video detected');

      // Auto-advances embed shorts
      expect(content.contains('_advanceToNextShort()'), isTrue,
          reason: 'kid_player_screen must support advancing to next short');
      expect(content.contains('if (_currentVideo.isShort)'), isTrue,
          reason: '_handleEmbedEnded must check if current video is a short and advance');
    });

    test('kid_shorts_feed_screen.dart wires onEnded and onUnknownVideoDetected to advance shorts', () {
      final content = File('lib/screens/kid_shorts_feed_screen.dart').readAsStringSync();

      expect(content.contains('onEnded: () => _onVideoFinished(index)'), isTrue,
          reason: 'kid_shorts_feed_screen must wire onEnded to _onVideoFinished');
      expect(content.contains('onVideoChanged: (newId)'), isTrue,
          reason: 'kid_shorts_feed_screen must intercept videoChanged');
    });

    test('KidsTubeBridge JSON protocol payload validation', () {
      // Simulate the bridge JSON messages
      const endedJson = '{"event":"ended","videoId":"test1234"}';
      const changedJson = '{"event":"videoChanged","videoId":"escaped5678"}';
      const timeMessage = '42.5';

      // Verify JSON parses properly
      final endedMap = jsonDecode(endedJson) as Map<String, dynamic>;
      expect(endedMap['event'], equals('ended'));
      expect(endedMap['videoId'], equals('test1234'));

      final changedMap = jsonDecode(changedJson) as Map<String, dynamic>;
      expect(changedMap['event'], equals('videoChanged'));
      expect(changedMap['videoId'], equals('escaped5678'));

      // Verify numeric time parse works
      expect(double.tryParse(timeMessage), equals(42.5));
      expect(double.tryParse(endedJson), isNull);
    });
  });
}
