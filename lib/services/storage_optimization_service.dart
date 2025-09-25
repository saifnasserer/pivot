import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StorageOptimizationService {
  static final StorageOptimizationService _instance =
      StorageOptimizationService._internal();
  factory StorageOptimizationService() => _instance;
  StorageOptimizationService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Storage analytics
  final Map<String, int> _storageUsage = {};
  final Map<String, List<String>> _fileReferences = {};

  /// Enhanced image compression with multiple quality levels based on usage
  Future<XFile?> compressImageOptimized(
    XFile image, {
    String? usage = 'general', // 'profile', 'announcement', 'task', 'general'
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      // Determine compression settings based on usage
      int quality;
      int width;
      int height;

      switch (usage) {
        case 'profile':
          quality = 70; // Higher quality for profile images
          width = maxWidth ?? 400;
          height = maxHeight ?? 400;
          break;
        case 'announcement':
          quality = 60; // Medium quality for announcements
          width = maxWidth ?? 800;
          height = maxHeight ?? 600;
          break;
        case 'task':
          quality = 50; // Lower quality for task attachments
          width = maxWidth ?? 600;
          height = maxHeight ?? 400;
          break;
        default:
          quality = 60;
          width = maxWidth ?? 600;
          height = maxHeight ?? 600;
      }

      final tempDir = Directory.systemTemp;
      final targetPath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        image.path,
        targetPath,
        quality: quality,
        minWidth: width,
        minHeight: height,
        format: CompressFormat.jpeg,
      );

      if (compressedFile != null) {
        // Calculate file size for analytics
        final file = File(compressedFile.path);
        final size = await file.length();
        _updateStorageUsage('images', size);

        //debugprint('Image compressed: ${size / 1024}KB (${quality}% quality)');
      }

      return compressedFile;
    } catch (e) {
      //debugprint('Error compressing image: $e');
      return null;
    }
  }

  /// Generate file hash for duplicate detection
  Future<String> _generateFileHash(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check for duplicate files before upload
  Future<bool> _isDuplicateFile(String filePath, String storagePath) async {
    try {
      final hash = await _generateFileHash(filePath);

      // Check if hash exists in our tracking
      final hashDoc =
          await _firestore.collection('file_hashes').doc(hash).get();

      if (hashDoc.exists) {
        //debugprint('Duplicate file detected: $filePath');
        return true;
      }

      // Store hash for future reference
      await _firestore.collection('file_hashes').doc(hash).set({
        'path': storagePath,
        'createdAt': FieldValue.serverTimestamp(),
        'fileSize': (await File(filePath).length()).toInt(),
      });

      return false;
    } catch (e) {
      //debugprint('Error checking duplicate: $e');
      return false;
    }
  }

  /// Upload file with duplicate detection and optimization
  Future<String?> uploadFileOptimized(
    XFile file, {
    String? folder = 'general',
    String? usage,
    bool checkDuplicate = true,
  }) async {
    const int maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {

        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
        final storagePath = '${folder ?? 'general'}/$fileName';


        // Check file size
        final fileSize = await File(file.path).length();

        if (fileSize > 10 * 1024 * 1024) {
          // 10MB limit
          throw Exception('File size exceeds 10MB limit');
        }

        // Check for duplicates if enabled - DISABLED due to Firestore permissions
        // if (checkDuplicate && await _isDuplicateFile(file.path, storagePath)) {
        //   debugPrint('Duplicate file detected, returning existing URL');
        //   // Return existing file URL instead of uploading
        //   final hash = await _generateFileHash(file.path);
        //   final hashDoc =
        //       await _firestore.collection('file_hashes').doc(hash).get();
        //   if (hashDoc.exists) {
        //     final data = hashDoc.data();
        //     final existingPath = data?['path'] as String?;
        //     if (existingPath != null) {
        //       final existingRef = _storage.ref().child(existingPath);
        //       return await existingRef.getDownloadURL();
        //     }
        //   }
        // }

        // Compress if it's an image
        XFile fileToUpload = file;
        if (file.path.toLowerCase().contains('.jpg') ||
            file.path.toLowerCase().contains('.jpeg') ||
            file.path.toLowerCase().contains('.png')) {
          final compressed = await compressImageOptimized(file, usage: usage);
          if (compressed != null) {
            fileToUpload = compressed;
            final compressedSize = await File(compressed.path).length();
          } else {
          }
        }

        // Upload to Firebase Storage with timeout
        final storageRef = _storage.ref().child(storagePath);

        // Create upload task with metadata
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploaded_at': DateTime.now().toIso8601String(),
            'usage': usage ?? 'general',
          },
        );

        final uploadTask = storageRef.putFile(
          File(fileToUpload.path),
          metadata,
        );

        // Monitor upload progress
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        });

        // Wait for upload to complete with timeout
        final snapshot = await uploadTask.timeout(
          Duration(seconds: 60),
          onTimeout: () {
            throw Exception('Upload timeout');
          },
        );

        final downloadUrl = await snapshot.ref.getDownloadURL();

        // Track file reference
        _addFileReference(folder ?? 'general', downloadUrl, storagePath);

        // Store file hash for duplicate detection - REMOVED due to Firestore permissions
        // if (checkDuplicate) {
        //   final hash = await _generateFileHash(file.path);
        //   await _firestore.collection('file_hashes').doc(hash).set({
        //     'path': storagePath,
        //     'url': downloadUrl,
        //     'uploaded_at': FieldValue.serverTimestamp(),
        //     'size': fileSize,
        //   });
        // }

        return downloadUrl;
      } catch (e) {
        retryCount++;

        // Check if it's a Firestore permission error (not storage)
        if (e.toString().contains('permission-denied') &&
            e.toString().contains('firestore')) {
          // Continue with retry for storage upload
        } else if (e.toString().contains('unauthorized') ||
            e.toString().contains('permission')) {
          return null; // Don't retry authorization errors
        }

        if (retryCount >= maxRetries) {
          return null;
        }

        // Wait before retrying (exponential backoff)
        final delay = Duration(seconds: retryCount * 2);
        await Future.delayed(delay);
      }
    }

    return null;
  }

  /// Simple fallback upload method for when the main upload fails
  Future<String?> uploadFileSimple(
    XFile file, {
    String? folder = 'general',
  }) async {
    try {

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final storagePath = '${folder ?? 'general'}/$fileName';

      final storageRef = _storage.ref().child(storagePath);
      final uploadTask = storageRef.putFile(File(file.path));

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      return null;
    }
  }

  /// Local storage fallback when Firebase upload fails
  Future<String?> saveImageLocally(XFile file) async {
    try {

      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/profile_images');

      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final localPath = '${imagesDir.path}/$fileName';

      // Copy the file to local storage
      await File(file.path).copy(localPath);

      return localPath;
    } catch (e) {
      return null;
    }
  }

  /// Clean up orphaned files (files in storage but not referenced in Firestore)
  Future<void> cleanupOrphanedFiles() async {
    try {
      //debugprint('Starting orphaned files cleanup...');

      // Get all file references from Firestore
      final Set<String> referencedFiles = {};

      // Check announcements
      final announcements = await _firestore.collection('announcements').get();
      for (var doc in announcements.docs) {
        final data = doc.data();
        final imageUrls = List<String>.from(data['imageUrls'] ?? []);
        referencedFiles.addAll(imageUrls);
      }

      // Check user profiles
      // TODO: The following code fetches the entire users collection and should be moved to a backend/admin function for security and privacy reasons.
      final users = await _firestore.collection('users').get();
      for (var doc in users.docs) {
        final data = doc.data();
        final profileImageUrl = data['profileImageUrl'] as String?;
        if (profileImageUrl != null) {
          referencedFiles.add(profileImageUrl);
        }
      }

      // Check tasks
      final tasks = await _firestore.collection('tasks').get();
      for (var doc in tasks.docs) {
        final data = doc.data();
        final attachments = List<String>.from(data['attachments'] ?? []);
        referencedFiles.addAll(attachments);
      }

      // List all files in storage and check if they're referenced
      await _cleanupStorageFolder('announcements', referencedFiles);
      await _cleanupStorageFolder('profile_images', referencedFiles);
      await _cleanupStorageFolder('tasks', referencedFiles);
      await _cleanupStorageFolder('guides', referencedFiles);
    } catch (e) {
      //debugprint('Error during orphaned files cleanup: $e');
    }
  }

  /// Clean up specific storage folder
  Future<void> _cleanupStorageFolder(
    String folder,
    Set<String> referencedFiles,
  ) async {
    try {
      final folderRef = _storage.ref().child(folder);
      final result = await folderRef.listAll();

      int deletedCount = 0;
      for (var item in result.items) {
        final downloadUrl = await item.getDownloadURL();

        // Check if this file is referenced anywhere
        bool isReferenced = false;
        for (String referencedUrl in referencedFiles) {
          if (referencedUrl.contains(item.name) ||
              referencedUrl == downloadUrl) {
            isReferenced = true;
            break;
          }
        }

        if (!isReferenced) {
          try {
            await item.delete();
            deletedCount++;
            //debugprint('Deleted orphaned file: ${item.fullPath}');
          } catch (e) {
            //debugprint('Error deleting file ${item.fullPath}: $e');
          }
        }
      }

      //debugprint('Cleaned up $deletedCount orphaned files in $folder');
    } catch (e) {
      //debugprint('Error cleaning up folder $folder: $e');
    }
  }

  /// Get storage usage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final stats = <String, dynamic>{};

      // Get file count and size by folder
      final folders = ['announcements', 'profile_images', 'tasks', 'guides'];

      for (String folder in folders) {
        final folderRef = _storage.ref().child(folder);
        final result = await folderRef.listAll();

        int totalSize = 0;
        for (var item in result.items) {
          final metadata = await item.getMetadata();
          totalSize += metadata.size ?? 0;
        }

        stats[folder] = {
          'fileCount': result.items.length,
          'totalSize': totalSize,
          'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
        };
      }

      return stats;
    } catch (e) {
      //debugprint('Error getting storage stats: $e');
      return {};
    }
  }

  /// Update storage usage tracking
  void _updateStorageUsage(String category, int bytes) {
    _storageUsage[category] = (_storageUsage[category] ?? 0) + bytes;
  }

  /// Add file reference for tracking
  void _addFileReference(String category, String url, String storagePath) {
    if (!_fileReferences.containsKey(category)) {
      _fileReferences[category] = [];
    }
    _fileReferences[category]!.add(url);
  }

  /// Delete specific file and clean up references
  Future<bool> deleteFile(String downloadUrl, String category) async {
    try {
      // Extract storage path from URL
      final uri = Uri.parse(downloadUrl);
      final pathSegments = uri.pathSegments;
      final storagePath = pathSegments
          .sublist(pathSegments.length - 2)
          .join('/');

      // Delete from storage
      final storageRef = _storage.ref().child(storagePath);
      await storageRef.delete();

      // Remove from tracking
      _fileReferences[category]?.remove(downloadUrl);

      //debugprint('File deleted successfully: $downloadUrl');
      return true;
    } catch (e) {
      //debugprint('Error deleting file: $e');
      return false;
    }
  }

  /// Batch cleanup operation
  Future<void> performFullCleanup() async {
    try {
      //debugprint('Starting full storage cleanup...');

      // Clean up orphaned files
      await cleanupOrphanedFiles();

      // Get and log storage statistics
      final stats = await getStorageStats();
      //debugprint('Storage cleanup completed. Current stats: $stats');
    } catch (e) {
      //debugprint('Error during full cleanup: $e');
    }
  }

  /// Optimize existing files (recompress if needed)
  Future<void> optimizeExistingFiles() async {
    try {
      //debugprint('Starting file optimization...');

      // This would require downloading, recompressing, and re-uploading files
      // Only implement if absolutely necessary due to cost implications
      //debugprint('File optimization skipped (cost considerations)');
    } catch (e) {
      //debugprint('Error during file optimization: $e');
    }
  }
}
