import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:cast/cast.dart';
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

  Future<void> _showCastDevices(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('البحث عن أجهزة التلفاز...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري البحث في شبكة Wi-Fi...'),
          ],
        ),
      ),
    );

    try {
      final castDiscoveryService = CastDiscoveryService();
      final devices = await castDiscoveryService.search();

      if (!context.mounted) return;
      Navigator.pop(context); // Close search dialog

      if (devices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يتم العثور على أجهزة Chromecast في هذه الشبكة.')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('اختر التلفاز للبث'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  return ListTile(
                    leading: const Icon(Icons.tv),
                    title: Text(device.friendlyName ?? 'تلفاز غير معروف'),
                    onTap: () async {
                      Navigator.pop(context);
                      await _connectAndCast(device);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              )
            ],
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء البحث: $e')),
      );
    }
  }

  Future<void> _connectAndCast(CastDevice device) async {
    try {
      final session = await CastSessionManager().startSession(device);

      session.sendMessage(CastSession.kNamespaceMedia, {
        'type': 'LOAD',
        'autoPlay': true,
        'currentTime': 0,
        'media': {
          'contentId': widget.playUrl,
          'contentType': 'application/x-mpegurl', // or video/mp4 depending on format
          'streamType': 'LIVE',
          'metadata': {
            'type': 0,
            'metadataType': 0,
            'title': widget.channelName,
            'images': [
               {'url': 'https://app.hr-tech.site/apk%20iptv/assets/icon.png'}
            ]
          }
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إرسال البث إلى ${device.friendlyName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الاتصال بالتلفاز: $e')),
        );
      }
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.cast, color: Colors.white),
            tooltip: 'بث للتلفاز',
            onPressed: () => _showCastDevices(context),
          ),
        ],
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
