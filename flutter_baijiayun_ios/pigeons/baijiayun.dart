import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(dartOut: 'lib/src/baijiayun.g.dart', swiftOut: 'ios/Classes/Baijiayun.g.swift'))
enum VideoPlayerType { avPlayer, ijkPlayer }

@ProxyApi()
abstract class VideoPlayer {
  VideoPlayer(VideoPlayerType type);

  void initialize();
  void setOnlineVideo({required String id, required String token});
  void play();
  void pause();
  void stop();
  void seekTo(int position);
  void setPlaybackSpeed(double speed);
  void setBackgroundPlay(bool backgroundPlay);
}

@HostApi()
abstract class BaijiayunApi {
  void setPrivateDomainPrefix(String prefix);
}
