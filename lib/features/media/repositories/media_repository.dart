import 'package:pivot/features/media/services/media_service.dart';
import 'package:pivot/models/material_link.dart';

class MediaRepository {
  final MediaService _mediaService;

  MediaRepository(this._mediaService);

  // Open PDF in browser
  Future<bool> openPdfInBrowser(String url) async {
    return await _mediaService.openPdfInBrowser(url);
  }

  // Open video in browser
  Future<bool> openVideoInBrowser(String url) async {
    return await _mediaService.openVideoInBrowser(url);
  }

  // Open image in browser
  Future<bool> openImageInBrowser(String url) async {
    return await _mediaService.openImageInBrowser(url);
  }

  // Open any material link in browser
  Future<bool> openMaterialInBrowser(MaterialLink materialLink) async {
    return await _mediaService.openMaterialInBrowser(materialLink);
  }

  // Get YouTube video ID from URL
  String? getYouTubeVideoId(String url) {
    return _mediaService.getYouTubeVideoId(url);
  }

  // Get YouTube embed URL
  String? getYouTubeEmbedUrl(String videoId) {
    return _mediaService.getYouTubeEmbedUrl(videoId);
  }

  // Check if URL is a valid video URL
  bool isValidVideoUrl(String url) {
    return _mediaService.isValidVideoUrl(url);
  }

  // Check if URL is a valid PDF URL
  bool isValidPdfUrl(String url) {
    return _mediaService.isValidPdfUrl(url);
  }

  // Check if URL is a valid image URL
  bool isValidImageUrl(String url) {
    return _mediaService.isValidImageUrl(url);
  }

  // Validate material link
  bool validateMaterialLink(MaterialLink materialLink) {
    return _mediaService.validateMaterialLink(materialLink);
  }

  // Get material type from URL
  MaterialType getMaterialTypeFromUrl(String url) {
    return _mediaService.getMaterialTypeFromUrl(url);
  }

  // Get material display title from URL
  String getMaterialDisplayTitleFromUrl(String url) {
    return _mediaService.getMaterialDisplayTitleFromUrl(url);
  }

  // Create MaterialLink from URL
  MaterialLink createMaterialLinkFromUrl(
    String url, {
    String? title,
    String? description,
  }) {
    return _mediaService.createMaterialLinkFromUrl(
      url,
      title: title,
      description: description,
    );
  }

  // Get material metadata
  Future<Map<String, dynamic>> getMaterialMetadata(String url) async {
    return await _mediaService.getMaterialMetadata(url);
  }
}
