import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import '../services/api_service.dart';
import '../services/app_language.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkExistingLogin();
  }

  Future<void> _checkExistingLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString('access_code');
    
    if (savedCode != null && savedCode.isNotEmpty) {
      setState(() => _isLoading = true);
      final response = await ApiService.login(savedCode);
      setState(() => _isLoading = false);
      
      if (response['success'] == true) {
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(code: savedCode)));
        }
      }
    }
  }

  Future<void> _login() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = AppLanguage.tr('please_enter_code'));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final response = await ApiService.login(code);

    setState(() => _isLoading = false);

    if (response['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_code', code);
      
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(code: code)));
      }
    } else {
      setState(() {
        _errorMessage = response['message'] ?? AppLanguage.tr('invalid_code');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Constants.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Constants.primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/icon/icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.tv, size: 50, color: Constants.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'HR TV',
                  style: TextStyle(
                    color: Constants.textMain,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLanguage.tr('login_sub'),
                  style: const TextStyle(
                    color: Constants.textMuted,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                if (_errorMessage.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Container(
                  decoration: BoxDecoration(
                    color: Constants.cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _codeController,
                    style: const TextStyle(color: Constants.textMain, fontSize: 18, letterSpacing: 2),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: AppLanguage.tr('access_code_hint'),
                      hintStyle: TextStyle(color: Constants.textMuted.withOpacity(0.5), letterSpacing: 0),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 5,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            AppLanguage.tr('connect_btn'),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () async {
                    final Uri url = Uri.parse('http://generator.hr-tech.site/');
                    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open the browser')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.card_giftcard, color: Constants.primaryColor),
                  label: Text(
                    AppLanguage.tr('free_trial_btn'),
                    style: const TextStyle(
                      color: Constants.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    backgroundColor: Constants.primaryColor.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
