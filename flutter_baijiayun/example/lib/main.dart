import 'package:flutter/material.dart';

import 'package:flutter_baijiayun/flutter_baijiayun.dart';

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

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      print(controller.value);
    });
    controller.setOnlineVideo(
      id: '300640151',
      token: '1HESMHR94-7FbckRSbAqZyYRZOjsF88q1yJXKdiXZWDAUE3NDhIV_TG5JtrxIFp-',
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
