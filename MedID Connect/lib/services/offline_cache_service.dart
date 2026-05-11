import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class OfflineCacheService {
  static const _walletKey = 'offline_wallet_summary';
  static const _wellnessKey = 'offline_wellness_logs';

  Future<void> saveWallet(Map<String, dynamic> wallet) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_walletKey, jsonEncode(wallet));
  }

  Future<Map<String, dynamic>?> readWallet() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_walletKey);
    if (value == null) return null;
    return Map<String, dynamic>.from(jsonDecode(value) as Map);
  }

  Future<void> addWellnessLog(Map<String, dynamic> log) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await readWellnessLogs();
    items.insert(0, log);
    await prefs.setString(_wellnessKey, jsonEncode(items.take(30).toList()));
  }

  Future<List<Map<String, dynamic>>> readWellnessLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_wellnessKey);
    if (value == null) return [];
    return (jsonDecode(value) as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }
}
