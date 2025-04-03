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

  late void Function(VideoPlayer player, Map event)? onEvent;
}

@HostApi()
abstract class BaijiayunApi {
  void initialize();
  void setPrivateDomainPrefix(String prefix);
}
