import 'package:flutter/material.dart';

import 'video_player_controller.dart';

class VideoPlayerWidget extends StatelessWidget {
  const VideoPlayerWidget({
    super.key,
    required this.controller,
  });

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return controller.platform.build(context);
  }
}
