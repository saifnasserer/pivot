import 'package:url_launcher/url_launcher.dart';
import 'package:pivot/models/material_link.dart';

class MediaService {
  // Open PDF in browser
  Future<bool> openPdfInBrowser(String url) async {
    try {
      final Uri? uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Open video in browser
  Future<bool> openVideoInBrowser(String url) async {
    try {
      final Uri? uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Open image in browser
  Future<bool> openImageInBrowser(String url) async {
    try {
      final Uri? uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Open any material link in browser
  Future<bool> openMaterialInBrowser(MaterialLink materialLink) async {
    try {
      final Uri? uri = Uri.tryParse(materialLink.url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Get YouTube video ID from URL
  String? getYouTubeVideoId(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host.contains('youtube.com') || uri.host.contains('youtu.be')) {
        if (uri.host.contains('youtu.be')) {
          return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
        } else {
          return uri.queryParameters['v'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get YouTube embed URL
  String? getYouTubeEmbedUrl(String videoId) {
    if (videoId.isEmpty) return null;
    return 'https://www.youtube.com/embed/$videoId?autoplay=1&rel=0';
  }

  // Check if URL is a valid video URL
  bool isValidVideoUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.contains('youtube.com') ||
          uri.host.contains('youtu.be') ||
          uri.host.contains('vimeo.com') ||
          url.endsWith('.mp4') ||
          url.endsWith('.webm') ||
          url.endsWith('.mov');
    } catch (e) {
      return false;
    }
  }

  // Check if URL is a valid PDF URL
  bool isValidPdfUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return url.endsWith('.pdf') ||
          uri.host.contains('drive.google.com') ||
          uri.host.contains('dropbox.com') ||
          uri.host.contains('onedrive.live.com');
    } catch (e) {
      return false;
    }
  }

  // Check if URL is a valid image URL
  bool isValidImageUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return url.endsWith('.jpg') ||
          url.endsWith('.jpeg') ||
          url.endsWith('.png') ||
          url.endsWith('.gif') ||
          url.endsWith('.webp') ||
          uri.host.contains('imgur.com') ||
          uri.host.contains('flickr.com');
    } catch (e) {
      return false;
    }
  }

  // Validate material link
  bool validateMaterialLink(MaterialLink materialLink) {
    switch (materialLink.type) {
      case MaterialType.video:
        return isValidVideoUrl(materialLink.url);
      case MaterialType.pdf:
        return isValidPdfUrl(materialLink.url);
      case MaterialType.image:
        return isValidImageUrl(materialLink.url);
      case MaterialType.link:
        return Uri.tryParse(materialLink.url) != null;
      default:
        return false;
    }
  }

  // Get material type from URL
  MaterialType getMaterialTypeFromUrl(String url) {
    if (isValidVideoUrl(url)) {
      return MaterialType.video;
    } else if (isValidPdfUrl(url)) {
      return MaterialType.pdf;
    } else if (isValidImageUrl(url)) {
      return MaterialType.image;
    } else {
      return MaterialType.link;
    }
  }

  // Get material display title from URL
  String getMaterialDisplayTitleFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      if (pathSegments.isNotEmpty) {
        final lastSegment = pathSegments.last;
        if (lastSegment.contains('.')) {
          // Remove file extension
          return lastSegment.split('.').first;
        }
        return lastSegment;
      }

      return uri.host;
    } catch (e) {
      return 'Material';
    }
  }

  // Create MaterialLink from URL
  MaterialLink createMaterialLinkFromUrl(
    String url, {
    String? title,
    String? description,
  }) {
    final type = getMaterialTypeFromUrl(url);
    final displayTitle = title ?? getMaterialDisplayTitleFromUrl(url);

    return MaterialLink(
      title: displayTitle,
      url: url,
      type: type,
      description: description,
    );
  }

  // Get material metadata
  Future<Map<String, dynamic>> getMaterialMetadata(String url) async {
    try {
      final type = getMaterialTypeFromUrl(url);
      final displayTitle = getMaterialDisplayTitleFromUrl(url);

      Map<String, dynamic> metadata = {
        'type': type.toString(),
        'displayTitle': displayTitle,
        'url': url,
        'isValid': validateMaterialLink(createMaterialLinkFromUrl(url)),
      };

      if (type == MaterialType.video) {
        final videoId = getYouTubeVideoId(url);
        if (videoId != null && videoId.isNotEmpty) {
          metadata['videoId'] = videoId;
          metadata['embedUrl'] = getYouTubeEmbedUrl(videoId);
        }
      }

      return metadata;
    } catch (e) {
      return {
        'type': MaterialType.link.toString(),
        'displayTitle': 'Unknown Material',
        'url': url,
        'isValid': false,
        'error': e.toString(),
      };
    }
  }
}
