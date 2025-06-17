import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:pivot/models/guide_content.dart';

class GuideProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  GuideContent? _guideContent;
  GuideContent? get guideContent => _guideContent;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  CollectionReference get _guideCollection => _firestore.collection('guide_content');

  Future<void> fetchGuideContent() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final docSnapshot = await _guideCollection.doc('default_guide').get();
      if (docSnapshot.exists) {
        _guideContent = GuideContent.fromMap(docSnapshot.data() as Map<String, dynamic>);
      } else {
        _guideContent = GuideContent(guidebookUrl: '', planImageUrls: []);
        await _guideCollection.doc('default_guide').set(_guideContent!.toMap());
      }
    } catch (e) {
      _error = 'Failed to fetch guide content: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> _uploadFile(File file, String path) async {
    final ref = _storage.ref().child(path);
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask.whenComplete(() => {});
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> updateGuidebook() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      _isLoading = true;
      notifyListeners();

      try {
        final downloadUrl = await _uploadFile(file, 'guides/guidebook.pdf');
        await _guideCollection.doc('default_guide').set(
          {'guidebookUrl': downloadUrl},
          SetOptions(merge: true),
        );
        await fetchGuideContent();
      } catch (e) {
        _error = 'Failed to upload guidebook: $e';
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> addPlanImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      _isLoading = true;
      notifyListeners();

      try {
        final fileName = 'plan_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final downloadUrl = await _uploadFile(file, 'guides/plans/$fileName');
        
        await _guideCollection.doc('default_guide').update({
          'planImageUrls': FieldValue.arrayUnion([downloadUrl])
        });

        await fetchGuideContent();
      } catch (e) {
        _error = 'Failed to upload plan image: $e';
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> removePlanImage(String imageUrl) async {
    _isLoading = true;
    notifyListeners();

    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();

      await _guideCollection.doc('default_guide').update({
        'planImageUrls': FieldValue.arrayRemove([imageUrl])
      });
      
      await fetchGuideContent();
    } catch (e) {
      _error = 'Failed to remove plan image: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
