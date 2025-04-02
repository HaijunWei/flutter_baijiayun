import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_baijiayun_ios/src/baijiayun.g.dart';
import 'package:flutter_baijiayun_platform_interface/flutter_baijiayun_platform_interface.dart';

@immutable
class VideoPlayerControllerCreationParams extends PlatformVideoPlayerControllerCreationParams {
  VideoPlayerControllerCreationParams({
    this.type = VideoPlayerType.avPlayer,
    @visibleForTesting PigeonInstanceManager? instanceManager,
  }) : _instanceManager = instanceManager ?? PigeonInstanceManager.instance;

  final VideoPlayerType type;

  final PigeonInstanceManager _instanceManager;
}

class VideoPlayerController extends PlatformVideoPlayerController {
  VideoPlayerController(PlatformVideoPlayerControllerCreationParams params)
      : super.implementation(
          params is VideoPlayerControllerCreationParams ? params : VideoPlayerControllerCreationParams(),
        );

  late final VideoPlayer _player = VideoPlayer(type: (params as VideoPlayerControllerCreationParams).type);

  late final _playerId = (params as VideoPlayerControllerCreationParams)._instanceManager.getIdentifier(_player);

  @override
  Widget build(BuildContext context) {
    return UiKitView(
      viewType: 'com.haijunwei.flutter/baijiayun_video_player',
      onPlatformViewCreated: (_) {},
      creationParams: _playerId,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }

  @override
  Future<void> initialize() {
    return _player.initialize();
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
  Stream<VideoEvent> videoEvents() {
    return _eventChannelFor(_playerId ?? 0).receiveBroadcastStream().map((event) {
      final Map<dynamic, dynamic> map = event;
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
    });
  }

  EventChannel _eventChannelFor(int playerId) {
    return EventChannel('com.haijunwei.flutter/baijiayun_video_player/videoEvents$playerId');
  }
}
