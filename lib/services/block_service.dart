import 'package:flutter/material.dart';

/// Hook for the native side (VpnService). Implement with a MethodChannel.
class BlockService {
  static Future<void> setBlocked(String app, bool blocked) async {}
  static Future<void> setMaster(bool on) async {}
  static Future<void> schedule(TimeOfDay start, TimeOfDay end, List<bool> days) async {}
}
