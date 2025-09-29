import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/media/services/media_service.dart';
import 'package:pivot/features/media/repositories/media_repository.dart';
import 'package:pivot/models/material_link.dart';

// Services
final mediaServiceProvider = Provider<MediaService>((ref) {
  return MediaService();
});

// Repositories
final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  final service = ref.watch(mediaServiceProvider);
  return MediaRepository(service);
});

// State classes
class MediaState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? materialMetadata;
  final bool isOpeningInBrowser;

  const MediaState({
    this.isLoading = false,
    this.error,
    this.materialMetadata,
    this.isOpeningInBrowser = false,
  });

  MediaState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? materialMetadata,
    bool? isOpeningInBrowser,
  }) {
    return MediaState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      materialMetadata: materialMetadata ?? this.materialMetadata,
      isOpeningInBrowser: isOpeningInBrowser ?? this.isOpeningInBrowser,
    );
  }
}

// Notifier
class MediaNotifier extends StateNotifier<MediaState> {
  final MediaRepository _repository;

  MediaNotifier(this._repository) : super(const MediaState());

  // Open PDF in browser
  Future<bool> openPdfInBrowser(String url) async {
    state = state.copyWith(isOpeningInBrowser: true, error: null);
    try {
      final success = await _repository.openPdfInBrowser(url);
      state = state.copyWith(isOpeningInBrowser: false);
      return success;
    } catch (e) {
      state = state.copyWith(isOpeningInBrowser: false, error: e.toString());
      return false;
    }
  }

  // Open video in browser
  Future<bool> openVideoInBrowser(String url) async {
    state = state.copyWith(isOpeningInBrowser: true, error: null);
    try {
      final success = await _repository.openVideoInBrowser(url);
      state = state.copyWith(isOpeningInBrowser: false);
      return success;
    } catch (e) {
      state = state.copyWith(isOpeningInBrowser: false, error: e.toString());
      return false;
    }
  }

  // Open image in browser
  Future<bool> openImageInBrowser(String url) async {
    state = state.copyWith(isOpeningInBrowser: true, error: null);
    try {
      final success = await _repository.openImageInBrowser(url);
      state = state.copyWith(isOpeningInBrowser: false);
      return success;
    } catch (e) {
      state = state.copyWith(isOpeningInBrowser: false, error: e.toString());
      return false;
    }
  }

  // Open any material link in browser
  Future<bool> openMaterialInBrowser(MaterialLink materialLink) async {
    state = state.copyWith(isOpeningInBrowser: true, error: null);
    try {
      final success = await _repository.openMaterialInBrowser(materialLink);
      state = state.copyWith(isOpeningInBrowser: false);
      return success;
    } catch (e) {
      state = state.copyWith(isOpeningInBrowser: false, error: e.toString());
      return false;
    }
  }

  // Get material metadata
  Future<void> getMaterialMetadata(String url) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final metadata = await _repository.getMaterialMetadata(url);
      state = state.copyWith(isLoading: false, materialMetadata: metadata);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get YouTube video ID from URL
  String? getYouTubeVideoId(String url) {
    return _repository.getYouTubeVideoId(url);
  }

  // Get YouTube embed URL
  String? getYouTubeEmbedUrl(String videoId) {
    return _repository.getYouTubeEmbedUrl(videoId);
  }

  // Check if URL is a valid video URL
  bool isValidVideoUrl(String url) {
    return _repository.isValidVideoUrl(url);
  }

  // Check if URL is a valid PDF URL
  bool isValidPdfUrl(String url) {
    return _repository.isValidPdfUrl(url);
  }

  // Check if URL is a valid image URL
  bool isValidImageUrl(String url) {
    return _repository.isValidImageUrl(url);
  }

  // Validate material link
  bool validateMaterialLink(MaterialLink materialLink) {
    return _repository.validateMaterialLink(materialLink);
  }

  // Get material type from URL
  MaterialType getMaterialTypeFromUrl(String url) {
    return _repository.getMaterialTypeFromUrl(url);
  }

  // Get material display title from URL
  String getMaterialDisplayTitleFromUrl(String url) {
    return _repository.getMaterialDisplayTitleFromUrl(url);
  }

  // Create MaterialLink from URL
  MaterialLink createMaterialLinkFromUrl(
    String url, {
    String? title,
    String? description,
  }) {
    return _repository.createMaterialLinkFromUrl(
      url,
      title: title,
      description: description,
    );
  }
}

// Providers
final mediaProvider =
    AutoDisposeStateNotifierProvider<MediaNotifier, MediaState>((ref) {
      final repository = ref.watch(mediaRepositoryProvider);
      return MediaNotifier(repository);
    });

// Convenience providers for specific data
final materialMetadataProvider = AutoDisposeProvider<Map<String, dynamic>?>((
  ref,
) {
  final state = ref.watch(mediaProvider);
  return state.materialMetadata;
});

final isOpeningInBrowserProvider = AutoDisposeProvider<bool>((ref) {
  final state = ref.watch(mediaProvider);
  return state.isOpeningInBrowser;
});
