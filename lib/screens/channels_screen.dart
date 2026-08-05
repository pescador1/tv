import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../constants.dart';
import '../services/api_service.dart';

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
  dynamic _selectedChannel;
  late final WebViewController _webViewController;
  bool _isVideoLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initWebView();
    _fetchChannels();
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) setState(() => _isVideoLoading = true);
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _isVideoLoading = false);
          },
        ),
      );
  }

  Future<void> _fetchChannels() async {
    setState(() => _isLoading = true);
    final channels = await ApiService.getChannels(widget.code, widget.type, widget.id);
    if (mounted) {
      setState(() {
        _channels = channels;
        _isLoading = false;
        if (_channels.isNotEmpty) {
          _playChannel(_channels[0]);
        }
      });
    }
  }

  void _playChannel(dynamic channel) {
    setState(() {
      _selectedChannel = channel;
      _isVideoLoading = true;
    });
    final playUrl = channel['play_url'] ?? '';
    if (playUrl.isNotEmpty) {
      _webViewController.loadRequest(Uri.parse(playUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredChannels = _channels.where((ch) {
      final name = (ch['name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Constants.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Constants.cardColor,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Favorite / Search Icons
                  IconButton(
                    icon: const Icon(Icons.favorite_border, color: Constants.textMuted),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Split Screen Body
            Expanded(
              child: Row(
                children: [
                  // Left Side: Channel List (350px)
                  Container(
                    width: 340,
                    decoration: const BoxDecoration(
                      color: Constants.bgColor,
                      border: Border(
                        right: BorderSide(color: Constants.cardBorderColor, width: 1),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Channel Search Input
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Constants.cardColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Constants.cardBorderColor),
                            ),
                            child: TextField(
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              onChanged: (val) => setState(() => _searchQuery = val),
                              decoration: const InputDecoration(
                                hintText: 'Search channel...',
                                hintStyle: TextStyle(color: Constants.textMuted, fontSize: 12),
                                border: InputBorder.none,
                                icon: Icon(Icons.search, color: Constants.textMuted, size: 16),
                              ),
                            ),
                          ),
                        ),

                        // List of Channels
                        Expanded(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator(color: Constants.primaryColor))
                              : filteredChannels.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No Channels',
                                        style: TextStyle(color: Constants.textMuted),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: filteredChannels.length,
                                      itemBuilder: (context, index) {
                                        final channel = filteredChannels[index];
                                        final isSelected = _selectedChannel != null &&
                                            _selectedChannel['id'] == channel['id'];

                                        return _buildChannelItem(channel, isSelected);
                                      },
                                    ),
                        ),
                      ],
                    ),
                  ),

                  // Right Side: Embedded Video Player + EPG Info
                  Expanded(
                    child: Container(
                      color: Colors.black,
                      child: _selectedChannel == null
                          ? const Center(
                              child: Text(
                                'Select a channel to play',
                                style: TextStyle(color: Constants.textMuted),
                              ),
                            )
                          : Stack(
                              children: [
                                // Video Player Widget
                                Center(
                                  child: AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: WebViewWidget(controller: _webViewController),
                                  ),
                                ),

                                // Video Loading Indicator Overlay
                                if (_isVideoLoading)
                                  Container(
                                    color: Colors.black54,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Constants.primaryColor,
                                      ),
                                    ),
                                  ),

                                // Channel Overlay Title (Top Left of Player)
                                Positioned(
                                  top: 16,
                                  left: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.circle,
                                          color: Colors.redAccent,
                                          size: 10,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _selectedChannel['name'] ?? 'Channel',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelItem(dynamic channel, bool isSelected) {
    final logoUrl = channel['logo_url'] ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _playChannel(channel),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Constants.activeCardColor : Colors.transparent,
            border: Border(
              left: isSelected
                  ? const BorderSide(color: Constants.primaryColor, width: 4)
                  : BorderSide.none,
              bottom: const BorderSide(color: Constants.cardBorderColor, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              // Channel Icon / Logo
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Constants.cardColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: logoUrl.isNotEmpty
                    ? Image.network(
                        logoUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.tv,
                          color: Constants.textMuted,
                          size: 20,
                        ),
                      )
                    : const Icon(Icons.tv, color: Constants.textMuted, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  channel['name'] ?? '',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Constants.textMuted,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.play_circle_fill,
                  color: Constants.primaryColor,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
