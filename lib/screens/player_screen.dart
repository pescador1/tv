import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
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
  late VlcPlayerController _vlcViewController;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _vlcViewController = VlcPlayerController.network(
      widget.playUrl,
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([
          VlcAdvancedOptions.networkCaching(2000),
        ]),
        http: VlcHttpOptions([
          VlcHttpOptions.httpReconnect(true),
        ]),
      ),
    );
  }

  @override
  void dispose() async {
    super.dispose();
    await _vlcViewController.stopRendererScanning();
    await _vlcViewController.dispose();
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
      body: Center(
        child: VlcPlayer(
          controller: _vlcViewController,
          aspectRatio: 16 / 9,
          placeholder: const Center(child: CircularProgressIndicator(color: Constants.primaryColor)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Constants.primaryColor,
        onPressed: () {
          if (_isPlaying) {
            _vlcViewController.pause();
          } else {
            _vlcViewController.play();
          }
          setState(() {
            _isPlaying = !_isPlaying;
          });
        },
        child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
      ),
    );
  }
}
