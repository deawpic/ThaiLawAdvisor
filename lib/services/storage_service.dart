import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  static const _secureStorage = FlutterSecureStorage();
  
  static const String _keyApiKey = 'thailaw_gemini_api_key';
  static const String _keySelectedModel = 'thailaw_selected_model';

  // API Key Management (Secure)
  static Future<void> saveApiKey(String key) async {
    try {
      await _secureStorage.write(key: _keyApiKey, value: key);
    } catch (e) {
      debugPrint('Error writing API Key: $e');
      try {
        await _secureStorage.delete(key: _keyApiKey);
        await _secureStorage.write(key: _keyApiKey, value: key);
      } catch (innerEx) {
        debugPrint('Failed writing API Key again: $innerEx');
      }
    }
  }

  static Future<String?> getApiKey() async {
    try {
      return await _secureStorage.read(key: _keyApiKey);
    } catch (e) {
      debugPrint('Error reading API Key: $e');
      try {
        await _secureStorage.delete(key: _keyApiKey);
      } catch (_) {}
      return null;
    }
  }

  static Future<void> deleteApiKey() async {
    try {
      await _secureStorage.delete(key: _keyApiKey);
    } catch (e) {
      debugPrint('Error deleting API Key: $e');
    }
  }

  // Selected Model Management (Preferences)
  static Future<void> saveSelectedModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedModel, model);
  }

  static Future<String> getSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySelectedModel) ?? 'gemini-3.5-flash';
  }
}
