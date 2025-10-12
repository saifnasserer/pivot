import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:open_file/open_file.dart';

/// Service for downloading and caching files from Backblaze
/// Similar to WhatsApp's file handling
class FileDownloadService {
  static const String _basePath = 'pivot_materials';

  /// Get Firebase ID token for authentication
  Future<String?> _getIdToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      return await user.getIdToken();
    } catch (e) {
      debugPrint('Error getting ID token: $e');
      return null;
    }
  }

  /// Get local storage directory for downloaded files
  Future<Directory> _getDownloadDirectory() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory downloadDir = Directory('${appDocDir.path}/$_basePath');

    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }

    return downloadDir;
  }

  /// Generate local file path from Backblaze file path
  Future<String> _getLocalFilePath(String backblazeFilePath) async {
    final dir = await _getDownloadDirectory();
    // Replace slashes with underscores to create a flat structure
    final sanitizedPath = backblazeFilePath.replaceAll('/', '_');
    return '${dir.path}/$sanitizedPath';
  }

  /// Check if file exists locally
  Future<bool> isFileDownloaded(String backblazeFilePath) async {
    try {
      final localPath = await _getLocalFilePath(backblazeFilePath);
      final file = File(localPath);
      return await file.exists();
    } catch (e) {
      debugPrint('Error checking file existence: $e');
      return false;
    }
  }

  /// Get local file path if exists, null otherwise
  Future<String?> getLocalFilePath(String backblazeFilePath) async {
    final localPath = await _getLocalFilePath(backblazeFilePath);
    final file = File(localPath);
    if (await file.exists()) {
      return localPath;
    }
    return null;
  }

  /// Download file from Backblaze with authentication
  ///
  /// This function fetches the file using Backblaze credentials
  /// and saves it locally for offline access
  Future<DownloadResult> downloadFile({
    required String backblazeFilePath,
    required String downloadUrl,
    Function(double)? onProgress,
  }) async {
    try {
      // Note: No storage permission needed for app-specific storage
      // (getApplicationDocumentsDirectory doesn't require permissions)

      final localPath = await _getLocalFilePath(backblazeFilePath);
      final file = File(localPath);

      // If file already exists, return success
      if (await file.exists()) {
        return DownloadResult(success: true, localPath: localPath);
      }

      // Get auth token
      final idToken = await _getIdToken();
      if (idToken == null) {
        return DownloadResult(success: false, error: 'User not authenticated');
      }

      // Make authenticated request to download file
      // For now, download directly from URL (works if bucket becomes public)
      // TODO: For private buckets, route through Firebase Function proxy
      final response = await http.get(
        Uri.parse(downloadUrl),
        headers: {
          // Add authorization if needed
          'User-Agent': 'PivotApp/1.0',
        },
      );

      if (response.statusCode == 200) {
        // Save file locally
        await file.writeAsBytes(response.bodyBytes);

        debugPrint('File downloaded successfully: $localPath');

        return DownloadResult(success: true, localPath: localPath);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Unauthorized - need to use proxy
        return await _downloadViaProxy(
          backblazeFilePath: backblazeFilePath,
          localPath: localPath,
          idToken: idToken,
          onProgress: onProgress,
        );
      } else {
        return DownloadResult(
          success: false,
          error: 'Failed to download: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error downloading file: $e');
      return DownloadResult(success: false, error: e.toString());
    }
  }

  /// Download file via Firebase Functions proxy (for private buckets)
  Future<DownloadResult> _downloadViaProxy({
    required String backblazeFilePath,
    required String localPath,
    required String idToken,
    Function(double)? onProgress,
  }) async {
    try {
      // Call Firebase Function to download file with server-side auth
      const proxyUrl =
          'https://us-central1-pivot-28563.cloudfunctions.net/download_material_file';

      final response = await http.post(
        Uri.parse(proxyUrl),
        headers: {'Content-Type': 'application/json'},
        body: '{"idToken": "$idToken", "filePath": "$backblazeFilePath"}',
      );

      if (response.statusCode == 200) {
        // Save file locally
        final file = File(localPath);
        await file.writeAsBytes(response.bodyBytes);

        return DownloadResult(success: true, localPath: localPath);
      } else {
        return DownloadResult(
          success: false,
          error: 'Proxy download failed: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      return DownloadResult(success: false, error: 'Proxy download error: $e');
    }
  }

  /// Open file from local storage
  Future<void> openFile(String localPath) async {
    try {
      final result = await OpenFile.open(localPath);

      if (result.type != ResultType.done) {
        debugPrint('Failed to open file: ${result.message}');
      }
    } catch (e) {
      debugPrint('Error opening file: $e');
      rethrow;
    }
  }

  /// Download and open file
  ///
  /// If file exists locally, opens it directly
  /// Otherwise, downloads first then opens
  Future<DownloadResult> downloadAndOpen({
    required String backblazeFilePath,
    required String downloadUrl,
    Function(double)? onProgress,
  }) async {
    try {
      // Check if file exists locally
      final localPath = await getLocalFilePath(backblazeFilePath);

      if (localPath != null) {
        // File exists, open it
        await openFile(localPath);
        return DownloadResult(success: true, localPath: localPath);
      }

      // File doesn't exist, download it
      final downloadResult = await downloadFile(
        backblazeFilePath: backblazeFilePath,
        downloadUrl: downloadUrl,
        onProgress: onProgress,
      );

      if (downloadResult.success && downloadResult.localPath != null) {
        // Open downloaded file
        await openFile(downloadResult.localPath!);
      }

      return downloadResult;
    } catch (e) {
      return DownloadResult(success: false, error: e.toString());
    }
  }

  /// Delete local file
  Future<bool> deleteLocalFile(String backblazeFilePath) async {
    try {
      final localPath = await _getLocalFilePath(backblazeFilePath);
      final file = File(localPath);

      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }

  /// Get file size
  Future<int?> getLocalFileSize(String backblazeFilePath) async {
    try {
      final localPath = await _getLocalFilePath(backblazeFilePath);
      final file = File(localPath);

      if (await file.exists()) {
        return await file.length();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting file size: $e');
      return null;
    }
  }

  /// Clear all downloaded files (cache cleanup)
  Future<void> clearAllDownloads() async {
    try {
      final dir = await _getDownloadDirectory();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create(recursive: true);
      }
    } catch (e) {
      debugPrint('Error clearing downloads: $e');
    }
  }

  /// Get total size of all downloaded files
  Future<int> getTotalDownloadedSize() async {
    try {
      final dir = await _getDownloadDirectory();
      if (!await dir.exists()) return 0;

      int totalSize = 0;
      final files = dir.listSync(recursive: true);

      for (var entity in files) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('Error calculating total size: $e');
      return 0;
    }
  }
}

/// Result of download operation
class DownloadResult {
  final bool success;
  final String? localPath;
  final String? error;

  DownloadResult({required this.success, this.localPath, this.error});
}
