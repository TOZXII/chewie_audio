import 'package:chewie_audio_fork/src/chewie_progress_colors.dart';
import 'package:chewie_audio_fork/src/progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MaterialVideoProgressBar extends StatelessWidget {
  MaterialVideoProgressBar(
    this.controller, {
    this.height = kToolbarHeight,
    ChewieProgressColors? colors,
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
    Key? key,
  })  : colors = colors ?? ChewieProgressColors(),
        super(key: key);

  final double height;
  final VideoPlayerController controller;
  final ChewieProgressColors colors;
  final Function()? onDragStart;
  final Function()? onDragEnd;
  final Function()? onDragUpdate;

  @override
  Widget build(BuildContext context) {
    return VideoProgressBar(
      controller,
      barHeight: 10,
      handleHeight: 6,
      drawShadow: true,
      colors: colors,
      onDragEnd: onDragEnd,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
    );
  }
}
