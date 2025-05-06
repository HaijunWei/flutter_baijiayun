import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_baijiayun/flutter_baijiayun.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BaijiayunApi.initialize();
  BaijiayunApi.setPrivateDomainPrefix('e33180987');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final controller = VideoPlayerController();
  bool _isFullscreen = false;
  final List<DeviceOrientation> preferredDeviceOrientation = [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ];
  final List<DeviceOrientation> preferredDeviceOrientationFullscreen = [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];

  final videoKey = GlobalKey();

  final downloadManager = VideoDownloadManager();

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      // print(controller.value);
    });
    controller.setOnlineVideo(
      id: '300852684',
      token: '2mTL4Jw709nFbckRSbAqZ92nuYlhGz1otveAFJcn0s44aYPNeoK15TG5JtrxIFp-',
      position: const Duration(minutes: 60),
    );

    downloadManager.stateChanged.listen((event) {
      print(event);
    });
  }

  void _setPreferredOrientation() {
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations(preferredDeviceOrientationFullscreen);
    } else {
      SystemChrome.setPreferredOrientations(preferredDeviceOrientation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          Wrap(
            children: [
              CupertinoButton(
                child: Text('播放'),
                onPressed: () {
                  controller.play();
                },
              ),
              CupertinoButton(
                child: Text('暂停'),
                onPressed: () {
                  controller.pause();
                },
              ),
              CupertinoButton(
                child: Text('倍速'),
                onPressed: () {
                  controller.setPlaybackSpeed(2);
                },
              ),
              CupertinoButton(
                child: Text('快退'),
                onPressed: () {
                  controller.seekTo(60);
                },
              ),
              CupertinoButton(
                child: Text('快进'),
                onPressed: () {
                  controller.seekTo(99 * 60);
                },
              ),
              CupertinoButton(
                child: Text('结束'),
                onPressed: () {
                  controller.stop();
                },
              ),
              CupertinoButton(
                child: Text('下载'),
                onPressed: () {
                  downloadManager.startDownload(
                    videoId: '300852684',
                    token: '2mTL4Jw709nFbckRSbAqZ92nuYlhGz1otveAFJcn0s44aYPNeoK15TG5JtrxIFp-',
                    title: '课程1',
                  );
                },
              ),
              CupertinoButton(
                child: const Text('全屏'),
                onPressed: () async {
                  _isFullscreen = true;
                  setState(() {});
                  _setPreferredOrientation();
                  await VideoPage(
                    controller: controller,
                    videoKey: videoKey,
                  ).show(context);
                  _isFullscreen = false;
                  setState(() {});
                  _setPreferredOrientation();
                },
              ),
            ],
          ),
          Expanded(
            child: _isFullscreen
                ? const SizedBox()
                : CustomVideoPlayerWidget(
                    key: videoKey,
                    controller: controller,
                  ),
          ),
        ],
      ),
    );
  }
}

class CustomVideoPlayerWidget extends StatelessWidget {
  const CustomVideoPlayerWidget({
    super.key,
    required this.controller,
  });

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: Consumer<VideoPlayerController>(
        builder: (context, controller, child) {
          final isLoading = context
              .select((VideoPlayerController controller) => !controller.value.isReady || controller.value.isBuffering);
          return Stack(
            children: [
              VideoPlayerWidget(
                controller: controller,
              ),
              if (isLoading)
                const Positioned.fill(
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}

class VideoPage extends StatefulWidget {
  const VideoPage({
    super.key,
    required this.controller,
    required this.videoKey,
  });

  final VideoPlayerController controller;
  final GlobalKey videoKey;

  Future show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) => this,
    );
  }

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  bool _willPop = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) {
        if (didPop) return;
        setState(() {
          _willPop = true;
        });
        // 增加点延迟，GlobalKey同时存在多个会报错
        Future.microtask(() => Navigator.of(context).pop());
      },
      canPop: false,
      child: GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        behavior: HitTestBehavior.opaque,
        child: Scaffold(
          body: _willPop
              ? const SizedBox()
              : CustomVideoPlayerWidget(
                  key: widget.videoKey,
                  controller: widget.controller,
                ),
        ),
      ),
    );
  }
}
