import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

/// Service for communicating with Backblaze B2 via Firebase Functions
class BackblazeService {
  // Firebase Functions base URL
  static const String _baseUrl =
      'https://us-central1-pivot-28563.cloudfunctions.net';

  static const String _generateUploadUrlEndpoint =
      '$_baseUrl/generate_upload_url';
  static const String _confirmUploadEndpoint =
      '$_baseUrl/confirm_material_upload';
  static const String _refreshDownloadUrlEndpoint =
      '$_baseUrl/refresh_download_url';
  static const String _deleteFileEndpoint = '$_baseUrl/delete_material_file';

  /// Get current user's Firebase ID token
  Future<String?> _getIdToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      return await user.getIdToken();
    } catch (e) {
      print('Error getting ID token: $e');
      return null;
    }
  }

  /// Generate upload URL for direct file upload to Backblaze
  ///
  /// Returns upload authorization data including:
  /// - uploadUrl: The presigned URL to upload to
  /// - authorizationToken: Token for authorization
  /// - filePath: Path where file will be stored
  /// - fileName: Generated file name
  Future<Map<String, dynamic>?> generateUploadUrl({
    required String title,
    required String fileName,
    required int fileSize,
    String? lectureId,
    String? subjectId,
    String? assistantId,
  }) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse(_generateUploadUrlEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
          'title': title,
          'fileName': fileName,
          'fileSize': fileSize,
          if (lectureId != null) 'lectureId': lectureId,
          if (subjectId != null) 'subjectId': subjectId,
          if (assistantId != null) 'assistantId': assistantId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['error'] ?? 'Failed to generate upload URL');
        }
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Error generating upload URL: $e');
      rethrow;
    }
  }

  /// Upload file directly to Backblaze using presigned URL
  ///
  /// This bypasses Firebase Functions for cost efficiency
  Future<bool> uploadFile({
    required String uploadUrl,
    required String authorizationToken,
    required String fileName,
    required String contentType,
    required List<int> fileBytes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(uploadUrl),
        headers: {
          'Authorization': authorizationToken,
          'X-Bz-File-Name': Uri.encodeComponent(fileName),
          'Content-Type': contentType,
          'X-Bz-Content-Sha1':
              'do_not_verify', // Skip SHA1 verification for speed
        },
        body: fileBytes,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error uploading file: $e');
      return false;
    }
  }

  /// Confirm upload and save metadata to Firestore
  ///
  /// Called after successful upload to Backblaze
  Future<Map<String, dynamic>?> confirmUpload({
    required String title,
    String? description,
    required String filePath,
    required String fileName,
    required int fileSize,
    required String contentType,
    String? lectureId,
    String? subjectId,
    String? assistantId,
  }) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse(_confirmUploadEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
          'title': title,
          'description': description ?? '',
          'filePath': filePath,
          'fileName': fileName,
          'fileSize': fileSize,
          'contentType': contentType,
          if (lectureId != null) 'lectureId': lectureId,
          if (subjectId != null) 'subjectId': subjectId,
          if (assistantId != null) 'assistantId': assistantId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['error'] ?? 'Failed to confirm upload');
        }
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Error confirming upload: $e');
      rethrow;
    }
  }

  /// Refresh download URL for an uploaded file
  ///
  /// Download URLs expire after 24 hours
  Future<String?> refreshDownloadUrl({required String filePath}) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse(_refreshDownloadUrlEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken, 'filePath': filePath}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['downloadUrl'];
        } else {
          throw Exception(data['error'] ?? 'Failed to refresh URL');
        }
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Error refreshing download URL: $e');
      rethrow;
    }
  }

  /// Delete material file from Backblaze and Firestore
  Future<bool> deleteMaterialFile({
    required String filePath,
    required String materialId,
    String? lectureId,
    String? subjectId,
    String? assistantId,
  }) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse(_deleteFileEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
          'filePath': filePath,
          'materialId': materialId,
          if (lectureId != null) 'lectureId': lectureId,
          if (subjectId != null) 'subjectId': subjectId,
          if (assistantId != null) 'assistantId': assistantId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error deleting material file: $e');
      return false;
    }
  }

  /// Get file size in human-readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  /// Check if file type is allowed
  static bool isAllowedFileType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    const allowedExtensions = ['pdf', 'docx', 'pptx', 'jpg', 'jpeg', 'png'];
    return allowedExtensions.contains(extension);
  }

  /// Get content type from file name
  static String getContentType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  /// Maximum file size in bytes (20 MB)
  static const int maxFileSizeBytes = 20 * 1024 * 1024;

  /// Validate file size
  static bool isValidFileSize(int fileSize) {
    return fileSize <= maxFileSizeBytes;
  }
}
