import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:http/http.dart' as http;
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
  bool _isInitializing = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      // 1. We resolve the redirect URL manually because VLC sometimes fails with HTTP 302 redirects
      final response = await http.Request('GET', Uri.parse(widget.playUrl)).send();
      
      // The final URL after any redirects
      final finalUrl = response.request?.url.toString() ?? widget.playUrl;

      // 2. Initialize VLC with the final direct URL
      _vlcViewController = VlcPlayerController.network(
        finalUrl,
        hwAcc: HwAcc.full,
        autoPlay: true,
        options: VlcPlayerOptions(
          advanced: VlcAdvancedOptions([
            VlcAdvancedOptions.networkCaching(2000),
          ]),
          http: VlcHttpOptions([
            VlcHttpOptions.httpReconnect(true),
          ]),
          extras: [
            '--http-user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36',
          ],
        ),
      );

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMsg = e.toString();
        });
      }
    }
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
        child: _isInitializing
            ? const CircularProgressIndicator(color: Constants.primaryColor)
            : _errorMsg != null
                ? Text('Error loading channel: $_errorMsg', style: const TextStyle(color: Colors.redAccent))
                : VlcPlayer(
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
