import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../constants.dart';

class PlayerScreen extends StatefulWidget {
  final String channelName;
  final String playUrl;

  const PlayerScreen({
    super.key,
    required this.channelName,
    required this.playUrl,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.playUrl));
      await _videoPlayerController.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        isLive: true,
        fullScreenByDefault: true,
        allowFullScreen: true,
        allowMuting: true,
        showControlsOnInitialize: false,
        placeholder: const Center(child: CircularProgressIndicator()),
        materialProgressColors: ChewieProgressColors(
          playedColor: Constants.primaryColor,
          handleColor: Constants.accentColor,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white54,
        ),
      );
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Player Error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.channelName, style: const TextStyle(color: Colors.white)),
      ),
      extendBodyBehindAppBar: true,
      body: _hasError
          ? const Center(
              child: Text(
                'Failed to load stream. Please try again.',
                style: TextStyle(color: Colors.redAccent, fontSize: 16),
              ),
            )
          : _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
              ? SafeArea(
                  child: Chewie(
                    controller: _chewieController!,
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(color: Constants.primaryColor),
                ),
    );
  }
}
