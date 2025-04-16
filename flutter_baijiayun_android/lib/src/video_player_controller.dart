import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_baijiayun_platform_interface/flutter_baijiayun_platform_interface.dart';

import 'baijiayun.g.dart';

@immutable
class VideoPlayerControllerCreationParams extends PlatformVideoPlayerControllerCreationParams {
  VideoPlayerControllerCreationParams({
    @visibleForTesting PigeonInstanceManager? instanceManager,
  }) : _instanceManager = instanceManager ?? PigeonInstanceManager.instance;

  final PigeonInstanceManager _instanceManager;
}

class VideoPlayerController extends PlatformVideoPlayerController {
  VideoPlayerController(PlatformVideoPlayerControllerCreationParams params)
      : super.implementation(
          params is VideoPlayerControllerCreationParams ? params : VideoPlayerControllerCreationParams(),
        );

  late final VideoPlayer _player = VideoPlayer(
    onEvent: (_, player, event) {
      _eventController.add(_mapEvent(event));
    },
  );

  late final _playerId = (params as VideoPlayerControllerCreationParams)._instanceManager.getIdentifier(_player);

  final _eventController = StreamController<VideoEvent>.broadcast();

  @override
  Widget build(BuildContext context) {
    return PlatformViewLink(
      viewType: 'com.haijunwei.flutter/baijiayun_video_player',
      surfaceFactory: (context, controller) {
        return AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
      onCreatePlatformView: (params) {
        return PlatformViewsService.initSurfaceAndroidView(
          id: params.id,
          viewType: 'com.haijunwei.flutter/baijiayun_video_player',
          layoutDirection: TextDirection.ltr,
          creationParams: _playerId,
          creationParamsCodec: const StandardMessageCodec(),
          onFocus: () {
            params.onFocusChanged(true);
          },
        )
          ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
          ..create();
      },
    );
  }

  @override
  Future<void> setOnlineVideo({required String id, required String token}) {
    return _player.setOnlineVideo(id, token);
  }

  @override
  Future<void> play() {
    return _player.play();
  }

  @override
  Future<void> pause() {
    return _player.pause();
  }

  @override
  Future<void> stop() {
    return _player.stop();
  }

  @override
  Future<void> seekTo(int position) {
    return _player.seekTo(position);
  }

  @override
  Future<void> setPlaybackSpeed(double speed) {
    return _player.setPlaybackSpeed(speed);
  }

  @override
  Future<void> setBackgroundPlay(bool backgroundPlay) {
    return _player.setBackgroundPlay(backgroundPlay);
  }

  @override
  Future<void> dispose() {
    return _player.dispose();
  }

  @override
  Stream<VideoEvent> videoEvents() {
    return _eventController.stream;
  }

  VideoEvent _mapEvent(Map map) {
    switch (map['event']) {
      case 'ready':
        return VideoEvent(eventType: VideoEventType.ready);
      case 'resolutionUpdate':
        return VideoEvent(
          eventType: VideoEventType.resolutionUpdate,
          size: Size(
            map['width']?.toDouble() ?? 0.0,
            map['height']?.toDouble() ?? 0.0,
          ),
        );
      case 'progressUpdate':
        final position = map['position'] ?? 0;
        if (position < 0) {
          return VideoEvent(eventType: VideoEventType.unknown);
        }
        return VideoEvent(
          eventType: VideoEventType.progressUpdate,
          duration: Duration(milliseconds: map['duration'] ?? 0),
          position: Duration(milliseconds: position),
          buffered: Duration(milliseconds: map['buffered'] ?? 0),
        );
      case 'ended':
        return VideoEvent(eventType: VideoEventType.ended);
      case 'failedToLoad':
        return VideoEvent(eventType: VideoEventType.failedToLoad);
      default:
        return VideoEvent(eventType: VideoEventType.unknown);
    }
  }
}
