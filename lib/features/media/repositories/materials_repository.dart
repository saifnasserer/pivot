import 'package:pivot/features/media/services/materials_service.dart';
import 'package:pivot/models/material_link.dart';

class MaterialsRepository {
  final MaterialsService _materialsService;

  MaterialsRepository(this._materialsService);

  // Get all materials from all lectures
  Future<List<MaterialLink>> getAllMaterials() async {
    return await _materialsService.getAllMaterials();
  }

  // Get materials by type
  Future<List<MaterialLink>> getMaterialsByType(MaterialType type) async {
    return await _materialsService.getMaterialsByType(type);
  }

  // Get materials by lecture ID
  Future<List<MaterialLink>> getMaterialsByLectureId(String lectureId) async {
    return await _materialsService.getMaterialsByLectureId(lectureId);
  }

  // Search materials
  Future<List<MaterialLink>> searchMaterials(String query) async {
    return await _materialsService.searchMaterials(query);
  }

  // Get materials statistics
  Future<Map<String, dynamic>> getMaterialsStatistics() async {
    return await _materialsService.getMaterialsStatistics();
  }

  // Get recent materials
  Future<List<MaterialLink>> getRecentMaterials({int limit = 10}) async {
    return await _materialsService.getRecentMaterials(limit: limit);
  }

  // Get popular materials
  Future<List<MaterialLink>> getPopularMaterials({int limit = 10}) async {
    return await _materialsService.getPopularMaterials(limit: limit);
  }

  // Add material to lecture
  Future<bool> addMaterialToLecture(
    String lectureId,
    MaterialLink materialLink,
  ) async {
    return await _materialsService.addMaterialToLecture(
      lectureId,
      materialLink,
    );
  }

  // Remove material from lecture
  Future<bool> removeMaterialFromLecture(
    String lectureId,
    MaterialLink materialLink,
  ) async {
    return await _materialsService.removeMaterialFromLecture(
      lectureId,
      materialLink,
    );
  }

  // Update material in lecture
  Future<bool> updateMaterialInLecture(
    String lectureId,
    MaterialLink oldMaterial,
    MaterialLink newMaterial,
  ) async {
    return await _materialsService.updateMaterialInLecture(
      lectureId,
      oldMaterial,
      newMaterial,
    );
  }

  // Get materials by subject
  Future<List<MaterialLink>> getMaterialsBySubject(String subjectId) async {
    return await _materialsService.getMaterialsBySubject(subjectId);
  }

  // Get materials by doctor
  Future<List<MaterialLink>> getMaterialsByDoctor(String doctorId) async {
    return await _materialsService.getMaterialsByDoctor(doctorId);
  }
}
