import 'package:chewie_audio_fork/src/chewie_player.dart';
import 'package:chewie_audio_fork/src/helpers/adaptive_controls.dart';
import 'package:flutter/material.dart';

class PlayerWithControls extends StatelessWidget {
  const PlayerWithControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ChewieAudioController chewieController =
        ChewieAudioController.of(context);

    Widget buildControls(
      BuildContext context,
      ChewieAudioController chewieController,
    ) {
      return chewieController.showControls
          ? chewieController.customControls ?? const AdaptiveControls()
          : const SizedBox();
    }

    Widget buildPlayerWithControls(
      ChewieAudioController chewieController,
      BuildContext context,
    ) {
      return SafeArea(
        bottom: false,
        child: buildControls(context, chewieController),
      );
    }

    return SizedBox(
      // width: MediaQuery.of(context).size.width,
      child: buildPlayerWithControls(chewieController, context),
    );
  }
}
