import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:pivot/models/material_link.dart';
import 'package:pivot/services/doctor_subject_service.dart';

class MaterialLinksProvider with ChangeNotifier {
  final DoctorSubjectService _service = DoctorSubjectService();

  List<MaterialLink> _materialLinks = [];
  bool _isLoading = false;
  String? _error;
  String? _currentLectureId;
  String _searchQuery = '';
  MaterialType? _selectedType;

  List<MaterialLink> get materialLinks => _materialLinks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  MaterialType? get selectedType => _selectedType;

  List<MaterialLink> get filteredLinks {
    List<MaterialLink> filtered = _materialLinks;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered
              .where(
                (link) =>
                    link.displayTitle.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    link.url.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    (link.description?.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ??
                        false),
              )
              .toList();
    }

    // Filter by type
    if (_selectedType != null) {
      filtered = filtered.where((link) => link.type == _selectedType).toList();
    }

    return filtered;
  }

  void _safeNotifyListeners() {
    if (SchedulerBinding.instance.schedulerPhase !=
        SchedulerPhase.persistentCallbacks) {
      notifyListeners();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  Future<void> fetchMaterialLinks(String lectureId) async {
    if (lectureId.isEmpty) {
      _materialLinks = [];
      _safeNotifyListeners();
      return;
    }

    _currentLectureId = lectureId;
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      // Get the specific lecture by ID
      final lecture = await _service.getLectureById(lectureId);

      if (lecture == null) {
        throw Exception('Lecture not found');
      }

      // Convert legacy Map<String, String> links to MaterialLink objects
      _materialLinks =
          lecture.links.map((linkMap) {
            return MaterialLink.fromMap(linkMap);
          }).toList();
    } catch (e) {
      _error = 'Failed to fetch material links: ${e.toString()}';
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<void> addMaterialLink(String lectureId, MaterialLink link) async {
    try {
      // Convert MaterialLink back to legacy format for the service
      final legacyLink = link.toLegacyMap();
      await _service.addLinkToLecture(lectureId, legacyLink);

      // Add to current list if this is the currently displayed lecture
      if (lectureId == _currentLectureId) {
        _materialLinks.add(link);
        _safeNotifyListeners();
      }
    } catch (e) {
      _error = 'Failed to add material link: ${e.toString()}';
      _safeNotifyListeners();
    }
  }

  Future<void> updateMaterialLink(String lectureId, MaterialLink link) async {
    try {
      // For now, we'll delete and re-add since the service doesn't support updates
      await deleteMaterialLink(lectureId, link);
      await addMaterialLink(lectureId, link);
    } catch (e) {
      _error = 'Failed to update material link: ${e.toString()}';
      _safeNotifyListeners();
    }
  }

  Future<void> deleteMaterialLink(
    String lectureId,
    MaterialLink materialLink,
  ) async {
    try {
      _isLoading = true;
      _safeNotifyListeners();

      // Convert to legacy format for service
      final legacyMap = materialLink.toLegacyMap();
      await _service.deleteLinkFromLecture(lectureId, legacyMap);

      // Remove from local list
      _materialLinks.removeWhere((link) => link.url == materialLink.url);
      _safeNotifyListeners();
    } catch (e) {
      _error = 'Failed to delete material link: ${e.toString()}';
      _safeNotifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<void> rateMaterial(
    String lectureId,
    MaterialLink materialLink,
    String userId,
    double rating,
  ) async {
    try {
      _isLoading = true;
      _safeNotifyListeners();

      // Create updated material link with new rating
      final updatedUserRatings = Map<String, double>.from(
        materialLink.userRatings,
      );
      updatedUserRatings[userId] = rating;

      final updatedMaterialLink = materialLink.copyWith(
        userRatings: updatedUserRatings,
        totalRatings: updatedUserRatings.length,
        averageRating:
            updatedUserRatings.values.reduce((a, b) => a + b) /
            updatedUserRatings.length,
      );

      // Update in service (convert to legacy format)
      final legacyMap = updatedMaterialLink.toLegacyMap();
      await _service.updateLinkInLecture(lectureId, legacyMap);

      // Update in local list
      final index = _materialLinks.indexWhere(
        (link) => link.url == materialLink.url,
      );
      if (index != -1) {
        _materialLinks[index] = updatedMaterialLink;
      }

      _safeNotifyListeners();
    } catch (e) {
      _error = 'Failed to rate material: ${e.toString()}';
      _safeNotifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<void> removeRating(
    String lectureId,
    MaterialLink materialLink,
    String userId,
  ) async {
    try {
      _isLoading = true;
      _safeNotifyListeners();

      // Create updated material link without user's rating
      final updatedUserRatings = Map<String, double>.from(
        materialLink.userRatings,
      );
      updatedUserRatings.remove(userId);

      final updatedMaterialLink = materialLink.copyWith(
        userRatings: updatedUserRatings,
        totalRatings: updatedUserRatings.length,
        averageRating:
            updatedUserRatings.isEmpty
                ? 0.0
                : updatedUserRatings.values.reduce((a, b) => a + b) /
                    updatedUserRatings.length,
      );

      // Update in service (convert to legacy format)
      final legacyMap = updatedMaterialLink.toLegacyMap();
      await _service.updateLinkInLecture(lectureId, legacyMap);

      // Update in local list
      final index = _materialLinks.indexWhere(
        (link) => link.url == materialLink.url,
      );
      if (index != -1) {
        _materialLinks[index] = updatedMaterialLink;
      }

      _safeNotifyListeners();
    } catch (e) {
      _error = 'Failed to remove rating: ${e.toString()}';
      _safeNotifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _safeNotifyListeners();
  }

  void setSelectedType(MaterialType? type) {
    _selectedType = type;
    _safeNotifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedType = null;
    _safeNotifyListeners();
  }

  List<MaterialType> get availableTypes {
    final types = _materialLinks.map((link) => link.type).toSet();
    return types.toList();
  }

  Map<MaterialType, int> get typeCounts {
    final counts = <MaterialType, int>{};
    for (final link in _materialLinks) {
      counts[link.type] = (counts[link.type] ?? 0) + 1;
    }
    return counts;
  }
}
