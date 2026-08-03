import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'channels_screen.dart';

class HomeScreen extends StatefulWidget {
  final String code;
  const HomeScreen({super.key, required this.code});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  List<dynamic> _categories = [];
  List<dynamic> _countries = [];
  int _currentIndex = 0; // 0 for Categories, 1 for Countries

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final cats = await ApiService.getCategories(widget.code);
    final counts = await ApiService.getCountries(widget.code);
    if (mounted) {
      setState(() {
        _categories = cats;
        _countries = counts;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_code');
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentList = _currentIndex == 0 ? _categories : _countries;
    final String type = _currentIndex == 0 ? 'category' : 'country';

    return Scaffold(
      backgroundColor: Constants.bgColor,
      appBar: AppBar(
        backgroundColor: Constants.bgColor,
        elevation: 0,
        title: const Text('HR TV', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _logout,
          )
        ],
      ),
      body: Column(
        children: [
          // Custom Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentIndex = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _currentIndex == 0 ? Constants.primaryColor : Constants.cardColor,
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Categories',
                        style: TextStyle(
                          color: _currentIndex == 0 ? Colors.white : Constants.textMuted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentIndex = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _currentIndex == 1 ? Constants.primaryColor : Constants.cardColor,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Countries',
                        style: TextStyle(
                          color: _currentIndex == 1 ? Colors.white : Constants.textMuted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : currentList.isEmpty
                    ? const Center(child: Text('No data found.', style: TextStyle(color: Constants.textMuted)))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: currentList.length,
                        itemBuilder: (context, index) {
                          final item = currentList[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChannelsScreen(
                                    code: widget.code,
                                    type: type,
                                    id: int.parse(item['id'].toString()),
                                    title: item['name'],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Constants.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.05)),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _currentIndex == 0 ? Icons.folder : Icons.public,
                                    size: 32,
                                    color: Constants.primaryColor,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    item['name'],
                                    style: const TextStyle(
                                      color: Constants.textMain,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item['channels_count']} channels',
                                    style: const TextStyle(
                                      color: Constants.textMuted,
                                      fontSize: 12,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
