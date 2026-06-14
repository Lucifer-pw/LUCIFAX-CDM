import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucifax_cdm/core/platform/native_bridge.dart';
import 'package:lucifax_cdm/core/constants/app_colors.dart';
import 'package:lucifax_cdm/core/constants/app_strings.dart';

class GithubService {
  static const String _owner = 'Lucifer-pw';
  static const String _repo = 'LUCIFAX-CDM';

  static Future<Map<String, dynamic>?> checkUpdates() async {
    try {
      final url = Uri.parse('https://api.github.com/repos/$_owner/$_repo/releases/latest');
      final response = await http.get(url, headers: {
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'Lucifax-CDM-App',
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
      } else {
        debugPrint('Github API check update failed: Status ${response.statusCode}');
        debugPrint('Response: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error checking github update: $e');
    }
    return {'hasUpdate': false};
  }

  static Future<void> checkAndShowUpdateDialog(BuildContext context) async {
    final updateInfo = await checkUpdates();
    if (updateInfo != null && updateInfo['hasUpdate'] == true && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.glassBorder),
          ),
          title: Row(
            children: [
              Icon(Icons.system_update, color: AppColors.primaryAccent),
              const SizedBox(width: 8),
              const Text(AppStrings.updateAvailableTitle),
            ],
          ),
          content: Text(
            AppStrings.updateAvailableDesc.replaceFirst('{version}', updateInfo['latestVersion']) +
            '\n\nCatatan Rilis:\n${updateInfo['releaseNotes']}'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppStrings.updateLaterBtn, style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (updateInfo['downloadUrl'] != null) {
                  _startDownloadFlow(context, updateInfo['downloadUrl']);
                } else {
                  launchUrlString(updateInfo['htmlUrl'] ?? '');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text(AppStrings.updateDownloadBtn),
            ),
          ],
        ),
      );
    }
  }

  static void _startDownloadFlow(BuildContext context, String url) {
    double progress = 0.0;
    bool downloadStarted = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          if (!downloadStarted) {
            downloadStarted = true;
            downloadAndInstallApk(
              url,
              (p) {
                if (context.mounted) {
                  setState(() {
                    progress = p;
                  });
                }
              },
              (err) {
                if (context.mounted) {
                  Navigator.pop(context);
                  if (err != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(err),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  }
                }
              },
            );
          }

          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.glassBorder),
            ),
            title: const Text('Mengunduh Pembaruan'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: progress,
                  color: AppColors.primaryAccent,
                  backgroundColor: AppColors.glassBackground,
                ),
                const SizedBox(height: 16),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% terunduh...',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        },
      ),
    );
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
