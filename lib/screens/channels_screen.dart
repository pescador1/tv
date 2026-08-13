import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../services/api_service.dart';
import '../services/app_language.dart';
import 'player_screen.dart';

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
  List<dynamic> _favorites = [];
  dynamic _selectedChannel;
  late final WebViewController _webViewController;
  bool _isVideoLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initWebView();
    _loadFavorites().then((_) => _fetchChannels());
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

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favList = prefs.getStringList('favorite_channels_list') ?? [];
    if (mounted) {
      setState(() {
        _favorites = favList.map((e) => json.decode(e)).toList();
      });
    }
  }

  Future<void> _toggleFavorite(dynamic channel) async {
    final prefs = await SharedPreferences.getInstance();
    final favList = prefs.getStringList('favorite_channels_list') ?? [];
    
    final chId = channel['id'].toString();
    final existsIndex = _favorites.indexWhere((c) => c['id'].toString() == chId);

    if (existsIndex >= 0) {
      _favorites.removeAt(existsIndex);
      favList.removeWhere((e) {
        final decoded = json.decode(e);
        return decoded['id'].toString() == chId;
      });
    } else {
      _favorites.add(channel);
      favList.add(json.encode(channel));
    }

    await prefs.setStringList('favorite_channels_list', favList);
    if (mounted) setState(() {});
  }

  bool _isFavorite(dynamic channel) {
    if (channel == null) return false;
    final chId = channel['id'].toString();
    return _favorites.any((c) => c['id'].toString() == chId);
  }

  Future<void> _fetchChannels() async {
    setState(() => _isLoading = true);

    if (widget.type == 'favorites') {
      if (mounted) {
        setState(() {
          _channels = List.from(_favorites);
          _isLoading = false;
          if (_channels.isNotEmpty) {
            _playChannel(_channels[0]);
          }
        });
      }
      return;
    }

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

  void _openFullScreen(dynamic channel) {
    final playUrl = channel['play_url'] ?? '';
    final name = channel['name'] ?? 'Channel';
    if (playUrl.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerScreen(
            channelName: name,
            playUrl: playUrl,
          ),
        ),
      );
    }
  }

  Future<void> _reportChannel(dynamic channel) async {
    if (channel == null) return;
    final chId = int.tryParse(channel['id'].toString()) ?? 0;
    if (chId == 0) return;

    final res = await ApiService.reportChannel(chId);
    if (mounted) {
      final action = res['heal_action'] ?? res['action'] ?? '';
      if (action == 'hidden') {
        setState(() {
          _channels.removeWhere((c) => c['id'].toString() == chId.toString());
          if (_selectedChannel != null && _selectedChannel['id'].toString() == chId.toString()) {
            if (_channels.isNotEmpty) {
              _playChannel(_channels[0]);
            } else {
              _selectedChannel = null;
            }
          }
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? AppLanguage.tr('report_submitted')),
          backgroundColor: res['success'] == true ? Colors.green : Colors.redAccent,
        ),
      );
    }
  }

  String _formatLogoUrl(String? rawUrl) {
    if (rawUrl == null) return '';
    String url = rawUrl.trim();
    if (url.isEmpty) return '';
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.startsWith('/')) {
        return '${Constants.baseUrl}$url';
      } else {
        return '${Constants.baseUrl}/$url';
      }
    }
    return url;
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
                    icon: Icon(
                      AppLanguage.isRtl ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 18,
                    ),
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
                  if (_selectedChannel != null) ...[
                    IconButton(
                      icon: const Icon(Icons.report_problem, color: Colors.amberAccent),
                      tooltip: AppLanguage.tr('report_channel'),
                      onPressed: () => _reportChannel(_selectedChannel),
                    ),
                    IconButton(
                      icon: Icon(
                        _isFavorite(_selectedChannel) ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite(_selectedChannel) ? Colors.redAccent : Constants.textMuted,
                      ),
                      onPressed: () => _toggleFavorite(_selectedChannel),
                    ),
                  ],
                ],
              ),
            ),

            // Split Screen Body
            Expanded(
              child: Row(
                children: [
                  // Left Side: Channel List (340px)
                  Container(
                    width: 340,
                    decoration: BoxDecoration(
                      color: Constants.bgColor,
                      border: Border(
                        right: AppLanguage.isRtl
                            ? BorderSide.none
                            : const BorderSide(color: Constants.cardBorderColor, width: 1),
                        left: AppLanguage.isRtl
                            ? const BorderSide(color: Constants.cardBorderColor, width: 1)
                            : BorderSide.none,
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
                              decoration: InputDecoration(
                                hintText: AppLanguage.tr('search_channel_hint'),
                                hintStyle: const TextStyle(color: Constants.textMuted, fontSize: 12),
                                border: InputBorder.none,
                                icon: const Icon(Icons.search, color: Constants.textMuted, size: 16),
                              ),
                            ),
                          ),
                        ),

                        // List of Channels
                        Expanded(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator(color: Constants.primaryColor))
                              : filteredChannels.isEmpty
                                  ? Center(
                                      child: Text(
                                        AppLanguage.tr('no_channels'),
                                        style: const TextStyle(color: Constants.textMuted),
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

                  // Right Side: Embedded Video Player
                  Expanded(
                    child: Container(
                      color: Colors.black,
                      child: _selectedChannel == null
                          ? Center(
                              child: Text(
                                AppLanguage.tr('select_channel_to_play'),
                                style: const TextStyle(color: Constants.textMuted),
                              ),
                            )
                          : GestureDetector(
                              onDoubleTap: () => _openFullScreen(_selectedChannel),
                              child: Stack(
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

                                  // Channel Title Overlay (Top Left)
                                  Positioned(
                                    top: 16,
                                    left: AppLanguage.isRtl ? null : 16,
                                    right: AppLanguage.isRtl ? 16 : null,
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

                                  // Action Overlay Buttons (Top Right: Favorite & Report)
                                  Positioned(
                                    top: 16,
                                    right: AppLanguage.isRtl ? null : 16,
                                    left: AppLanguage.isRtl ? 16 : null,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: () => _reportChannel(_selectedChannel),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.7),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.1),
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.report_problem,
                                              color: Colors.amberAccent,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () => _toggleFavorite(_selectedChannel),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.7),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.1),
                                              ),
                                            ),
                                            child: Icon(
                                              _isFavorite(_selectedChannel)
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: _isFavorite(_selectedChannel)
                                                  ? Colors.redAccent
                                                  : Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
    final logoUrl = _formatLogoUrl(channel['logo_url'] ?? channel['stream_icon']);
    final isFav = _isFavorite(channel);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _playChannel(channel),
        onDoubleTap: () => _openFullScreen(channel),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Constants.activeCardColor : Colors.transparent,
            border: Border(
              left: isSelected && !AppLanguage.isRtl
                  ? const BorderSide(color: Constants.primaryColor, width: 4)
                  : BorderSide.none,
              right: isSelected && AppLanguage.isRtl
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
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          logoUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.tv,
                            color: Constants.textMuted,
                            size: 20,
                          ),
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
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.redAccent : Constants.textMuted.withOpacity(0.4),
                  size: 18,
                ),
                onPressed: () => _toggleFavorite(channel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
