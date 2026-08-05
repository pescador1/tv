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
  List<dynamic> _countries = [];
  int _selectedTab = 0; // 0 for Categories (أصناف), 1 for Countries (دول)
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final cats = await ApiService.getCategories(widget.code);
    final countries = await ApiService.getCountries(widget.code);
    if (mounted) {
      setState(() {
        _categories = cats;
        _countries = countries;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentList = _selectedTab == 0 ? _categories : _countries;
    final currentType = _selectedTab == 0 ? 'category' : 'country';

    final filteredList = currentList.where((item) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Constants.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),

                  // Dynamic App Logo & Name Header
                  Row(
                    children: [
                      if (ApiService.logoUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            ApiService.logoUrl,
                            height: 28,
                            width: 28,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildDefaultAppIcon(),
                          ),
                        )
                      else
                        _buildDefaultAppIcon(),
                      const SizedBox(width: 10),
                      Text(
                        ApiService.appName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  
                  // Toggle Switch (Categories / Countries)
                  Container(
                    decoration: BoxDecoration(
                      color: Constants.cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Constants.cardBorderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTabButton(
                          title: 'Categories (أصناف)',
                          icon: Icons.category,
                          isSelected: _selectedTab == 0,
                          onTap: () => setState(() => _selectedTab = 0),
                        ),
                        _buildTabButton(
                          title: 'Countries (دول)',
                          icon: Icons.public,
                          isSelected: _selectedTab == 1,
                          onTap: () => setState(() => _selectedTab = 1),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Search Box
                  Container(
                    width: 200,
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Constants.cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Constants.cardBorderColor),
                    ),
                    child: TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        hintStyle: TextStyle(color: Constants.textMuted, fontSize: 12),
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
                  : filteredList.isEmpty
                      ? const Center(
                          child: Text(
                            'No items found',
                            style: TextStyle(color: Constants.textMuted, fontSize: 16),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 3.2,
                          ),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final item = filteredList[index];
                            return _buildCard(item, currentType);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAppIcon() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Constants.primaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.live_tv, color: Constants.primaryColor, size: 18),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Constants.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : Constants.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Constants.textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(dynamic item, String type) {
    final name = item['name'] ?? 'Unknown';
    final count = item['channels_count'] ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChannelsScreen(
                code: widget.code,
                type: type,
                id: int.parse(item['id'].toString()),
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
                child: Icon(
                  type == 'category' ? Icons.connected_tv : Icons.public,
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
