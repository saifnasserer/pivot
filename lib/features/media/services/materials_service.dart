import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pivot/models/material_link.dart';

class MaterialsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all materials from all lectures
  Future<List<MaterialLink>> getAllMaterials() async {
    try {
      final lecturesSnapshot = await _firestore.collection('lectures').get();
      List<MaterialLink> allMaterials = [];

      for (var doc in lecturesSnapshot.docs) {
        final data = doc.data();
        final links = data['links'] as List<dynamic>? ?? [];

        for (var linkData in links) {
          try {
            final materialLink = MaterialLink.fromMap(
              Map<String, dynamic>.from(linkData),
            );
            allMaterials.add(materialLink);
          } catch (e) {
            // Skip invalid material links
            continue;
          }
        }
      }

      return allMaterials;
    } catch (e) {
      throw Exception('Failed to fetch all materials: $e');
    }
  }

  // Get materials by type
  Future<List<MaterialLink>> getMaterialsByType(MaterialType type) async {
    try {
      final allMaterials = await getAllMaterials();
      return allMaterials.where((material) => material.type == type).toList();
    } catch (e) {
      throw Exception('Failed to fetch materials by type: $e');
    }
  }

  // Get materials by lecture ID
  Future<List<MaterialLink>> getMaterialsByLectureId(String lectureId) async {
    try {
      final lectureDoc =
          await _firestore.collection('lectures').doc(lectureId).get();

      if (!lectureDoc.exists) {
        throw Exception('Lecture not found');
      }

      final data = lectureDoc.data()!;
      final links = data['links'] as List<dynamic>? ?? [];

      return links.map((linkData) {
        return MaterialLink.fromMap(Map<String, dynamic>.from(linkData));
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch materials by lecture ID: $e');
    }
  }

  // Search materials
  Future<List<MaterialLink>> searchMaterials(String query) async {
    try {
      final allMaterials = await getAllMaterials();
      final lowercaseQuery = query.toLowerCase();

      return allMaterials.where((material) {
        return material.displayTitle.toLowerCase().contains(lowercaseQuery) ||
            material.url.toLowerCase().contains(lowercaseQuery) ||
            (material.description?.toLowerCase().contains(lowercaseQuery) ??
                false);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search materials: $e');
    }
  }

  // Get materials statistics
  Future<Map<String, dynamic>> getMaterialsStatistics() async {
    try {
      final allMaterials = await getAllMaterials();

      int totalMaterials = allMaterials.length;
      int pdfCount = 0;
      int videoCount = 0;
      int imageCount = 0;
      int linkCount = 0;

      Map<String, int> materialsByLecture = {};

      for (var material in allMaterials) {
        switch (material.type) {
          case MaterialType.pdf:
            pdfCount++;
            break;
          case MaterialType.video:
            videoCount++;
            break;
          case MaterialType.image:
            imageCount++;
            break;
          case MaterialType.link:
            linkCount++;
            break;
          case MaterialType.document:
            linkCount++; // Treat document as link for now
            break;
        }
      }

      // Get materials by lecture
      final lecturesSnapshot = await _firestore.collection('lectures').get();
      for (var doc in lecturesSnapshot.docs) {
        final data = doc.data();
        final links = data['links'] as List<dynamic>? ?? [];
        materialsByLecture[doc.id] = links.length;
      }

      return {
        'totalMaterials': totalMaterials,
        'pdfCount': pdfCount,
        'videoCount': videoCount,
        'imageCount': imageCount,
        'linkCount': linkCount,
        'materialsByLecture': materialsByLecture,
        'averageMaterialsPerLecture':
            lecturesSnapshot.docs.isNotEmpty
                ? (totalMaterials / lecturesSnapshot.docs.length).round()
                : 0,
      };
    } catch (e) {
      throw Exception('Failed to fetch materials statistics: $e');
    }
  }

  // Get recent materials
  Future<List<MaterialLink>> getRecentMaterials({int limit = 10}) async {
    try {
      final allMaterials = await getAllMaterials();

      // Sort by creation time
      allMaterials.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return allMaterials.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to fetch recent materials: $e');
    }
  }

  // Get popular materials (by type)
  Future<List<MaterialLink>> getPopularMaterials({int limit = 10}) async {
    try {
      final allMaterials = await getAllMaterials();

      // Group by URL to count duplicates (popularity)
      Map<String, int> urlCounts = {};
      Map<String, MaterialLink> urlToMaterial = {};

      for (var material in allMaterials) {
        urlCounts[material.url] = (urlCounts[material.url] ?? 0) + 1;
        urlToMaterial[material.url] = material;
      }

      // Sort by count and return top materials
      final sortedUrls =
          urlCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      return sortedUrls
          .take(limit)
          .map((entry) => urlToMaterial[entry.key]!)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch popular materials: $e');
    }
  }

  // Add material to lecture
  Future<bool> addMaterialToLecture(
    String lectureId,
    MaterialLink materialLink,
  ) async {
    try {
      final lectureRef = _firestore.collection('lectures').doc(lectureId);

      await lectureRef.update({
        'links': FieldValue.arrayUnion([materialLink.toLegacyMap()]),
      });

      return true;
    } catch (e) {
      throw Exception('Failed to add material to lecture: $e');
    }
  }

  // Remove material from lecture
  Future<bool> removeMaterialFromLecture(
    String lectureId,
    MaterialLink materialLink,
  ) async {
    try {
      final lectureRef = _firestore.collection('lectures').doc(lectureId);

      await lectureRef.update({
        'links': FieldValue.arrayRemove([materialLink.toLegacyMap()]),
      });

      return true;
    } catch (e) {
      throw Exception('Failed to remove material from lecture: $e');
    }
  }

  // Update material in lecture
  Future<bool> updateMaterialInLecture(
    String lectureId,
    MaterialLink oldMaterial,
    MaterialLink newMaterial,
  ) async {
    try {
      // Remove old material and add new one
      await removeMaterialFromLecture(lectureId, oldMaterial);
      await addMaterialToLecture(lectureId, newMaterial);

      return true;
    } catch (e) {
      throw Exception('Failed to update material in lecture: $e');
    }
  }

  // Get materials by subject
  Future<List<MaterialLink>> getMaterialsBySubject(String subjectId) async {
    try {
      final lecturesSnapshot =
          await _firestore
              .collection('lectures')
              .where('subjectId', isEqualTo: subjectId)
              .get();

      List<MaterialLink> materials = [];

      for (var doc in lecturesSnapshot.docs) {
        final data = doc.data();
        final links = data['links'] as List<dynamic>? ?? [];

        for (var linkData in links) {
          try {
            final materialLink = MaterialLink.fromMap(
              Map<String, dynamic>.from(linkData),
            );
            materials.add(materialLink);
          } catch (e) {
            continue;
          }
        }
      }

      return materials;
    } catch (e) {
      throw Exception('Failed to fetch materials by subject: $e');
    }
  }

  // Get materials by doctor
  Future<List<MaterialLink>> getMaterialsByDoctor(String doctorId) async {
    try {
      final lecturesSnapshot =
          await _firestore
              .collection('lectures')
              .where('doctorId', isEqualTo: doctorId)
              .get();

      List<MaterialLink> materials = [];

      for (var doc in lecturesSnapshot.docs) {
        final data = doc.data();
        final links = data['links'] as List<dynamic>? ?? [];

        for (var linkData in links) {
          try {
            final materialLink = MaterialLink.fromMap(
              Map<String, dynamic>.from(linkData),
            );
            materials.add(materialLink);
          } catch (e) {
            continue;
          }
        }
      }

      return materials;
    } catch (e) {
      throw Exception('Failed to fetch materials by doctor: $e');
    }
  }

  // Rate a material
  Future<void> rateMaterial(
    String lectureId,
    MaterialLink material,
    String userId,
    double rating,
  ) async {
    try {
      final lectureRef = _firestore.collection('lectures').doc(lectureId);
      final lectureDoc = await lectureRef.get();

      if (!lectureDoc.exists) {
        throw Exception('Lecture not found');
      }

      final data = lectureDoc.data()!;
      final links = List<Map<String, dynamic>>.from(data['links'] ?? []);

      // Find the material in the links array
      final materialIndex = links.indexWhere(
        (link) => link['url'] == material.url,
      );

      if (materialIndex == -1) {
        throw Exception('Material not found in lecture');
      }

      // Update the rating
      final materialData = links[materialIndex];
      final userRatings = Map<String, double>.from(
        materialData['userRatings'] ?? {},
      );
      userRatings[userId] = rating;

      // Calculate new average
      final totalRatings = userRatings.length;
      final sum = userRatings.values.reduce((a, b) => a + b);
      final averageRating = sum / totalRatings;

      // Update the material data
      materialData['userRatings'] = userRatings;
      materialData['totalRatings'] = totalRatings;
      materialData['averageRating'] = averageRating;

      links[materialIndex] = materialData;

      // Update the lecture document
      await lectureRef.update({'links': links});
    } catch (e) {
      throw Exception('Failed to rate material: $e');
    }
  }
}
