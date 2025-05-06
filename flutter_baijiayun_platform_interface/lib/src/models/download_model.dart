enum DownloadState {
  invalid,
  downloading,
  paused,
  completed,
}

class DownloadModel {
  final String videoId;
  final String title;
  final double progress;
  final int totalSize;

  /// 下载速度，单位：字节/秒
  final int speed;
  final DownloadState state;

  DownloadModel({
    required this.videoId,
    required this.title,
    required this.progress,
    required this.totalSize,
    required this.speed,
    required this.state,
  });

  DownloadModel copyWith({
    String? videoId,
    String? title,
    double? progress,
    int? totalSize,
    int? speed,
    DownloadState? state,
  }) {
    return DownloadModel(
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      progress: progress ?? this.progress,
      totalSize: totalSize ?? this.totalSize,
      speed: speed ?? this.speed,
      state: state ?? this.state,
    );
  }

  @override
  String toString() {
    return 'DownloadModel(videoId: $videoId, title: $title, progress: $progress, totalSize: $totalSize, speed: $speed, state: $state)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DownloadModel &&
        other.videoId == videoId &&
        other.title == title &&
        other.progress == progress &&
        other.totalSize == totalSize &&
        other.speed == speed &&
        other.state == state;
  }

  @override
  int get hashCode {
    return videoId.hashCode ^ title.hashCode ^ progress.hashCode ^ totalSize.hashCode ^ speed.hashCode ^ state.hashCode;
  }
}
