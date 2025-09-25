import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' hide MaterialType;
import 'package:pivot/models/lecture_model.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/models/material_link.dart';

class MaterialBrowserBottomSheet extends StatefulWidget {
  const MaterialBrowserBottomSheet({super.key});

  @override
  State<MaterialBrowserBottomSheet> createState() =>
      _MaterialBrowserBottomSheetState();
}

class _MaterialBrowserBottomSheetState
    extends State<MaterialBrowserBottomSheet> {
  final TextEditingController _searchController = TextEditingController();

  List<MaterialLink> _allMaterials = [];
  List<MaterialLink> _filteredMaterials = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAllMaterials();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllMaterials() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch all lectures from Firestore
      final QuerySnapshot lecturesSnapshot =
          await FirebaseFirestore.instance.collection('lectures').get();

      final List<MaterialLink> allMaterials = [];
      final Map<String, UserProfile> doctorProfiles = {};

      // Fetch all doctor profiles for display
      final QuerySnapshot doctorsSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('role', whereIn: ['Professor', 'miniProfessor'])
              .get();

      for (var doc in doctorsSnapshot.docs) {
        final userData = doc.data() as Map<String, dynamic>;
        doctorProfiles[doc.id] = UserProfile.fromJson(userData);
      }

      // Process each lecture and extract materials
      for (var doc in lecturesSnapshot.docs) {
        try {
          final lecture = Lecture.fromFirestore(doc);

          // Get doctor profile for this lecture
          final doctorProfile = doctorProfiles[lecture.doctorId];
          final doctorName = doctorProfile?.name ?? 'Unknown Doctor';

          // Convert lecture links to MaterialLink objects
          for (var linkMap in lecture.links) {
            try {
              final materialLink = MaterialLink.fromMap(linkMap);

              // Add metadata for search
              final enhancedMaterialLink = materialLink.copyWith(
                metadata: {
                  ...materialLink.metadata,
                  'lectureTitle': lecture.title,
                  'doctorName': doctorName,
                  'subjectId': lecture.subjectId,
                  'lectureId': lecture.id,
                },
              );

              allMaterials.add(enhancedMaterialLink);
            } catch (e) {
              // Skip this material if there's an error
              continue;
            }
          }
        } catch (e) {
          // Skip this lecture if there's an error
          continue;
        }
      }

      setState(() {
        _allMaterials = allMaterials;
        _filteredMaterials = allMaterials;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load materials: $e';
        _isLoading = false;
      });
    }
  }

  void _filterMaterials(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredMaterials = _allMaterials;
      } else {
        _filteredMaterials =
            _allMaterials.where((material) {
              final searchLower = query.toLowerCase();

              // Search in material title
              if (material.title.toLowerCase().contains(searchLower)) {
                return true;
              }

              // Search in material description
              if (material.description?.toLowerCase().contains(searchLower) ==
                  true) {
                return true;
              }

              // Search in doctor name
              final doctorName =
                  material.metadata['doctorName']?.toString().toLowerCase() ??
                  '';
              if (doctorName.contains(searchLower)) {
                return true;
              }

              // Search in lecture title
              final lectureTitle =
                  material.metadata['lectureTitle']?.toString().toLowerCase() ??
                  '';
              if (lectureTitle.contains(searchLower)) {
                return true;
              }

              // Search in URL
              if (material.url.toLowerCase().contains(searchLower)) {
                return true;
              }

              return false;
            }).toList();
      }
    });
  }

  Widget _buildMaterialCard(MaterialLink material) {
    final doctorName =
        material.metadata['doctorName']?.toString() ?? 'Unknown Doctor';
    final lectureTitle =
        material.metadata['lectureTitle']?.toString() ?? 'Unknown Lecture';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: EdgeInsets.only(
          bottom: Responsive.space(context, size: Space.small),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.medium),
          ),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.medium),
            ),
            onTap: () {
              Navigator.of(context).pop(material);
            },
            child: Padding(
              padding: Responsive.padding(context, size: Space.medium),
              child: Row(
                children: [
                  // Material type icon
                  Container(
                    padding: EdgeInsets.all(
                      Responsive.space(context, size: Space.small),
                    ),
                    decoration: BoxDecoration(
                      color: _getMaterialTypeColor(
                        material.type,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getMaterialTypeColor(
                          material.type,
                        ).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      _getMaterialTypeIcon(material.type),
                      color: _getMaterialTypeColor(material.type),
                      size: Responsive.space(context, size: Space.large),
                    ),
                  ),
                  SizedBox(
                    width: Responsive.space(context, size: Space.medium),
                  ),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          material.title,
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(
                          height:
                              Responsive.space(context, size: Space.small) / 2,
                        ),

                        // Doctor name
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                doctorName,
                                style: TextStyle(
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.small,
                                  ),
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height:
                              Responsive.space(context, size: Space.small) / 2,
                        ),

                        // Lecture title
                        Row(
                          children: [
                            Icon(
                              Icons.school,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                lectureTitle,
                                style: TextStyle(
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.small,
                                  ),
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        // Description
                        if (material.description?.isNotEmpty == true) ...[
                          SizedBox(
                            height:
                                Responsive.space(context, size: Space.small) /
                                2,
                          ),
                          Text(
                            material.description!,
                            style: TextStyle(
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.small,
                              ),
                              color: Colors.grey[500],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Add button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.add, color: Colors.blue[700], size: 20),
                      onPressed: () {
                        Navigator.of(context).pop(material);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getMaterialTypeIcon(MaterialType type) {
    switch (type) {
      case MaterialType.video:
        return Icons.play_circle_outline;
      case MaterialType.pdf:
        return Icons.picture_as_pdf;
      case MaterialType.document:
        return Icons.description;
      case MaterialType.image:
        return Icons.image;
      case MaterialType.link:
        return Icons.link;
    }
    return Icons.link; // Default fallback
  }

  Color _getMaterialTypeColor(MaterialType type) {
    switch (type) {
      case MaterialType.video:
        return Colors.red;
      case MaterialType.pdf:
        return Colors.orange;
      case MaterialType.document:
        return Colors.blue;
      case MaterialType.image:
        return Colors.green;
      case MaterialType.link:
        return Colors.grey;
    }
    return Colors.grey; // Default fallback
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Responsive.height(context) * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(
            Responsive.space(context, size: Space.large),
          ),
          topRight: Radius.circular(
            Responsive.space(context, size: Space.large),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar and header
          Container(
            padding: EdgeInsets.all(
              Responsive.space(context, size: Space.large),
            ),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(
                  Responsive.space(context, size: Space.large),
                ),
                topRight: Radius.circular(
                  Responsive.space(context, size: Space.large),
                ),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 50,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),

                // Header
                Column(
                  children: [
                    Text(
                      'اختيار من المتريال الموجودة',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.heading,
                        ),
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'ابحث ب اسم الدكتور او المادة او المتريال',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.small,
                        ),
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content area
          Expanded(
            child: Padding(
              padding: Responsive.padding(context, size: Space.large),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(
                        Responsive.space(context, size: Space.large),
                      ),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'البحث في اسم الملف، الدكتور، أو المحاضرة...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: Responsive.space(
                            context,
                            size: Space.medium,
                          ),
                          vertical: Responsive.space(
                            context,
                            size: Space.medium,
                          ),
                        ),
                      ),
                      onChanged: _filterMaterials,
                    ),
                  ),
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),

                  // Results count with filter chips
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.space(
                            context,
                            size: Space.small,
                          ),
                          vertical:
                              Responsive.space(context, size: Space.small) / 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'النتائج: ${_filteredMaterials.length}',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.small,
                            ),
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Spacer(),
                      if (_searchQuery.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.space(
                              context,
                              size: Space.small,
                            ),
                            vertical:
                                Responsive.space(context, size: Space.small) /
                                2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search,
                                size: 16,
                                color: Colors.orange[700],
                              ),
                              SizedBox(width: 4),
                              Text(
                                'البحث: $_searchQuery',
                                style: TextStyle(
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.small,
                                  ),
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),

                  // Materials List
                  Expanded(
                    child:
                        _isLoading
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.blue,
                                    ),
                                  ),
                                  SizedBox(
                                    height: Responsive.space(
                                      context,
                                      size: Space.medium,
                                    ),
                                  ),
                                  Text(
                                    'جاري تحميل المواد...',
                                    style: TextStyle(
                                      fontSize: Responsive.text(
                                        context,
                                        size: TextSize.medium,
                                      ),
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : _error != null
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(
                                      Responsive.space(
                                        context,
                                        size: Space.large,
                                      ),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(
                                        Responsive.space(
                                          context,
                                          size: Space.large,
                                        ),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.error_outline,
                                      size: 64,
                                      color: Colors.red[400],
                                    ),
                                  ),
                                  SizedBox(
                                    height: Responsive.space(
                                      context,
                                      size: Space.medium,
                                    ),
                                  ),
                                  Text(
                                    'حدث خطأ في تحميل المواد',
                                    style: TextStyle(
                                      fontSize: Responsive.text(
                                        context,
                                        size: TextSize.medium,
                                      ),
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  SizedBox(
                                    height: Responsive.space(
                                      context,
                                      size: Space.small,
                                    ),
                                  ),
                                  Text(
                                    _error!,
                                    style: TextStyle(color: Colors.red[600]),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(
                                    height: Responsive.space(
                                      context,
                                      size: Space.medium,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _loadAllMaterials,
                                    icon: Icon(Icons.refresh),
                                    label: Text('إعادة المحاولة'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : _filteredMaterials.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(
                                      Responsive.space(
                                        context,
                                        size: Space.large,
                                      ),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(
                                        Responsive.space(
                                          context,
                                          size: Space.large,
                                        ),
                                      ),
                                    ),
                                    child: Icon(
                                      _searchQuery.isEmpty
                                          ? Icons.folder_open
                                          : Icons.search_off,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  SizedBox(
                                    height: Responsive.space(
                                      context,
                                      size: Space.medium,
                                    ),
                                  ),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? 'لا توجد مواد متاحة'
                                        : 'لا توجد نتائج للبحث',
                                    style: TextStyle(
                                      fontSize: Responsive.text(
                                        context,
                                        size: TextSize.medium,
                                      ),
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  SizedBox(
                                    height: Responsive.space(
                                      context,
                                      size: Space.small,
                                    ),
                                  ),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? 'لم يتم رفع أي مواد بعد'
                                        : 'جرب البحث بكلمات مختلفة',
                                    style: TextStyle(
                                      fontSize: Responsive.text(
                                        context,
                                        size: TextSize.small,
                                      ),
                                      color: Colors.grey[500],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              itemCount: _filteredMaterials.length,
                              itemBuilder: (context, index) {
                                return _buildMaterialCard(
                                  _filteredMaterials[index],
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
