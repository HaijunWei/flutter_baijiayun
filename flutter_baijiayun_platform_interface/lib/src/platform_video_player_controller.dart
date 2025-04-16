import 'package:flutter/widgets.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'video_event.dart';
import 'video_player_platform.dart';

abstract class PlatformVideoPlayerController extends PlatformInterface {
  factory PlatformVideoPlayerController(PlatformVideoPlayerControllerCreationParams params) {
    assert(VideoPlayerPlatform.instance != null);
    final controller = VideoPlayerPlatform.instance!.createVideoPlayerController(params);
    PlatformInterface.verify(controller, _token);
    return controller;
  }

  @protected
  PlatformVideoPlayerController.implementation(this.params) : super(token: _token);

  static final Object _token = Object();

  final PlatformVideoPlayerControllerCreationParams params;

  Widget build(BuildContext context);

  Future<void> setOnlineVideo({required String id, required String token}) {
    throw UnimplementedError('setOnlineVideo has not been implemented.');
  }

  Future<void> play() {
    throw UnimplementedError('play has not been implemented.');
  }

  Future<void> pause() {
    throw UnimplementedError('pause has not been implemented.');
  }

  Future<void> stop() {
    throw UnimplementedError('stop has not been implemented.');
  }

  Future<void> seekTo(int position) {
    throw UnimplementedError('seekTo has not been implemented.');
  }

  Future<void> setPlaybackSpeed(double speed) {
    throw UnimplementedError('setPlaybackSpeed has not been implemented.');
  }

  Future<void> setBackgroundPlay(bool backgroundPlay) {
    throw UnimplementedError('setBackgroundPlay has not been implemented.');
  }

  Future<void> dispose() {
    throw UnimplementedError('dispose has not been implemented.');
  }

  Stream<VideoEvent> videoEvents() {
    throw UnimplementedError('videoEvents has not been implemented.');
  }
}
