import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucifax_cdm/core/platform/native_bridge.dart';

class GithubService {
  static const String _owner = 'Lucifer-pw';
  static const String _repo = 'LUCIFAX-CDM';

  static Future<Map<String, dynamic>?> checkUpdates() async {
    try {
      final url = Uri.parse('https://api.github.com/repos/$_owner/$_repo/releases/latest');
      final response = await http.get(url, headers: {
        'Accept': 'application/vnd.github.v3+json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestTagName = data['tag_name'] as String; // e.g. "v1.0.1" or "1.0.1"
        final latestVersion = latestTagName.replaceAll(RegExp(r'[^0-9\.]'), '');
        
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        if (_isNewer(latestVersion, currentVersion)) {
          return {
            'hasUpdate': true,
            'latestVersion': latestTagName,
            'currentVersion': currentVersion,
            'releaseNotes': data['body'] ?? 'Tidak ada catatan rilis.',
            'htmlUrl': data['html_url'],
            'downloadUrl': data['assets'] != null && (data['assets'] as List).isNotEmpty
                ? data['assets'][0]['browser_download_url']
                : null,
          };
        }
      }
    } catch (e) {
      debugPrint('Error checking github update: $e');
    }
    return {'hasUpdate': false};
  }

  static bool _isNewer(String latest, String current) {
    List<int> latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < latestParts.length; i++) {
      if (i >= currentParts.length) return true;
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  static Future<void> launchUrlString(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Downloads release APK and triggers the native package installer
  static Future<void> downloadAndInstallApk(
    String downloadUrl,
    Function(double progress) onProgress,
    Function(String? error) onComplete,
  ) async {
    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        onComplete('Gagal mengunduh file: HTTP ${response.statusCode}');
        return;
      }

      final contentLength = response.contentLength ?? 0;
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/lucifax_update.apk';
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
      }

      final fileSink = file.openWrite();
      var bytesDownloaded = 0;

      await response.stream.listen(
        (chunk) {
          fileSink.add(chunk);
          bytesDownloaded += chunk.length;
          if (contentLength > 0) {
            onProgress(bytesDownloaded / contentLength);
          }
        },
        onError: (e) {
          fileSink.close();
          onComplete('Gagal mengunduh file: $e');
        },
        cancelOnError: true,
      ).asFuture();

      await fileSink.close();
      client.close();

      // Trigger automatic native installation
      final success = await NativeBridge.installApk(filePath);
      if (success) {
        onComplete(null);
      } else {
        onComplete('Gagal memasang APK secara otomatis. Harap install secara manual.');
      }
    } catch (e) {
      onComplete('Kesalahan pengunduhan: $e');
    }
  }
}
