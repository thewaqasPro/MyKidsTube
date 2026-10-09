import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Prompt F2 — Generation Guard in _initControllerForVideo Tests', () {
    late String screenContent;

    setUpAll(() {
      screenContent = File('lib/screens/kid_player_screen.dart').readAsStringSync();
    });

    test('kid_player_screen.dart defines _controllerGeneration and _inFlightController', () {
      expect(screenContent.contains('int _controllerGeneration = 0;'), isTrue,
          reason: 'State must declare _controllerGeneration counter');
      expect(screenContent.contains('VideoPlayerController? _inFlightController;'), isTrue,
          reason: 'State must declare _inFlightController to track in-flight initializations');
    });

    test('_initControllerForVideo captures generation token per call', () {
      expect(screenContent.contains('final gen = ++_controllerGeneration;'), isTrue,
          reason: 'Must increment and capture token per initialization invocation');
    });

    test('_initControllerForVideo disposes in-flight and previous controllers on entry', () {
      final initIdx = screenContent.indexOf('Future<void> _initControllerForVideo');
      final awaitIdx = screenContent.indexOf('await ctrl.initialize()', initIdx);
      final entryBlock = screenContent.substring(initIdx, awaitIdx);

      expect(entryBlock.contains('_inFlightController?.dispose();'), isTrue,
          reason: 'Must proactively dispose any pending in-flight controller');
      expect(entryBlock.contains('_controller?.dispose();'), isTrue,
          reason: 'Must dispose any existing active controller');
      expect(entryBlock.contains('_controller?.removeListener(_playerListener);'), isTrue,
          reason: 'Must remove listener before disposal');
    });

    test('_initControllerForVideo bails out after await ctrl.initialize() if stale', () {
      final initIdx = screenContent.indexOf('Future<void> _initControllerForVideo');
      final endInitIdx = screenContent.indexOf('DateTime? _lastPlayerTickTime;', initIdx);
      final initBlock = screenContent.substring(initIdx, endInitIdx);

      final awaitIdx = initBlock.indexOf('await ctrl.initialize()');
      final afterAwait = initBlock.substring(awaitIdx);

      // Verify staleness check
      expect(afterAwait.contains('if (!mounted || _controllerGeneration != gen)'), isTrue,
          reason: 'Must check if mounted or stale after await ctrl.initialize()');

      // Verify disposal of local controller on staleness
      expect(afterAwait.contains('ctrl.dispose();'), isTrue,
          reason: 'Must dispose local controller when stale');
      expect(afterAwait.contains('return;'), isTrue,
          reason: 'Must bail out early without touching state');
    });

    test('_initControllerForVideo never calls addListener, play, or setState on stale controller', () {
      final initIdx = screenContent.indexOf('Future<void> _initControllerForVideo');
      final endInitIdx = screenContent.indexOf('DateTime? _lastPlayerTickTime;', initIdx);
      final initBlock = screenContent.substring(initIdx, endInitIdx);

      final awaitIdx = initBlock.indexOf('await ctrl.initialize()');
      final afterAwait = initBlock.substring(awaitIdx);

      final listenerIdx = afterAwait.indexOf('ctrl.addListener(_playerListener)');
      final playIdx = afterAwait.indexOf('ctrl.play()');
      final bailOutIdx = afterAwait.indexOf('if (!mounted || _controllerGeneration != gen)');

      expect(bailOutIdx != -1, isTrue, reason: 'Bailout check must exist');
      expect(listenerIdx != -1, isTrue, reason: 'addListener must exist');
      expect(playIdx != -1, isTrue, reason: 'play() must exist');
      expect(bailOutIdx < listenerIdx, isTrue,
          reason: 'Bail out check must occur before addListener');
      expect(bailOutIdx < playIdx, isTrue,
          reason: 'Bail out check must occur before play()');
      expect(afterAwait.contains('if (mounted && _controllerGeneration == gen)'), isTrue,
          reason: 'setState for isInitialized must be strictly guarded by generation token');
    });

    test('_initControllerForVideo catch block bails out if stale and never flips _useEmbed or error card', () {
      final catchIdx = screenContent.indexOf('} catch (e) {');
      final endCatchIdx = screenContent.indexOf('DateTime? _lastPlayerTickTime;', catchIdx);
      final catchBlock = screenContent.substring(catchIdx, endCatchIdx);

      expect(catchBlock.contains('ctrl?.dispose();'), isTrue,
          reason: 'Must dispose local controller in catch block');
      expect(catchBlock.contains('if (!mounted || _controllerGeneration != gen)'), isTrue,
          reason: 'Must check if stale in catch block before handling fallback');

      final bailIdx = catchBlock.indexOf('if (!mounted || _controllerGeneration != gen)');
      final flipEmbedIdx = catchBlock.indexOf('_useEmbed = true');
      final errorCardIdx = catchBlock.indexOf('_hasError = true');

      expect(bailIdx < flipEmbedIdx, isTrue,
          reason: 'Bail out must occur before flipping _useEmbed in fallback');
      expect(bailIdx < errorCardIdx, isTrue,
          reason: 'Bail out must occur before setting _hasError');
    });

    test('dispose() increments _controllerGeneration and disposes in-flight & active controllers', () {
      final disposeIdx = screenContent.indexOf('void dispose() {');
      final endDisposeIdx = screenContent.indexOf('super.dispose();', disposeIdx);
      final disposeBlock = screenContent.substring(disposeIdx, endDisposeIdx);

      expect(disposeBlock.contains('_controllerGeneration++;'), isTrue,
          reason: 'dispose() must invalidate in-flight initializations');
      expect(disposeBlock.contains('_inFlightController?.dispose();'), isTrue,
          reason: 'dispose() must dispose in-flight controller');
      expect(disposeBlock.contains('_controller?.dispose();'), isTrue,
          reason: 'dispose() must dispose active controller');
      expect(disposeBlock.contains('WakelockPlus.disable();'), isTrue,
          reason: 'Wakelock must be cleanly disabled');
    });

    test('Disposal order preserves timers, wakelock, session flush, and controller listeners', () {
      final disposeIdx = screenContent.indexOf('void dispose() {');
      final endDisposeIdx = screenContent.indexOf('super.dispose();', disposeIdx);
      final disposeBlock = screenContent.substring(disposeIdx, endDisposeIdx);

      final genIdx = disposeBlock.indexOf('_controllerGeneration++');
      final wakeIdx = disposeBlock.indexOf('WakelockPlus.disable()');
      final flushIdx = disposeBlock.indexOf('_flushWatchSession()');
      final removeListenerIdx = disposeBlock.indexOf('_controller?.removeListener(_playerListener)');
      final disposeCtrlIdx = disposeBlock.indexOf('_controller?.dispose()');

      expect(genIdx < wakeIdx, isTrue, reason: 'Generation must be incremented first');
      expect(wakeIdx < flushIdx, isTrue, reason: 'Wakelock disabled in orderly sequence');
      expect(flushIdx < removeListenerIdx, isTrue, reason: 'Session flushed before listener removal');
      expect(removeListenerIdx < disposeCtrlIdx, isTrue, reason: 'Listener removed before controller disposal');
    });
  });
}
