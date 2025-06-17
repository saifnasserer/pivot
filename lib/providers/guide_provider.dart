import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pivot/models/guide_content.dart';
import 'package:pivot/models/guidebook_model.dart';

class GuideProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  GuideContent? _guideContent;
  GuideContent? get guideContent => _guideContent;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  CollectionReference get _guideCollection =>
      _firestore.collection('guide_content');

  Future<void> fetchGuideContent() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final docSnapshot = await _guideCollection.doc('default_guide').get();
      if (docSnapshot.exists) {
        _guideContent =
            GuideContent.fromMap(docSnapshot.data() as Map<String, dynamic>);
      } else {
        _guideContent = GuideContent(guidebooks: []);
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

  Future<String> _uploadFileBytes(Uint8List bytes, String path) async {
    final ref = _storage.ref().child(path);
    final uploadTask = ref.putData(bytes);
    final snapshot = await uploadTask.whenComplete(() => {});
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> addGuidebook() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      _isLoading = true;
      notifyListeners();

      try {
        String downloadUrl;
        final String fileName = result.files.single.name;
        final String storagePath =
            'guides/${DateTime.now().millisecondsSinceEpoch}_$fileName';

        if (kIsWeb) {
          final Uint8List fileBytes = result.files.single.bytes!;
          downloadUrl = await _uploadFileBytes(fileBytes, storagePath);
        } else {
          final File file = File(result.files.single.path!);
          downloadUrl = await _uploadFile(file, storagePath);
        }

        final newGuidebook = Guidebook(
          name: fileName,
          url: downloadUrl,
          storagePath: storagePath,
        );

        await _guideCollection.doc('default_guide').update({
          'guidebooks': FieldValue.arrayUnion([newGuidebook.toMap()])
        });

        await fetchGuideContent();
      } catch (e) {
        _error = 'Failed to upload guidebook: $e';
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> removeGuidebook(Guidebook guidebook) async {
    _isLoading = true;
    notifyListeners();

    try {
      final ref = _storage.ref().child(guidebook.storagePath);
      await ref.delete();

      await _guideCollection.doc('default_guide').update({
        'guidebooks': FieldValue.arrayRemove([guidebook.toMap()])
      });

      await fetchGuideContent();
    } catch (e) {
      _error = 'Failed to remove guidebook: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

