import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../constants.dart';

class ApiService {
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');
    
    if (deviceId == null) {
      final deviceInfoPlugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceId = iosInfo.identifierForVendor;
      } else {
        deviceId = 'dev_${DateTime.now().millisecondsSinceEpoch}';
      }
      // Ensure we have a string
      deviceId ??= 'dev_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('device_id', deviceId);
    }
    
    return deviceId;
  }

  static Future<Map<String, dynamic>> login(String code) async {
    final mac = await getDeviceId();
    final url = Uri.parse('${Constants.apiUrl}?action=login&code=${Uri.encodeComponent(code)}&mac=${Uri.encodeComponent(mac)}');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Login error: $e');
    }
    return {'success': false, 'message': 'Network Error'};
  }

  static Future<List<dynamic>> getCategories(String code) async {
    final url = Uri.parse('${Constants.apiUrl}?action=categories&code=${Uri.encodeComponent(code)}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['data'];
        }
      }
    } catch (e) {
      print('Categories error: $e');
    }
    return [];
  }
  
  static Future<List<dynamic>> getCountries(String code) async {
    final url = Uri.parse('${Constants.apiUrl}?action=countries&code=${Uri.encodeComponent(code)}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['data'];
        }
      }
    } catch (e) {
      print('Countries error: $e');
    }
    return [];
  }

  static Future<List<dynamic>> getChannels(String code, String type, int id) async {
    final url = Uri.parse('${Constants.apiUrl}?action=channels&code=${Uri.encodeComponent(code)}&type=$type&id=$id');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['channels'] as List<dynamic>;
        }
      }
    } catch (e) {
      print('Channels error: $e');
    }
    return [];
  }
}
