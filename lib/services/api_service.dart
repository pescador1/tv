import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../constants.dart';

class ApiService {
  static String appName = 'HR TV';
  static String logoUrl = '';
  static String expDate = 'Unlimited';

  static Future<void> initSettings() async {
    final prefs = await SharedPreferences.getInstance();
    appName = prefs.getString('panel_name') ?? 'HR TV';
    logoUrl = prefs.getString('logo_url') ?? '';
    expDate = prefs.getString('exp_date') ?? 'Unlimited';
  }

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
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final prefs = await SharedPreferences.getInstance();
          if (data['panel_name'] != null && data['panel_name'].toString().isNotEmpty) {
            appName = data['panel_name'];
            await prefs.setString('panel_name', appName);
          }
          if (data['logo_url'] != null && data['logo_url'].toString().isNotEmpty) {
            logoUrl = data['logo_url'];
            await prefs.setString('logo_url', logoUrl);
          }
          final exp = data['exp_date'] ?? data['expiration'] ?? data['expire_date'];
          if (exp != null && exp.toString().isNotEmpty) {
            expDate = exp.toString();
            await prefs.setString('exp_date', expDate);
          }
        }
        return data;
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
        
        if (data['panel_name'] != null && data['panel_name'].toString().isNotEmpty) {
          appName = data['panel_name'];
        }
        if (data['logo_url'] != null && data['logo_url'].toString().isNotEmpty) {
          logoUrl = data['logo_url'];
        }
        final exp = data['exp_date'] ?? data['expiration'] ?? data['expire_date'];
        if (exp != null && exp.toString().isNotEmpty) {
          expDate = exp.toString();
        }

        if (data['success'] == true) {
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
        if (data['success'] == true) {
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
    return [];
  }

  static Future<Map<String, dynamic>> reportChannel(int channelId) async {
    // Uses web API endpoint for reporting & trigger auto-healer
    final url = Uri.parse('http://app.hr-tech.site/app/api.php?action=report&channel_id=$channelId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      }
    } catch (e) {
      print('Report channel error: $e');
    }
    return {'success': false, 'message': 'Network Error'};
  }
}
