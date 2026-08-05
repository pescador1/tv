import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/api_service.dart';
import 'channels_screen.dart';

class CategoriesScreen extends StatefulWidget {
  final String code;

  const CategoriesScreen({super.key, required this.code});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _isLoading = true;
  List<dynamic> _categories = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    final cats = await ApiService.getCategories(widget.code);
    if (mounted) {
      setState(() {
        _categories = cats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories = _categories.where((cat) {
      final name = (cat['name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Constants.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Constants.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.live_tv, color: Constants.primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'IPTV Xtream Code Player',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Search Box
                  Container(
                    width: 250,
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Constants.cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Constants.cardBorderColor),
                    ),
                    child: TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: const InputDecoration(
                        hintText: 'Search Category...',
                        hintStyle: TextStyle(color: Constants.textMuted, fontSize: 13),
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: Constants.textMuted, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content Grid
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Constants.primaryColor))
                  : filteredCategories.isEmpty
                      ? const Center(
                          child: Text(
                            'No Categories Found',
                            style: TextStyle(color: Constants.textMuted, fontSize: 16),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, // 3 items per row for TV layout
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 3.2, // Wide landscape card like in video
                          ),
                          itemCount: filteredCategories.length,
                          itemBuilder: (context, index) {
                            final cat = filteredCategories[index];
                            return _buildCategoryCard(cat);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(dynamic category) {
    final name = category['name'] ?? 'Unknown';
    final count = category['channels_count'] ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChannelsScreen(
                code: widget.code,
                type: 'category',
                id: int.parse(category['id'].toString()),
                title: name,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Constants.cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Constants.cardBorderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.connected_tv,
                  color: Constants.primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count Channels',
                      style: const TextStyle(
                        color: Constants.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Constants.textMuted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
