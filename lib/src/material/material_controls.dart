import 'dart:async';

import 'package:chewie_audio/src/animated_play_pause.dart';
import 'package:chewie_audio/src/chewie_player.dart';
import 'package:chewie_audio/src/chewie_progress_colors.dart';
import 'package:chewie_audio/src/helpers/utils.dart';
import 'package:chewie_audio/src/material/material_progress_bar.dart';
import 'package:chewie_audio/src/material/widgets/options_dialog.dart';
import 'package:chewie_audio/src/material/widgets/playback_speed_dialog.dart';
import 'package:chewie_audio/src/models/option_item.dart';
import 'package:chewie_audio/src/models/subtitle_model.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MaterialDesktopControls extends StatefulWidget {
  const MaterialDesktopControls({
    this.showPlayButton = true,
    Key? key,
  }) : super(key: key);

  final bool showPlayButton;

  @override
  State<StatefulWidget> createState() {
    return _MaterialDesktopControlsState();
  }
}

class _MaterialDesktopControlsState extends State<MaterialDesktopControls>
    with SingleTickerProviderStateMixin {
  late VideoPlayerValue _latestValue;
  double? _latestVolume;
  Timer? _initTimer;
  late var _subtitlesPosition = Duration.zero;
  bool _subtitleOn = false;
  Timer? _bufferingDisplayTimer;
  bool _displayBufferingIndicator = false;

  final barHeight = 48.0 * 1.5;
  final marginSize = 5.0;

  late VideoPlayerController controller;
  ChewieAudioController? _chewieController;

  // We know that _chewieController is set in didChangeDependencies
  ChewieAudioController get chewieController => _chewieController!;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_latestValue.hasError) {
      return chewieController.errorBuilder?.call(
            context,
            chewieController.videoPlayerController.value.errorDescription!,
          ) ??
          const Center(
            child: Icon(
              Icons.error,
              color: Colors.white,
              size: 42,
            ),
          );
    }

    return Container(
      color: Theme.of(context).colorScheme.background,
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              if (_subtitleOn)
                _buildSubtitles(context, chewieController.subtitle!),
              _buildBottomBar(context),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    controller.removeListener(_updateState);
    _initTimer?.cancel();
  }

  @override
  void didChangeDependencies() {
    final oldController = _chewieController;
    _chewieController = ChewieAudioController.of(context);
    controller = chewieController.videoPlayerController;

    if (oldController != chewieController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  Widget _buildSubtitleToggle({IconData? icon, bool isPadded = false}) {
    return IconButton(
      padding: isPadded ? const EdgeInsets.all(8.0) : EdgeInsets.zero,
      icon: Icon(icon,
          color: _subtitleOn
              ? Theme.of(context).colorScheme.onBackground
              : Theme.of(context).colorScheme.onBackground.withOpacity(0.3)),
      onPressed: _onSubtitleTap,
    );
  }

  Widget _buildOptionsButton({
    IconData? icon,
    bool isPadded = false,
  }) {
    final options = <OptionItem>[
      OptionItem(
        onTap: () async {
          Navigator.pop(context);
          _onSpeedButtonTap();
        },
        iconData: Icons.speed,
        title: chewieController.optionsTranslation?.playbackSpeedButtonText ??
            'Playback speed',
      )
    ];

    if (chewieController.additionalOptions != null &&
        chewieController.additionalOptions!(context).isNotEmpty) {
      options.addAll(chewieController.additionalOptions!(context));
    }

    return IconButton(
      padding: isPadded ? const EdgeInsets.all(8.0) : EdgeInsets.zero,
      onPressed: () async {
        if (chewieController.optionsBuilder != null) {
          await chewieController.optionsBuilder!(context, options);
        } else {
          await showModalBottomSheet<OptionItem>(
            context: context,
            isScrollControlled: true,
            builder: (context) => OptionsDialog(
              options: options,
              cancelButtonText:
                  chewieController.optionsTranslation?.cancelButtonText,
            ),
          );
        }
      },
      icon: Icon(
        icon ?? Icons.more_vert,
        color: Theme.of(context).colorScheme.onBackground,
      ),
    );
  }

  Widget _buildSubtitles(BuildContext context, Subtitles subtitles) {
    if (!_subtitleOn) {
      return const SizedBox();
    }
    final currentSubtitle = subtitles.getByPosition(_subtitlesPosition);
    if (currentSubtitle.isEmpty) {
      return const SizedBox();
    }

    if (chewieController.subtitleBuilder != null) {
      return chewieController.subtitleBuilder!(
        context,
        currentSubtitle.first!.text,
      );
    }

    return Padding(
      padding: EdgeInsets.all(marginSize),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0x96000000),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Text(
          currentSubtitle.first!.text.toString(),
          style: const TextStyle(
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
  ) {
    final iconColor = Theme.of(context).textTheme.labelLarge!.color;

    return Container(
      height: barHeight,
      padding: const EdgeInsets.only(bottom: 15),
      child: SafeArea(
        bottom: chewieController.controlsSafeAreaBottom,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          verticalDirection: VerticalDirection.up,
          children: [
            Flexible(
              child: Row(
                children: <Widget>[
                  _buildPlayPause(controller),
                  if (chewieController.isLive)
                    const Expanded(child: Text('LIVE'))
                  else
                    _buildPosition(iconColor),
                  if (!chewieController.isLive) _buildProgressBar(),
                  _buildMuteButton(controller),
                  if (chewieController.showControls &&
                      chewieController.subtitle != null &&
                      chewieController.subtitle!.isNotEmpty)
                    _buildSubtitleToggle(icon: Icons.subtitles),
                  if (chewieController.showOptions)
                    _buildOptionsButton(icon: Icons.more_vert),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSpeedButtonTap() async {
    final chosenSpeed = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (context) => PlaybackSpeedDialog(
        speeds: chewieController.playbackSpeeds,
        selected: _latestValue.playbackSpeed,
      ),
    );

    if (chosenSpeed != null) {
      controller.setPlaybackSpeed(chosenSpeed);
    }
  }

  GestureDetector _buildMuteButton(
    VideoPlayerController controller,
  ) {
    return GestureDetector(
      onTap: () {
        if (_latestValue.volume == 0) {
          controller.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller.value.volume;
          controller.setVolume(0.0);
        }
      },
      child: ClipRect(
        child: Container(
          height: barHeight,
          padding: const EdgeInsets.only(
            left: 15.0,
          ),
          child: Icon(
            _latestValue.volume > 0 ? Icons.volume_up : Icons.volume_off,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
      ),
    );
  }

  GestureDetector _buildPlayPause(VideoPlayerController controller) {
    return GestureDetector(
      onTap: _playPause,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        margin: const EdgeInsets.only(left: 8.0, right: 4.0),
        padding: const EdgeInsets.only(
          left: 12.0,
          right: 12.0,
        ),
        child: _displayBufferingIndicator
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : AnimatedPlayPause(
                playing: controller.value.isPlaying,
                color: Theme.of(context).colorScheme.onBackground,
              ),
      ),
    );
  }

  Widget _buildPosition(Color? iconColor) {
    final position = _latestValue.position;
    final duration = _latestValue.duration;

    return Text(
      '${formatDuration(position)} / ${formatDuration(duration)}',
      style: TextStyle(
        fontSize: 14.0,
        color: Theme.of(context).colorScheme.onBackground,
      ),
    );
  }

  void _onSubtitleTap() {
    setState(() {
      _subtitleOn = !_subtitleOn;
    });
  }

  Future<void> _initialize() async {
    _subtitleOn = chewieController.subtitle?.isNotEmpty ?? false;
    controller.addListener(_updateState);

    _updateState();
  }

  void _playPause() {
    final isFinished = _latestValue.position >= _latestValue.duration;

    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        if (!controller.value.isInitialized) {
          controller.initialize().then((_) {
            controller.play();
          });
        } else {
          if (isFinished) {
            controller.seekTo(Duration.zero);
          }
          controller.play();
        }
      }
    });
  }

  void _bufferingTimerTimeout() {
    _displayBufferingIndicator = true;
    if (mounted) {
      setState(() {});
    }
  }

  void _updateState() {
    if (!mounted) return;

    // display the progress bar indicator only after the buffering delay if it has been set
    if (chewieController.progressIndicatorDelay != null) {
      if (controller.value.isBuffering) {
        _bufferingDisplayTimer ??= Timer(
          chewieController.progressIndicatorDelay!,
          _bufferingTimerTimeout,
        );
      } else {
        _bufferingDisplayTimer?.cancel();
        _bufferingDisplayTimer = null;
        _displayBufferingIndicator = false;
      }
    } else {
      _displayBufferingIndicator = controller.value.isBuffering;
    }

    setState(() {
      _latestValue = controller.value;
      _subtitlesPosition = controller.value.position;
    });
  }

  Expanded _buildProgressBar() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: MaterialVideoProgressBar(
          controller,
          colors: chewieController.materialProgressColors ??
              ChewieProgressColors(
                playedColor: Theme.of(context).colorScheme.secondary,
                handleColor: Theme.of(context).colorScheme.secondary,
                bufferedColor:
                    Theme.of(context).colorScheme.background.withOpacity(0.5),
                backgroundColor:
                    Theme.of(context).disabledColor.withOpacity(.5),
              ),
        ),
      ),
    );
  }
}
