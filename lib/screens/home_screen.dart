import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'categories_screen.dart';
import 'channels_screen.dart';

class HomeScreen extends StatefulWidget {
  final String code;
  const HomeScreen({super.key, required this.code});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  int _totalChannels = 0;
  int _favCount = 0;
  String _deviceId = 'Loading...';

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    await ApiService.initSettings();
    final devId = await ApiService.getDeviceId();
    final cats = await ApiService.getCategories(widget.code);
    
    final prefs = await SharedPreferences.getInstance();
    final favList = prefs.getStringList('favorite_channels_list') ?? [];

    int count = 0;
    for (var c in cats) {
      count += (c['channels_count'] ?? 0) as int;
    }
    if (mounted) {
      setState(() {
        _deviceId = devId;
        _totalChannels = count;
        _favCount = favList.length;
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

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Constants.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.settings, color: Constants.primaryColor, size: 24),
                  const SizedBox(width: 10),
                  const Text(
                    'Settings & Account Info',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Constants.textMuted, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: Constants.cardBorderColor, height: 24),

              _buildInfoRow('App Name (اسم اللوحة):', ApiService.appName, Icons.title),
              const SizedBox(height: 12),
              _buildInfoRow('Access Code (رمز الدخول):', widget.code, Icons.vpn_key),
              const SizedBox(height: 12),
              _buildInfoRow('Device ID / MAC:', _deviceId, Icons.important_devices),
              const SizedBox(height: 12),
              _buildInfoRow('Status (الحالة):', 'Active (نشط)', Icons.verified, valueColor: Colors.greenAccent),
              const SizedBox(height: 12),
              _buildInfoRow('Total Channels (القنوات):', '$_totalChannels Channels', Icons.tv),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Constants.bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Constants.cardBorderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Constants.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Constants.textMuted, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthStr = months[now.month - 1];
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final amPm = now.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = now.minute.toString().padLeft(2, '0');
    final nowStr = '$monthStr ${now.day}, ${now.year} - ${hour.toString().padLeft(2, '0')}:$minuteStr $amPm';

    return Scaffold(
      backgroundColor: Constants.bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // Top Bar
              Row(
                children: [
                  Row(
                    children: [
                      if (ApiService.logoUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            ApiService.logoUrl,
                            height: 36,
                            width: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildFallbackLogoIcon(),
                          ),
                        )
                      else
                        _buildFallbackLogoIcon(),
                      
                      const SizedBox(width: 12),
                      Text(
                        ApiService.appName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    nowStr,
                    style: const TextStyle(
                      color: Constants.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: _showSettingsDialog,
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
                    // LIVE TV Card
                    Expanded(
                      flex: 2,
                      child: _buildLiveTvCard(),
                    ),
                    const SizedBox(width: 24),

                    // Favourites Card Only
                    Expanded(
                      flex: 1,
                      child: _buildFavoritesCard(),
                    ),
                  ],
                ),
              ),

              // Footer Note
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  '${ApiService.appName} - Powered by PESCADOR',
                  style: const TextStyle(color: Constants.textMuted, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackLogoIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Constants.primaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
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

  Widget _buildFavoritesCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChannelsScreen(
                code: widget.code,
                type: 'favorites',
                id: 0,
                title: 'Favourites (المفضلة)',
              ),
            ),
          );
          _fetchStats();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Constants.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Constants.cardBorderColor),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: -10,
                child: Icon(
                  Icons.favorite,
                  size: 140,
                  color: Colors.white.withOpacity(0.02),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        size: 40,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Favourites',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$_favCount Saved Channels',
                      style: const TextStyle(
                        color: Constants.textMuted,
                        fontSize: 12,
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
}
