import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'models/download_model.dart';

abstract class PlatformVideoDownloadManager extends PlatformInterface {
  /// Constructs a PlatformVideoDownloadManager.
  PlatformVideoDownloadManager() : super(token: _token);

  static final Object _token = Object();

  static PlatformVideoDownloadManager? _instance;

  static PlatformVideoDownloadManager? get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [VideoPlayerPlatform] when
  /// they register themselves.
  static set instance(PlatformVideoDownloadManager? instance) {
    if (instance == null) {
      throw AssertionError('Platform interfaces can only be set to a non-null instance');
    }

    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> startDownload({
    required String videoId,
    required String token,
    required String title,
    required bool encrypted,
  }) {
    throw UnimplementedError('startDownload has not been implemented.');
  }

  Future<void> stopDownload(String videoId) {
    throw UnimplementedError('stopDownload has not been implemented.');
  }

  Future<void> pauseDownload(String videoId) {
    throw UnimplementedError('pauseDownload has not been implemented.');
  }

  Future<void> resumeDownload(String videoId) {
    throw UnimplementedError('stopDownload has not been implemented.');
  }

  Future<List<DownloadModel>> getDownloadList() {
    throw UnimplementedError('getDownloadList has not been implemented.');
  }

  Stream<DownloadModel> stateChanged() {
    throw UnimplementedError('downloadStateChanged has not been implemented.');
  }
}
