import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateCheckResult {
  final bool checked;
  final bool updateAvailable;
  final String message;
  final Map<String, dynamic>? manifest;

  const UpdateCheckResult({
    required this.checked,
    required this.updateAvailable,
    required this.message,
    this.manifest,
  });
}

class UpdateService {
  static const String currentVersion = '26.8.6';
  static const String _manifestUrlKey = 'kitty_update_manifest_url';
  static const String _lastSeenVersionKey = 'kitty_update_last_seen_version';
  static const String _pendingUpdateKey = 'kitty_pending_update';

  static const String _builtInManifestUrl = String.fromEnvironment(
    'KITTY_UPDATE_MANIFEST_URL',
    defaultValue: 'https://kitty-adventure-zona.web.app/latest.json',
  );
  static const String publicServerIp = String.fromEnvironment(
    'KITTY_UPDATE_PUBLIC_IP',
    defaultValue: '',
  );

  static Future<String> getManifestUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_manifestUrlKey) ?? _builtInManifestUrl;
  }

  static Future<void> setManifestUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = url.trim();

    if (trimmed.isEmpty) {
      await prefs.remove(_manifestUrlKey);
      return;
    }

    await prefs.setString(_manifestUrlKey, trimmed);
  }

  static Future<String> getGlobalServerAddress() async {
    if (publicServerIp.trim().isNotEmpty) {
      return publicServerIp.trim();
    }

    final manifestUrl = await getManifestUrl();
    final uri = Uri.tryParse(manifestUrl);
    return uri?.host ?? '';
  }

  static Future<UpdateCheckResult> checkForUpdates(
    BuildContext context, {
    bool showNoUpdateSnack = false,
  }) async {
    final manifestUrl = await getManifestUrl();

    if (manifestUrl.trim().isEmpty) {
      final result = const UpdateCheckResult(
        checked: false,
        updateAvailable: false,
        message: 'Add an update manifest URL in Settings first.',
      );
      if (showNoUpdateSnack && context.mounted) {
        _showSnack(context, result.message);
      }
      return result;
    }

    final uri = Uri.tryParse(manifestUrl.trim());
    if (uri == null || !uri.hasScheme) {
      final result = const UpdateCheckResult(
        checked: false,
        updateAvailable: false,
        message: 'Update URL needs to start with http:// or https://.',
      );
      if (showNoUpdateSnack && context.mounted) {
        _showSnack(context, result.message);
      }
      return result;
    }

    try {
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'KittyAdventure/$currentVersion'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        final result = UpdateCheckResult(
          checked: false,
          updateAvailable: false,
          message: 'Update server replied ${response.statusCode}.',
        );
        if (showNoUpdateSnack && context.mounted) {
          _showSnack(context, result.message);
        }
        return result;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        const result = UpdateCheckResult(
          checked: false,
          updateAvailable: false,
          message: 'Update manifest is not a JSON object.',
        );
        if (showNoUpdateSnack && context.mounted) {
          _showSnack(context, result.message);
        }
        return result;
      }

      final latestVersion = decoded['version']?.toString() ?? currentVersion;
      final available = isVersionNewer(latestVersion, currentVersion);

      if (available) {
        if (context.mounted) {
          await _showUpdateDialog(context, decoded);
        }

        return UpdateCheckResult(
          checked: true,
          updateAvailable: true,
          message: 'Update $latestVersion is available.',
          manifest: decoded,
        );
      }

      final result = UpdateCheckResult(
        checked: true,
        updateAvailable: false,
        message: 'You are up to date on v$currentVersion.',
        manifest: decoded,
      );
      if (showNoUpdateSnack && context.mounted) {
        _showSnack(context, result.message);
      }
      return result;
    } catch (error) {
      final result = UpdateCheckResult(
        checked: false,
        updateAvailable: false,
        message: 'Update server is not reachable right now.',
      );
      if (showNoUpdateSnack && context.mounted) {
        _showSnack(context, result.message);
      }
      return result;
    }
  }

  static bool isVersionNewer(String latest, String current) {
    final latestParts = _versionParts(latest);
    final currentParts = _versionParts(current);
    final length = latestParts.length > currentParts.length
        ? latestParts.length
        : currentParts.length;

    for (var i = 0; i < length; i++) {
      final latestPart = i < latestParts.length ? latestParts[i] : 0;
      final currentPart = i < currentParts.length ? currentParts[i] : 0;

      if (latestPart > currentPart) return true;
      if (latestPart < currentPart) return false;
    }

    return false;
  }

  static List<int> _versionParts(String version) {
    final clean = version
        .trim()
        .toLowerCase()
        .replaceFirst(RegExp(r'^v'), '')
        .split('+')
        .first
        .split('-')
        .first;

    return clean.split('.').map((part) {
      final match = RegExp(r'\d+').firstMatch(part);
      return int.tryParse(match?.group(0) ?? '0') ?? 0;
    }).toList();
  }

  static Future<void> _showUpdateDialog(
    BuildContext context,
    Map<String, dynamic> manifest,
  ) async {
    final required = manifest['required'] == true;
    final latestVersion = manifest['version']?.toString() ?? 'Unknown';
    final changelog = _changelogLines(manifest['changelog']);
    final downloadUrl = _downloadUrlForCurrentPlatform(manifest);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSeenVersionKey, latestVersion);
    await prefs.setString(_pendingUpdateKey, jsonEncode(manifest));

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: !required,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.system_update_alt, color: Color(0xFFFF76B7)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Update Available',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kitty Adventure v$latestVersion is ready.'),
              const SizedBox(height: 8),
              if (manifest['release_date'] != null)
                Text('Release date: ${manifest['release_date']}'),
              if (manifest['size'] != null) Text('Size: ${manifest['size']}'),
              const SizedBox(height: 12),
              const Text(
                "What's new:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              ...changelog.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('- $line'),
                ),
              ),
              if (required) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: const Text(
                    'This update is required before continuing.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (!required)
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Later'),
            ),
          ElevatedButton.icon(
            onPressed: downloadUrl == null
                ? null
                : () async {
                    await launchUrl(
                      Uri.parse(downloadUrl),
                      mode: LaunchMode.externalApplication,
                    );
                  },
            icon: const Icon(Icons.download),
            label: const Text('Download'),
          ),
        ],
      ),
    );
  }

  static List<String> _changelogLines(Object? changelog) {
    if (changelog is List) {
      return changelog.map((item) => item.toString()).toList();
    }

    if (changelog is String && changelog.trim().isNotEmpty) {
      return changelog
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
    }

    return const ['Bug fixes and polish.'];
  }

  static String? _downloadUrlForCurrentPlatform(Map<String, dynamic> manifest) {
    if (kIsWeb) {
      return _firstUrl(manifest, ['web_url', 'download_url']);
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _firstUrl(manifest, ['apk_url', 'download_url']);
      case TargetPlatform.iOS:
        return _firstUrl(manifest, ['ipa_url', 'download_url']);
      case TargetPlatform.macOS:
        return _firstUrl(manifest, ['macos_url', 'download_url']);
      case TargetPlatform.windows:
        return _firstUrl(manifest, ['windows_url', 'download_url']);
      case TargetPlatform.linux:
        return _firstUrl(manifest, ['linux_url', 'download_url']);
      case TargetPlatform.fuchsia:
        return _firstUrl(manifest, ['download_url']);
    }
  }

  static String? _firstUrl(Map<String, dynamic> manifest, List<String> keys) {
    for (final key in keys) {
      final value = manifest[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
