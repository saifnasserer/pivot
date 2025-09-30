import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pivot/models/guide_content.dart';
import 'package:pivot/models/guidebook_model.dart';
import 'package:image_picker/image_picker.dart';

class GuideService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collectionPath = 'guide_content';

  Future<GuideContent> fetchGuideContent() async {
    try {
      final docSnapshot =
          await _firestore
              .collection(_collectionPath)
              .doc('default_guide')
              .get();

      if (docSnapshot.exists) {
        return GuideContent.fromMap(docSnapshot.data() as Map<String, dynamic>);
      } else {
        // Create default guide content if it doesn't exist
        final defaultGuide = GuideContent(guidebooks: []);
        await _firestore
            .collection(_collectionPath)
            .doc('default_guide')
            .set(defaultGuide.toMap());
        return defaultGuide;
      }
    } catch (e) {
      throw Exception('Failed to fetch guide content: $e');
    }
  }

  Future<void> addGuidebook(Guidebook guidebook) async {
    try {
      final guideContent = await fetchGuideContent();
      final updatedGuidebooks = [...guideContent.guidebooks, guidebook];
      final updatedGuideContent = guideContent.copyWith(
        guidebooks: updatedGuidebooks,
      );

      await _firestore
          .collection(_collectionPath)
          .doc('default_guide')
          .update(updatedGuideContent.toMap());
    } catch (e) {
      throw Exception('Failed to add guidebook: $e');
    }
  }

  Future<void> updateGuidebook(String id, Guidebook guidebook) async {
    try {
      final guideContent = await fetchGuideContent();
      final updatedGuidebooks =
          guideContent.guidebooks.map((gb) {
            return gb.id == id ? guidebook : gb;
          }).toList();

      final updatedGuideContent = guideContent.copyWith(
        guidebooks: updatedGuidebooks,
      );

      await _firestore
          .collection(_collectionPath)
          .doc('default_guide')
          .update(updatedGuideContent.toMap());
    } catch (e) {
      throw Exception('Failed to update guidebook: $e');
    }
  }

  Future<void> deleteGuidebook(String id) async {
    try {
      final guideContent = await fetchGuideContent();
      final updatedGuidebooks =
          guideContent.guidebooks.where((gb) => gb.id != id).toList();

      final updatedGuideContent = guideContent.copyWith(
        guidebooks: updatedGuidebooks,
      );

      await _firestore
          .collection(_collectionPath)
          .doc('default_guide')
          .update(updatedGuideContent.toMap());
    } catch (e) {
      throw Exception('Failed to delete guidebook: $e');
    }
  }

  Future<String> uploadGuidebookFile(String filePath, String fileName) async {
    try {
      final file = File(filePath);
      final ref = _storage.ref().child('guidebooks/$fileName');

      final uploadTask = ref.putFile(file);

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((snapshot) {
        // final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        // You might want to emit progress events here
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload guidebook file: $e');
    }
  }

  Future<String> uploadImage(String imagePath) async {
    try {
      // TODO: Implement image upload using StorageOptimizationService
      // For now, return a placeholder
      return 'placeholder_image_url';
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<void> pickAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await uploadImage(image.path);
      }
    } catch (e) {
      throw Exception('Failed to pick and upload image: $e');
    }
  }
}
