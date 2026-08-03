import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/api_service.dart';
import 'player_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChannelsScreen extends StatefulWidget {
  final String code;
  final String type;
  final int id;
  final String title;

  const ChannelsScreen({
    super.key,
    required this.code,
    required this.type,
    required this.id,
    required this.title,
  });

  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> {
  bool _isLoading = true;
  List<dynamic> _channels = [];

  @override
  void initState() {
    super.initState();
    _fetchChannels();
  }

  Future<void> _fetchChannels() async {
    final channels = await ApiService.getChannels(widget.code, widget.type, widget.id);
    if (mounted) {
      setState(() {
        _channels = channels;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.bgColor,
      appBar: AppBar(
        backgroundColor: Constants.bgColor,
        title: Text(widget.title),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _channels.isEmpty
              ? const Center(child: Text('No channels found.', style: TextStyle(color: Constants.textMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _channels.length,
                  itemBuilder: (context, index) {
                    final channel = _channels[index];
                    final logoUrl = channel['logo_url'] ?? '';
                    
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Constants.cardColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: logoUrl.isNotEmpty
                            ? CachedNetworkImage( // I need to add this to pubspec! Or use Image.network for now to save a dependency. I'll use Image.network
                                imageUrl: logoUrl,
                                fit: BoxFit.contain,
                                errorWidget: (context, url, error) => const Icon(Icons.tv, color: Constants.primaryColor),
                              )
                            : const Icon(Icons.tv, color: Constants.primaryColor),
                      ),
                      title: Text(
                        channel['name'],
                        style: const TextStyle(color: Constants.textMain, fontWeight: FontWeight.bold),
                      ),
                      trailing: const Icon(Icons.play_circle_fill, color: Constants.primaryColor, size: 30),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlayerScreen(
                              channelName: channel['name'],
                              playUrl: channel['play_url'],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
