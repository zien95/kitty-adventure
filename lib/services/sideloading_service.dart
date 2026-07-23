import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SideloadingService {
  static const String _serverUrl = 'https://your-server.com/api';
  static const String _currentVersion = '26.8.6';

  // Check for updates
  static Future<bool> checkForUpdates(BuildContext context) async {
    try {
      final response = await http.get(
        Uri.parse('$_serverUrl/version.json'),
        headers: {'User-Agent': 'KittyAdventure/$_currentVersion'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersion = data['version'] ?? _currentVersion;
        final currentVersion = _currentVersion; // Use current version constant

        if (_isVersionNewer(latestVersion, currentVersion)) {
          _showUpdateDialog(context, data);
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  // Show update dialog
  static void _showUpdateDialog(
      BuildContext context, Map<String, dynamic> updateData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.system_update, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('🍎 Update Available',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Version ${updateData['version']} is now available!'),
              const SizedBox(height: 8),
              Text('📋 What\'s New:'),
              Text(updateData['changelog'] ??
                  'Bug fixes and performance improvements'),
              const SizedBox(height: 8),
              if (updateData['required'] == true)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(
                              'This update is required for continued use.')),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Text('📦 File Size: ${updateData['size'] ?? 'Unknown'}'),
              Text(
                  '📅 Release Date: ${updateData['release_date'] ?? 'Unknown'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _downloadUpdate(updateData),
            child: const Text('📥 Download Update'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('⏰ Remind Later'),
          ),
        ],
      ),
    );
  }

  // Download update
  static Future<void> _downloadUpdate(Map<String, dynamic> updateData) async {
    try {
      final ipaUrl = updateData['ipa_url'];
      if (ipaUrl != null) {
        // Save update info for later
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pending_update', jsonEncode(updateData));
      }
    } catch (_) {}
  }

  // Check if version is newer
  static bool _isVersionNewer(String latest, String current) {
    final latestParts = latest.split('.').map(int.parse).toList();
    final currentParts = current.split('.').map(int.parse).toList();

    for (int i = 0; i < latestParts.length && i < currentParts.length; i++) {
      if (latestParts[i] > currentParts[i]) {
        return true;
      } else if (latestParts[i] < currentParts[i]) {
        return false;
      }
    }
    return false;
  }

  // Get installation source
  static Future<String> getInstallationSource() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('install_source') ?? 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  // Track installation for analytics
  static Future<void> trackInstallation() async {
    try {
      final deviceId = await _getDeviceId();

      final analyticsData = {
        'app_name': 'KittyAdventure',
        'version': _currentVersion,
        'build': '26.8.6',
        'platform': Platform.operatingSystem,
        'device_id': deviceId,
        'install_source': await getInstallationSource(),
        'timestamp': DateTime.now().toIso8601String(),
        'flutter_version': '3.10.0', // Default Flutter version
        'sideload_method': await _getSideloadMethod(),
      };

      await http
          .post(
            Uri.parse('$_serverUrl/analytics'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(analyticsData),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  // Get unique device ID
  static Future<String> _getDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString('device_id');

      if (deviceId == null) {
        deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString('device_id', deviceId);
      }

      return deviceId;
    } catch (e) {
      return 'unknown_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // Detect sideload method
  static Future<String> _getSideloadMethod() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('sideload_method') ?? 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  // Check if app is sideloaded
  static Future<bool> isSideloaded() async {
    try {
      // Check installation source
      final installSource = await getInstallationSource();
      if (installSource != 'app_store') {
        return true;
      }

      return false;
    } catch (e) {
      return true; // Assume sideloaded if we can't determine
    }
  }

  // Show sideload warning
  static void showSideloadWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('⚠️ Sideloaded App',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This app was installed outside the App Store.'),
            SizedBox(height: 8),
            Text('🔒 Security considerations:'),
            Text('• This version has not been reviewed by an app store'),
            Text('• Updates may require manual installation'),
            Text('• Some features may be limited'),
            SizedBox(height: 8),
            Text('✅ Benefits:'),
            Text('• Early access to new features'),
            Text('• No App Store restrictions'),
            Text('• Direct developer updates'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }
}
