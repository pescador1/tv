import 'package:flutter/material.dart';

class Constants {
  // Updated with the provided domain (Can be modified to your server IP or domain)
  static const String apiUrl = 'http://app.hr-tech.site/app/api_mobile.php';
  
  // Dynamic Base URL getter (extracts base URL path from apiUrl)
  static String get baseUrl {
    try {
      final uri = Uri.parse(apiUrl);
      final portStr = uri.hasPort ? ':${uri.port}' : '';
      final pathSegs = uri.pathSegments;
      if (pathSegs.length > 1) {
        final parentPath = pathSegs.sublist(0, pathSegs.length - 1).join('/');
        return '${uri.scheme}://${uri.host}$portStr/$parentPath';
      }
      return '${uri.scheme}://${uri.host}$portStr';
    } catch (_) {
      return 'http://app.hr-tech.site/app';
    }
  }

  // Xtream Code Player Colors
  static const Color primaryColor = Color(0xFFFF2B55); // Red-Pink accent for LIVE TV
  static const Color accentColor = Color(0xFF6B4eff);
  static const Color bgColor = Color(0xFF100E19); // Deep dark background
  static const Color cardColor = Color(0xFF1C1A29); // Dark card color
  static const Color cardBorderColor = Color(0xFF2B283E);
  static const Color activeCardColor = Color(0xFF28253D);
  static const Color textMain = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF8A88A8);
}

