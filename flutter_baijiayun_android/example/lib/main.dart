import 'package:flutter/material.dart';
import 'package:flutter_baijiayun_android/flutter_baijiayun_android.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomePage());
  }
}

class VideoPlayerWidget extends StatelessWidget {
  const VideoPlayerWidget({
    super.key,
    required this.controller,
  });

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return controller.build(context);
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final controller = VideoPlayerController(
    VideoPlayerControllerCreationParams(),
  );

  @override
  void initState() {
    super.initState();
    controller.setOnlineVideo(
      id: '160491264',
      token: 'Vaac3j5n5hdjXPso7IvWENxo6c4wA6poVNb7GL8FoVwnHPIguunSCjG5JtrxIFp-',
    );
    controller.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: VideoPlayerWidget(
        controller: controller,
      ),
    );
  }
}
