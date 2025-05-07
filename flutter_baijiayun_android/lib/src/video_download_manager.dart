import 'dart:async';

import 'package:flutter_baijiayun_platform_interface/flutter_baijiayun_platform_interface.dart';

import 'baijiayun.g.dart';

class AndroidVideoDownloadManager extends PlatformVideoDownloadManager {
  late final _manager = VideoDownloadManager(onDownloadStateChagned: (_, player, info) {
    _eventController.sink.add(DownloadModel(
      videoId: info['videoId'] as String,
      title: info['title'] as String,
      progress: info['progress'] as double,
      totalSize: info['totalSize'] as int,
      speed: info['speed'] as int,
      state: _mapState(info['state'] as int),
    ));
  });

  final _eventController = StreamController<DownloadModel>.broadcast();

  @override
  Future<void> startDownload({
    required String videoId,
    required String token,
    required String title,
    bool encrypted = false,
  }) {
    return _manager.startDownload(videoId, token, title, encrypted);
  }

  @override
  Future<void> stopDownload(String videoId) {
    return _manager.stopDownload(videoId);
  }

  @override
  Future<void> pauseDownload(String videoId) {
    return _manager.pauseDownload(videoId);
  }

  @override
  Future<void> resumeDownload(String videoId) {
    return _manager.resumeDownload(videoId);
  }

  @override
  Future<List<DownloadModel>> getDownloadList() {
    return _manager.getDownloadList().then((value) => value
        .map((e) => DownloadModel(
              videoId: e['videoId'] as String,
              title: e['title'] as String,
              progress: e['progress'] as double,
              totalSize: e['totalSize'] as int,
              speed: e['speed'] as int,
              state: _mapState(e['state'] as int),
            ))
        .toList());
  }

  @override
  Stream<DownloadModel> stateChanged() {
    return _eventController.stream;
  }

  DownloadState _mapState(int state) {
    switch (state) {
      case 0:
        return DownloadState.downloading;
      case 1:
        return DownloadState.paused;
      case 2:
        return DownloadState.completed;
      default:
        return DownloadState.invalid;
    }
  }
}
