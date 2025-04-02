import 'package:flutter/services.dart';

class VideoEvent {
  VideoEvent({
    required this.eventType,
    this.duration,
    this.position,
    this.buffered,
    this.size,
  });

  final VideoEventType eventType;

  /// 视频总时长
  final Duration? duration;

  /// 当前播放时长
  final Duration? position;

  /// 已缓冲长度
  final Duration? buffered;

  /// 视频分辨率
  final Size? size;
}

enum VideoEventType {
  /// 已加载到视频，可以开始播放了
  ready,

  /// 视频进度改变
  progressUpdate,

  /// 分辨率改变
  resolutionUpdate,

  /// 视频播放已结束
  ended,

  /// 视频加载\缓冲失败
  failedToLoad,

  /// unknown
  unknown,
}
