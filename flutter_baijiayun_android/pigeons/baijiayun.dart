import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/baijiayun.g.dart',
  kotlinOut: 'android/src/main/kotlin/com/haijunwei/flutter_baijiayun_android/Baijiayun.g.kt',
  kotlinOptions: KotlinOptions(
    package: 'com.haijunwei.flutter_baijiayun_android',
    errorClassName: 'BaijiayunError',
  ),
))
@ProxyApi()
abstract class VideoPlayer {
  VideoPlayer();

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
