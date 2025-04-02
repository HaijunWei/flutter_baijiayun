import 'package:flutter_baijiayun_platform_interface/flutter_baijiayun_platform_interface.dart';

import 'baijiayun_api.dart';
import 'video_player_controller.dart';

class VideoPlayerIOSPlatform extends VideoPlayerPlatform {
  static void registerWith() {
    VideoPlayerPlatform.instance = VideoPlayerIOSPlatform();
    BaijiayunApiPlatform.instance = BaijiayunApiIOSPlatform();
  }

  @override
  PlatformVideoPlayerController createVideoPlayerController(PlatformVideoPlayerControllerCreationParams params) {
    return VideoPlayerController(params);
  }
}
