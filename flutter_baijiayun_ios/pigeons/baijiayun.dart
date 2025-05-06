import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(dartOut: 'lib/src/baijiayun.g.dart', swiftOut: 'ios/Classes/Baijiayun.g.swift'))
enum VideoPlayerType { avPlayer, ijkPlayer }

@ProxyApi()
abstract class VideoPlayer {
  VideoPlayer(VideoPlayerType type);

  void setOnlineVideo({required String id, required String token});
  void play();
  void pause();
  void stop();
  void seekTo(int position);
  void setPlaybackSpeed(double speed);
  void setBackgroundPlay(bool backgroundPlay);
  void dispose();

  late void Function(VideoPlayer player, Map event)? onEvent;
}

@HostApi()
abstract class BaijiayunApi {
  void initialize();
  void setPrivateDomainPrefix(String prefix);
}

@ProxyApi()
abstract class VideoDownloadManager {
  VideoDownloadManager();

  void startDownload(String videoId, String token, String title, bool encrypted);
  void stopDownload(String videoId);
  void pauseDownload(String videoId);
  void resumeDownload(String videoId);
  List<DownloadItem> getDownloadList();

  late void Function(VideoDownloadManager player, Map info)? onDownloadStateChagned;
}

class DownloadItem {
  final String videoId;
  final String title;
  final int state;
  final int totalSize;
  final double progress;

  DownloadItem({
    required this.videoId,
    required this.title,
    required this.state,
    required this.totalSize,
    required this.progress,
  });
}
