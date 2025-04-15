import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_baijiayun_platform_interface/flutter_baijiayun_platform_interface.dart';

class VideoPlayerValue {
  VideoPlayerValue({
    this.isPlaying = false,
    this.isStop = false,
    this.isLoading = false,
    this.isFailedToLoad = false,
    this.isReady = false,
    required this.duration,
    this.position = Duration.zero,
    this.buffered = Duration.zero,
    this.size = Size.zero,
    this.playbackSpeed = 1.0,
    this.errorDescription,
  });

  VideoPlayerValue.erroneous(String errorDescription)
      : this(
          duration: Duration.zero,
          isReady: false,
          errorDescription: errorDescription,
        );

  /// 是否播放中
  final bool isPlaying;

  /// 视频已停止播放
  final bool isStop;

  /// 是否加载中
  final bool isLoading;

  /// 是否加载/缓冲失败，已停止播放
  final bool isFailedToLoad;

  /// 视频是否已经加载成功，可以播放了
  final bool isReady;

  /// 视频时长
  final Duration duration;

  /// 视频已播放时长
  final Duration position;

  /// 视频缓冲长度
  final Duration buffered;

  /// 视频分辨率，直播此值为zero
  final Size size;

  /// 播放速度
  final double playbackSpeed;

  final String? errorDescription;

  bool get hasError => errorDescription != null;

  VideoPlayerValue copyWith({
    bool? isPlaying,
    bool? isStop,
    bool? isLoading,
    bool? isFailedToLoad,
    bool? isReady,
    Duration? duration,
    Duration? position,
    Duration? buffered,
    Size? size,
    double? playbackSpeed,
    String? errorDescription,
  }) {
    return VideoPlayerValue(
      isPlaying: isPlaying ?? this.isPlaying,
      isStop: isStop ?? this.isStop,
      isLoading: isLoading ?? this.isLoading,
      isFailedToLoad: isFailedToLoad ?? this.isFailedToLoad,
      isReady: isReady ?? this.isReady,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      buffered: buffered ?? this.buffered,
      size: size ?? this.size,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      errorDescription: errorDescription ?? this.errorDescription,
    );
  }

  @override
  String toString() {
    return 'VideoPlayerValue(isPlaying: $isPlaying, isStop: $isStop, isLoading: $isLoading, isFailedToLoad: $isFailedToLoad, isReady: $isReady, duration: $duration, position: $position, buffered: $buffered, size: $size, playbackSpeed: $playbackSpeed, errorDescription: $errorDescription)';
  }
}

class VideoPlayerController extends ValueNotifier<VideoPlayerValue> {
  VideoPlayerController() : this.fromPlatformCreationParams(const PlatformVideoPlayerControllerCreationParams());

  VideoPlayerController.fromPlatformCreationParams(
    PlatformVideoPlayerControllerCreationParams params,
  )   : platform = PlatformVideoPlayerController(params),
        super(VideoPlayerValue(duration: Duration.zero)) {
    _lifeCycleObserver = _VideoAppLifeCycleObserver(this);
    _lifeCycleObserver.initialize();
    _eventSubscription = platform.videoEvents().listen(_eventListener, onError: _errorListener);
  }

  final PlatformVideoPlayerController platform;

  bool _isDisposed = false;
  bool _autoPlay = false;
  bool _backgroundPlay = false;
  bool get backgroundPlay => _backgroundPlay;
  Duration? _initializedPosition;

  late _VideoAppLifeCycleObserver _lifeCycleObserver;

  StreamSubscription<dynamic>? _eventSubscription;

  void _eventListener(VideoEvent event) async {
    if (_isDisposed) return;

    switch (event.eventType) {
      case VideoEventType.ready:
        // 卡顿后恢复播放也会调用此消息
        if (value.isReady) {
          value = value.copyWith(isFailedToLoad: false);
          break;
        }
        value = value.copyWith(
          isReady: true,
          isLoading: false,
          isFailedToLoad: false,
        );
        if (_initializedPosition != null) {
          seekTo(_initializedPosition!.inSeconds);
        }
        if (_autoPlay) resume();
        break;
      case VideoEventType.resolutionUpdate:
        if (value.isStop) break;
        value = value.copyWith(
          size: event.size,
        );
        break;
      case VideoEventType.progressUpdate:
        if (value.isStop) break;
        value = value.copyWith(
          duration: event.duration,
          position: event.position,
          buffered: event.buffered,
        );
        break;
      case VideoEventType.ended:
        if (!value.isStop) stop();
        break;
      case VideoEventType.failedToLoad:
        value = value.copyWith(
          isFailedToLoad: true,
        );
        break;
      case VideoEventType.unknown:
        break;
    }
  }

  void _errorListener(Object obj) {
    final PlatformException e = obj as PlatformException;
    value = VideoPlayerValue.erroneous(e.message!);
  }

  Future<void> setOnlineVideo({
    required String id,
    required String token,
    bool autoPlay = false,
    Duration? position,
  }) async {
    _autoPlay = autoPlay;
    _initializedPosition = position;
    value = value.copyWith(
      isReady: false,
      isStop: false,
      isLoading: true,
    );
    return platform.setOnlineVideo(id: id, token: token);
  }

  Future<void> play() {
    return platform.play();
  }

  Future<void> replay() async {
    _initializedPosition = null;
    await platform.play();
    _autoPlay = true;
    value = value.copyWith(
      isReady: false,
      isStop: false,
      isLoading: true,
    );
  }

  Future<void> resume() async {
    await platform.play();
    value = value.copyWith(
      isPlaying: true,
    );
  }

  Future<void> pause() async {
    await platform.pause();
    value = value.copyWith(
      isPlaying: false,
    );
  }

  Future<void> stop() async {
    await platform.stop();
    value = value.copyWith(
      isStop: true,
      isPlaying: false,
      isReady: false,
    );
  }

  Future<void> seekTo(int position) {
    value = value.copyWith(
      position: Duration(seconds: position),
    );
    return platform.seekTo(position);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    await platform.setPlaybackSpeed(speed);
    value = value.copyWith(playbackSpeed: speed);
  }

  Future<void> setBackgroundPlay(bool backgroundPlay) {
    _backgroundPlay = backgroundPlay;
    return platform.setBackgroundPlay(backgroundPlay);
  }

  @override
  Future<void> dispose() async {
    if (!_isDisposed) {
      _isDisposed = true;
      await _eventSubscription?.cancel();
    }
    // _lifeCycleObserver.dispose();
    _isDisposed = true;
    super.dispose();
  }
}

class _VideoAppLifeCycleObserver extends Object with WidgetsBindingObserver {
  _VideoAppLifeCycleObserver(this._controller);

  bool _wasPlayingBeforePause = false;
  final VideoPlayerController _controller;

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller.backgroundPlay) return;
    switch (state) {
      case AppLifecycleState.paused:
        _wasPlayingBeforePause = _controller.value.isPlaying;
        _controller.pause();
        break;
      case AppLifecycleState.resumed:
        if (_wasPlayingBeforePause) {
          _controller.resume();
        }
        break;
      default:
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}
