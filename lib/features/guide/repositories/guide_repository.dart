import 'package:pivot/features/guide/services/guide_service.dart';
import 'package:pivot/models/guide_content.dart';
import 'package:pivot/models/guidebook_model.dart';

class GuideRepository {
  GuideRepository(this._service);

  final GuideService _service;

  Future<GuideContent> fetchGuideContent() => _service.fetchGuideContent();

  Future<void> addGuidebook(Guidebook guidebook) =>
      _service.addGuidebook(guidebook);

  Future<void> updateGuidebook(String id, Guidebook guidebook) =>
      _service.updateGuidebook(id, guidebook);

  Future<void> deleteGuidebook(String id) => _service.deleteGuidebook(id);

  Future<String> uploadGuidebookFile(String filePath, String fileName) =>
      _service.uploadGuidebookFile(filePath, fileName);

  Future<String> uploadImage(String imagePath) =>
      _service.uploadImage(imagePath);

  Future<void> pickAndUploadImage() => _service.pickAndUploadImage();
}
