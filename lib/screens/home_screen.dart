import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'categories_screen.dart';

class HomeScreen extends StatefulWidget {
  final String code;
  const HomeScreen({super.key, required this.code});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  int _totalChannels = 0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    final cats = await ApiService.getCategories(widget.code);
    int count = 0;
    for (var c in cats) {
      count += (c['channels_count'] ?? 0) as int;
    }
    if (mounted) {
      setState(() {
        _totalChannels = count;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_code');
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nowStr = DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.now());

    return Scaffold(
      backgroundColor: Constants.bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // Top Bar (Header)
              Row(
                children: [
                  // App Branding
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Constants.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'IPTV Xtream Code Player',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Date & Info
                  Text(
                    nowStr,
                    style: const TextStyle(
                      color: Constants.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Constants.textMuted),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.power_settings_new, color: Colors.redAccent),
                    onPressed: _logout,
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Main Dashboard Area
              Expanded(
                child: Row(
                  children: [
                    // Main Big Card: LIVE TV (Left Side - Dominant)
                    Expanded(
                      flex: 2,
                      child: _buildLiveTvCard(),
                    ),
                    const SizedBox(width: 24),

                    // Secondary Action Menu (Right Side Vertical List)
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          _buildActionTile(
                            icon: Icons.history,
                            title: 'Catch up',
                            onTap: () {},
                          ),
                          const SizedBox(height: 12),
                          _buildActionTile(
                            icon: Icons.favorite,
                            title: 'Favourites',
                            onTap: () {},
                          ),
                          const SizedBox(height: 12),
                          _buildActionTile(
                            icon: Icons.qr_code,
                            title: 'IPTV Codes',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Footer Note
              const Padding(
                padding: EdgeInsets.only(top: 12.0),
                child: Text(
                  'HR TV - Powered by Xtream Engine',
                  style: TextStyle(color: Constants.textMuted, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveTvCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoriesScreen(code: widget.code),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E1A38), Color(0xFF1C1A29)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Constants.primaryColor.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Constants.primaryColor.withOpacity(0.15),
                blurRadius: 15,
                spreadRadius: 2,
              )
            ],
          ),
          child: Stack(
            children: [
              // Background Glow Icon
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.sensors,
                  size: 180,
                  color: Colors.white.withOpacity(0.03),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Constants.primaryColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.live_tv_rounded,
                        size: 54,
                        color: Constants.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'LIVE TV',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _isLoading ? 'Loading...' : '$_totalChannels Channels',
                        style: const TextStyle(
                          color: Constants.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Constants.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Constants.cardBorderColor),
            ),
            child: Row(
              children: [
                Icon(icon, color: Constants.textMuted, size: 22),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, color: Constants.textMuted, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
