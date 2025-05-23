import 'package:flutter_baijiayun_platform_interface/flutter_baijiayun_platform_interface.dart';

import 'baijiayun_api.dart';
import 'video_download_manager.dart';
import 'video_player_controller.dart';

class VideoPlayerAndroidPlatform extends VideoPlayerPlatform {
  static void registerWith() {
    VideoPlayerPlatform.instance = VideoPlayerAndroidPlatform();
    BaijiayunApiPlatform.instance = BaijiayunApiAndroidPlatform();
    PlatformVideoDownloadManager.instance = AndroidVideoDownloadManager();
  }

  @override
  PlatformVideoPlayerController createVideoPlayerController(PlatformVideoPlayerControllerCreationParams params) {
    return VideoPlayerController(params);
  }
}
