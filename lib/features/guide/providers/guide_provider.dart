import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/models/guide_content.dart';
import 'package:pivot/models/guidebook_model.dart';
import 'package:pivot/services/storage_optimization_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

// State class
class GuideState {
  final GuideContent? guideContent;
  final bool isLoading;
  final String? error;

  GuideState({this.guideContent, this.isLoading = false, this.error});

  GuideState copyWith({
    GuideContent? guideContent,
    bool? isLoading,
    String? error,
  }) {
    return GuideState(
      guideContent: guideContent ?? this.guideContent,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// StateNotifier
class GuideNotifier extends StateNotifier<GuideState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  GuideNotifier() : super(GuideState());

  CollectionReference get _guideCollection =>
      _firestore.collection('guide_content');

  Future<void> fetchGuideContent() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final docSnapshot = await _guideCollection.doc('default_guide').get();
      if (docSnapshot.exists) {
        final content = GuideContent.fromMap(
          docSnapshot.data() as Map<String, dynamic>,
        );
        state = GuideState(guideContent: content, isLoading: false);
      } else {
        final newContent = GuideContent(guidebooks: []);
        await _guideCollection.doc('default_guide').set(newContent.toMap());
        state = GuideState(guideContent: newContent, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch guide content: $e',
      );
    }
  }

  Future<void> addGuidebook() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      state = state.copyWith(isLoading: true);

      try {
        String downloadUrl;
        final String fileName = result.files.single.name;

        // Use the optimized storage service
        final storageService = StorageOptimizationService();

        if (kIsWeb) {
          // For web, we need to create a temporary file
          final Uint8List fileBytes = result.files.single.bytes!;
          final storagePath =
              'guides/${DateTime.now().millisecondsSinceEpoch}_$fileName';
          final ref = _storage.ref().child(storagePath);
          final uploadTask = ref.putData(fileBytes);
          final snapshot = await uploadTask.whenComplete(() => {});
          downloadUrl = await snapshot.ref.getDownloadURL();
        } else {
          // For mobile, use the optimized service
          final File file = File(result.files.single.path!);
          final xFile = XFile(file.path);
          downloadUrl =
              await storageService.uploadFileOptimized(
                xFile,
                folder: 'guides',
                usage: 'general',
                checkDuplicate: true,
              ) ??
              '';
        }

        if (downloadUrl.isNotEmpty) {
          final newGuidebook = Guidebook(
            name: fileName,
            url: downloadUrl,
            storagePath:
                'guides/${DateTime.now().millisecondsSinceEpoch}_$fileName',
          );

          await _guideCollection.doc('default_guide').update({
            'guidebooks': FieldValue.arrayUnion([newGuidebook.toMap()]),
          });

          await fetchGuideContent();
        }
      } catch (e) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to upload guidebook: $e',
        );
      }
    }
  }

  Future<void> removeGuidebook(Guidebook guidebook) async {
    state = state.copyWith(isLoading: true);

    try {
      final ref = _storage.ref().child(guidebook.storagePath);
      await ref.delete();

      await _guideCollection.doc('default_guide').update({
        'guidebooks': FieldValue.arrayRemove([guidebook.toMap()]),
      });

      await fetchGuideContent();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to remove guidebook: $e',
      );
    }
  }
}

// Riverpod Provider
final guideProvider = StateNotifierProvider<GuideNotifier, GuideState>((ref) {
  return GuideNotifier();
});
