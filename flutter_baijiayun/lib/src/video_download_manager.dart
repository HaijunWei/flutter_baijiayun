import 'package:flutter_baijiayun_platform_interface/flutter_baijiayun_platform_interface.dart';

class VideoDownloadManager {
  final PlatformVideoDownloadManager platform;

  VideoDownloadManager() : platform = PlatformVideoDownloadManager.instance!;

  Stream<DownloadModel> get stateChanged => platform.stateChanged();

  Future<void> startDownload({
    required String videoId,
    required String token,
    required String title,
    bool encrypted = false,
  }) {
    return platform.startDownload(videoId: videoId, token: token, title: title, encrypted: encrypted);
  }

  Future<void> stopDownload(String videoId) {
    return platform.stopDownload(videoId);
  }

  Future<void> pauseDownload(String videoId) {
    return platform.pauseDownload(videoId);
  }

  Future<void> resumeDownload(String videoId) {
    return platform.resumeDownload(videoId);
  }

  Future<List<DownloadModel>> getDownloadList() {
    return platform.getDownloadList();
  }
}
