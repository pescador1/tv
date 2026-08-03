import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../services/api_service.dart';
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
      setState(() => _errorMessage = 'Please enter your access code');
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
        _errorMessage = response['message'] ?? 'Invalid access code';
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
                const Text(
                  'Enter your access code to start watching',
                  style: TextStyle(
                    color: Constants.textMuted,
                    fontSize: 16,
                  ),
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
                      hintText: 'Access Code',
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
                        : const Text(
                            'Connect',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
