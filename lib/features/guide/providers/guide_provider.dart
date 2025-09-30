import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/guide/repositories/guide_repository.dart';
import 'package:pivot/features/guide/services/guide_service.dart';
import 'package:pivot/models/guide_content.dart';
import 'package:pivot/models/guidebook_model.dart';

final guideServiceProvider = Provider<GuideService>((ref) => GuideService());

final guideRepositoryProvider = Provider<GuideRepository>((ref) {
  final service = ref.watch(guideServiceProvider);
  return GuideRepository(service);
});

class GuideState {
  final GuideContent? guideContent;
  final bool isLoading;
  final String? error;
  final bool isUploading;
  final double uploadProgress;
  final String? uploadError;

  const GuideState({
    this.guideContent,
    this.isLoading = false,
    this.error,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.uploadError,
  });

  GuideState copyWith({
    GuideContent? guideContent,
    bool? isLoading,
    String? error,
    bool? isUploading,
    double? uploadProgress,
    String? uploadError,
  }) => GuideState(
    guideContent: guideContent ?? this.guideContent,
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
    isUploading: isUploading ?? this.isUploading,
    uploadProgress: uploadProgress ?? this.uploadProgress,
    uploadError: uploadError ?? this.uploadError,
  );
}

final guideProvider =
    StateNotifierProvider.autoDispose<GuideNotifier, GuideState>(
      (ref) => GuideNotifier(ref),
    );

class GuideNotifier extends StateNotifier<GuideState> {
  GuideNotifier(this._ref) : super(const GuideState());

  final Ref _ref;
  late final GuideRepository _repo = _ref.read(guideRepositoryProvider);

  Future<void> fetchGuideContent() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final guideContent = await _repo.fetchGuideContent();
      state = state.copyWith(isLoading: false, guideContent: guideContent);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addGuidebook(Guidebook guidebook) async {
    try {
      await _repo.addGuidebook(guidebook);
      // Refresh the guide content
      await fetchGuideContent();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateGuidebook(String id, Guidebook guidebook) async {
    try {
      await _repo.updateGuidebook(id, guidebook);
      // Refresh the guide content
      await fetchGuideContent();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteGuidebook(String id) async {
    try {
      await _repo.deleteGuidebook(id);
      // Refresh the guide content
      await fetchGuideContent();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> uploadGuidebookFile(String filePath, String fileName) async {
    state = state.copyWith(isUploading: true, uploadError: null);
    try {
      await _repo.uploadGuidebookFile(filePath, fileName);
      state = state.copyWith(isUploading: false, uploadProgress: 1.0);
      // You might want to add the uploaded file to a guidebook here
    } catch (e) {
      state = state.copyWith(isUploading: false, uploadError: e.toString());
    }
  }

  void setUploadProgress(double progress) {
    state = state.copyWith(uploadProgress: progress);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearUploadError() {
    state = state.copyWith(uploadError: null);
  }
}
