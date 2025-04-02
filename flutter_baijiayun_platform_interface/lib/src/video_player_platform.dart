import 'package:flutter/material.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'platform_video_player_controller.dart';

abstract class VideoPlayerPlatform extends PlatformInterface {
  /// Constructs a PlatformVideoPlayerController.
  VideoPlayerPlatform() : super(token: _token);

  static final Object _token = Object();

  static VideoPlayerPlatform? _instance;

  static VideoPlayerPlatform? get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [VideoPlayerPlatform] when
  /// they register themselves.
  static set instance(VideoPlayerPlatform? instance) {
    if (instance == null) {
      throw AssertionError('Platform interfaces can only be set to a non-null instance');
    }

    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  PlatformVideoPlayerController createVideoPlayerController(PlatformVideoPlayerControllerCreationParams params) {
    throw UnimplementedError('createVideoPlayerController has not been implemented.');
  }
}

@immutable
class PlatformVideoPlayerControllerCreationParams {
  const PlatformVideoPlayerControllerCreationParams();
}
