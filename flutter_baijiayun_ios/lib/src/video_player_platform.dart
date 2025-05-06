import 'package:flutter_baijiayun_platform_interface/flutter_baijiayun_platform_interface.dart';

import 'baijiayun_api.dart';
import 'video_download_manager.dart';
import 'video_player_controller.dart';

class VideoPlayerIOSPlatform extends VideoPlayerPlatform {
  static void registerWith() {
    VideoPlayerPlatform.instance = VideoPlayerIOSPlatform();
    BaijiayunApiPlatform.instance = BaijiayunApiIOSPlatform();
    PlatformVideoDownloadManager.instance = IOSVideoDownloadManager();
  }

  @override
  PlatformVideoPlayerController createVideoPlayerController(PlatformVideoPlayerControllerCreationParams params) {
    return VideoPlayerController(params);
  }
}
