import 'package:flutter/material.dart';

import 'video_player_controller.dart';

class VideoPlayerWidget extends StatefulWidget {
  const VideoPlayerWidget({
    super.key,
    required this.controller,
  });

  final VideoPlayerController controller;

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  Size _videoSize = Size.zero;
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      if (_videoSize != widget.controller.value.size) {
        _videoSize = widget.controller.value.size;
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: _videoSize == Size.zero ? 1 : _videoSize.width / _videoSize.height,
        child: IgnorePointer(
          child: widget.controller.platform.build(context),
        ),
      ),
    );
  }
}
