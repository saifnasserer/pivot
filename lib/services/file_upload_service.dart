import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:pivot/services/backblaze_service.dart';

/// Service for handling file upload workflow
class FileUploadService {
  final BackblazeService _backblazeService = BackblazeService();

  /// Pick a file from device
  ///
  /// Returns file info or null if cancelled
  Future<PickedFileInfo?> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Allow all file types
        withData: true, // Get file bytes
      );

      if (result == null || result.files.isEmpty) {
        return null; // User cancelled
      }

      final file = result.files.first;

      // Validate file
      if (file.name.isEmpty) {
        throw Exception('اسم الملف غير صالح');
      }

      if (file.size <= 0) {
        throw Exception('حجم الملف غير صالح');
      }

      if (!BackblazeService.isValidFileSize(file.size)) {
        throw Exception('حجم الملف كبير جداً. الحد الأقصى 20 ميجابايت');
      }

      // File type validation removed - allow all file types
      // if (!BackblazeService.isAllowedFileType(file.name)) {
      //   throw Exception(
      //     'نوع الملف غير مدعوم. الأنواع المدعومة: PDF, DOCX, PPTX, JPG, PNG',
      //   );
      // }

      // Get file bytes
      List<int>? bytes;
      if (file.bytes != null) {
        bytes = file.bytes!;
      } else if (file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      } else {
        throw Exception('لا يمكن قراءة الملف');
      }

      return PickedFileInfo(
        name: file.name,
        size: file.size,
        bytes: bytes,
        extension: file.extension ?? '',
      );
    } catch (e) {
      print('Error picking file: $e');
      rethrow;
    }
  }

  /// Upload file to Backblaze with progress callback
  ///
  /// Returns material info if successful
  Future<UploadResult> uploadFile({
    required PickedFileInfo fileInfo,
    required String title,
    String? description,
    String? lectureId,
    String? subjectId,
    String? assistantId,
    Function(UploadProgress)? onProgress,
  }) async {
    try {
      // Step 1: Generate upload URL
      onProgress?.call(
        UploadProgress(
          stage: UploadStage.generatingUrl,
          progress: 0.1,
          message: 'جاري التحضير...',
        ),
      );

      final uploadAuth = await _backblazeService.generateUploadUrl(
        title: title,
        fileName: fileInfo.name,
        fileSize: fileInfo.size,
        lectureId: lectureId,
        subjectId: subjectId,
        assistantId: assistantId,
      );

      if (uploadAuth == null) {
        throw Exception('فشل في الحصول على رابط التحميل');
      }

      // Step 2: Upload file to Backblaze
      onProgress?.call(
        UploadProgress(
          stage: UploadStage.uploading,
          progress: 0.5,
          message: 'جاري رفع الملف...',
        ),
      );

      final uploadSuccess = await _backblazeService.uploadFile(
        uploadUrl: uploadAuth['uploadUrl'],
        authorizationToken: uploadAuth['authorizationToken'],
        fileName: uploadAuth['filePath'],
        contentType: BackblazeService.getContentType(fileInfo.name),
        fileBytes: fileInfo.bytes,
      );

      if (!uploadSuccess) {
        throw Exception('فشل في رفع الملف');
      }

      // Step 3: Confirm upload and save metadata
      onProgress?.call(
        UploadProgress(
          stage: UploadStage.confirming,
          progress: 0.9,
          message: 'جاري الحفظ...',
        ),
      );

      final confirmResult = await _backblazeService.confirmUpload(
        title: title,
        description: description,
        filePath: uploadAuth['filePath'],
        fileName: uploadAuth['fileName'],
        fileSize: fileInfo.size,
        contentType: BackblazeService.getContentType(fileInfo.name),
        lectureId: lectureId,
        subjectId: subjectId,
        assistantId: assistantId,
      );

      if (confirmResult == null) {
        throw Exception('فشل في حفظ بيانات الملف');
      }

      // Step 4: Complete
      onProgress?.call(
        UploadProgress(
          stage: UploadStage.complete,
          progress: 1.0,
          message: 'تم الرفع بنجاح',
        ),
      );

      return UploadResult(
        success: true,
        materialId: confirmResult['materialId'],
        downloadUrl: confirmResult['downloadUrl'],
        filePath: uploadAuth['filePath'],
        fileName: uploadAuth['fileName'],
      );
    } catch (e) {
      print('Error uploading file: $e');

      onProgress?.call(
        UploadProgress(
          stage: UploadStage.error,
          progress: 0.0,
          message: 'فشل الرفع: ${e.toString()}',
        ),
      );

      return UploadResult(success: false, error: e.toString());
    }
  }
}

/// Information about picked file
class PickedFileInfo {
  final String name;
  final int size;
  final List<int> bytes;
  final String extension;

  PickedFileInfo({
    required this.name,
    required this.size,
    required this.bytes,
    required this.extension,
  });

  String get formattedSize => BackblazeService.formatFileSize(size);
}

/// Upload progress information
class UploadProgress {
  final UploadStage stage;
  final double progress; // 0.0 to 1.0
  final String message;

  UploadProgress({
    required this.stage,
    required this.progress,
    required this.message,
  });
}

/// Stages of upload process
enum UploadStage { generatingUrl, uploading, confirming, complete, error }

/// Result of upload operation
class UploadResult {
  final bool success;
  final String? materialId;
  final String? downloadUrl;
  final String? filePath;
  final String? fileName;
  final String? error;

  UploadResult({
    required this.success,
    this.materialId,
    this.downloadUrl,
    this.filePath,
    this.fileName,
    this.error,
  });
}
