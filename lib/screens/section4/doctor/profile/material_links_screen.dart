import 'package:flutter/material.dart' hide MaterialType;
import 'package:flutter/services.dart';
import 'package:pivot/services/haptic_service.dart';
import 'package:pivot/models/lecture_model.dart';
import 'package:pivot/models/material_link.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/material_links_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section4/doctor/profile/material_card.dart';
import 'package:pivot/screens/section4/doctor/profile/add_material_dialog.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MaterialLinksScreen extends StatefulWidget {
  final Lecture lecture;
  final UserProfile? loggedInUser;

  const MaterialLinksScreen({
    super.key,
    required this.lecture,
    this.loggedInUser,
  });

  @override
  State<MaterialLinksScreen> createState() => _MaterialLinksScreenState();
}

class _MaterialLinksScreenState extends State<MaterialLinksScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    // Fetch material links when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint(
        'MaterialLinksScreen: Logged in user: ${widget.loggedInUser?.id}',
      );
      debugPrint(
        'MaterialLinksScreen: User role: ${widget.loggedInUser?.role}',
      );
      context.read<MaterialLinksProvider>().fetchMaterialLinks(
        widget.lecture.id,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String urlString) async {
    HapticService().lightImpact();

    final Uri? url = Uri.tryParse(urlString);
    if (url != null && await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر فتح الرابط: $urlString'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'إعادة المحاولة',
              onPressed: () => _launchURL(urlString),
            ),
          ),
        );
      }
    }
  }

  void _showAddMaterialDialog() async {
    final result = await showDialog<MaterialLink>(
      context: context,
      builder: (context) => AddMaterialDialog(),
    );

    if (result != null && mounted) {
      final provider = context.read<MaterialLinksProvider>();
      await provider.addMaterialLink(widget.lecture.id, result);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة المحتوى بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _showSearch ? null : _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        widget.lecture.title,
        style: TextStyle(
          color: Colors.black,
          fontSize: Responsive.text(context, size: TextSize.medium),
          fontWeight: FontWeight.w600,
          fontFamily: 'NotoSansArabic',
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black),
          onPressed: () {
            setState(() {
              _showSearch = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        if (_showSearch) _buildSearchBar(),
        Expanded(
          child: Consumer<MaterialLinksProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return _buildSkeletonLoading();
              }

              if (provider.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red.shade300,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'خطأ: ${provider.error}',
                        style: TextStyle(color: Colors.red.shade600),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed:
                            () =>
                                provider.fetchMaterialLinks(widget.lecture.id),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                );
              }

              final filteredLinks = provider.filteredLinks;

              if (filteredLinks.isEmpty) {
                return _buildEmptyState();
              }

              return Column(
                children: [
                  // _buildMaterialStats(provider),
                  _buildFilterChips(provider),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh:
                          () => provider.fetchMaterialLinks(widget.lecture.id),
                      child: ListView.builder(
                        padding: EdgeInsets.all(
                          Responsive.space(context, size: Space.small),
                        ),
                        itemCount: filteredLinks.length,
                        itemBuilder: (context, index) {
                          final link = filteredLinks[index];
                          return MaterialCard(
                            materialLink: link,
                            canEdit: widget.loggedInUser?.role != 'Student',
                            loggedInUser: widget.loggedInUser,
                            onTap: () => _launchURL(link.url),
                            onDelete: () => _deleteMaterial(link),
                            onRate: (rating) => _rateMaterial(link, rating),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.only(
        top:
            MediaQuery.of(context).padding.top +
            Responsive.space(context, size: Space.small),
        left: Responsive.space(context, size: Space.small),
        right: Responsive.space(context, size: Space.small),
        bottom: Responsive.space(context, size: Space.small),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  setState(() {
                    _showSearch = false;
                    _searchController.clear();
                    context.read<MaterialLinksProvider>().setSearchQuery('');
                  });
                },
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'البحث في المواد...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        Responsive.space(context, size: Space.large),
                      ),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: Responsive.space(context, size: Space.medium),
                      vertical: Responsive.space(context, size: Space.small),
                    ),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                context
                                    .read<MaterialLinksProvider>()
                                    .setSearchQuery('');
                              },
                            )
                            : null,
                  ),
                  onChanged: (value) {
                    context.read<MaterialLinksProvider>().setSearchQuery(value);
                  },
                ),
              ),
            ],
          ),
          if (_searchController.text.isNotEmpty) ...[
            SizedBox(height: Responsive.space(context, size: Space.small)),
            _buildSearchSuggestions(),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    final provider = context.read<MaterialLinksProvider>();
    final suggestions =
        provider.materialLinks
            .where(
              (link) =>
                  link.title.toLowerCase().contains(
                    _searchController.text.toLowerCase(),
                  ) ||
                  link.description?.toLowerCase().contains(
                        _searchController.text.toLowerCase(),
                      ) ==
                      true,
            )
            .take(3)
            .toList();

    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.small),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            suggestions
                .map(
                  (link) => ListTile(
                    dense: true,
                    leading: Icon(_getMaterialTypeIcon(link.type), size: 20),
                    title: Text(
                      link.title,
                      style: TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      _searchController.text = link.title;
                      context.read<MaterialLinksProvider>().setSearchQuery(
                        link.title,
                      );
                    },
                  ),
                )
                .toList(),
      ),
    );
  }

  IconData _getMaterialTypeIcon(MaterialType type) {
    switch (type) {
      case MaterialType.video:
        return Icons.video_library;
      case MaterialType.pdf:
        return Icons.picture_as_pdf;
      case MaterialType.document:
        return Icons.description;
      case MaterialType.image:
        return Icons.image;
      case MaterialType.link:
        return Icons.link;
    }
  }

  // Widget _buildMaterialStats(MaterialLinksProvider provider) {
  //   final totalMaterials = provider.materialLinks.length;
  //   final totalRatings = provider.materialLinks.fold(
  //     0,
  //     (sum, link) => sum + link.totalRatings,
  //   );
  //   final avgRating =
  //       provider.materialLinks.isEmpty
  //           ? 0.0
  //           : provider.materialLinks.fold(
  //                 0.0,
  //                 (sum, link) => sum + link.averageRating,
  //               ) /
  //               totalMaterials;

  //   return Container(
  //     margin: EdgeInsets.symmetric(
  //       horizontal: Responsive.space(context, size: Space.small),
  //       vertical: Responsive.space(context, size: Space.tiny),
  //     ),
  //     padding: EdgeInsets.all(Responsive.space(context, size: Space.small)),
  //     decoration: BoxDecoration(
  //       color: Colors.grey.shade50,
  //       borderRadius: BorderRadius.circular(
  //         Responsive.space(context, size: Space.medium),
  //       ),
  //       border: Border.all(color: Colors.grey.shade200),
  //     ),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceAround,
  //       children: [
  //         _buildStatItem(
  //           icon: Icons.library_books,
  //           label: 'المواد',
  //           value: '$totalMaterials',
  //           color: Colors.blue,
  //         ),
  //         _buildStatItem(
  //           icon: Icons.star,
  //           label: 'التقييمات',
  //           value: '$totalRatings',
  //           color: Colors.amber,
  //         ),
  //         _buildStatItem(
  //           icon: Icons.star_rate,
  //           label: 'المتوسط',
  //           value: avgRating.toStringAsFixed(1),
  //           color: Colors.green,
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildFilterChips(MaterialLinksProvider provider) {
    final typeCounts = provider.typeCounts;
    if (typeCounts.isEmpty) return const SizedBox.shrink();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: 50,
        margin: EdgeInsets.symmetric(
          horizontal: Responsive.space(context, size: Space.small),
          vertical: Responsive.space(context, size: Space.tiny),
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: typeCounts.length + 1, // +1 for "All" option
          itemBuilder: (context, index) {
            if (index == 0) {
              // "All" option
              final isSelected = provider.selectedType == null;
              return _buildFilterChip(
                'الكل',
                null,
                isSelected,
                provider.materialLinks.length,
              );
            } else {
              final type = typeCounts.keys.elementAt(index - 1);
              final count = typeCounts[type]!;
              final isSelected = provider.selectedType == type;
              return _buildFilterChip(
                _getTypeDisplayName(type),
                type,
                isSelected,
                count,
              );
            }
          },
        ),
      ),
    );
  }

  String _getTypeDisplayName(MaterialType type) {
    switch (type) {
      case MaterialType.video:
        return 'Video';
      case MaterialType.pdf:
        return 'PDF Document';
      case MaterialType.document:
        return 'Document';
      case MaterialType.image:
        return 'Image';
      case MaterialType.link:
        return 'Link';
    }
  }

  Widget _buildFilterChip(
    String label,
    MaterialType? type,
    bool isSelected,
    int count,
  ) {
    return Container(
      margin: EdgeInsets.only(
        right: Responsive.space(context, size: Space.small),
      ),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (type != null) ...[
              Icon(
                _getMaterialTypeIcon(type),
                size: 16,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
              SizedBox(width: 4),
            ],
            Text('$label ($count)'),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          HapticService().selectionClick();
          context.read<MaterialLinksProvider>().setSelectedType(
            selected ? type : null,
          );
        },
        backgroundColor: Colors.grey.shade100,
        selectedColor: Colors.black,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontSize: Responsive.text(context, size: TextSize.small),
        ),
        elevation: isSelected ? 2 : 0,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            'لا توجد مواد متاحة',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: Responsive.text(context, size: TextSize.medium),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'اضغط على زر الإضافة لإنشاء مادة جديدة',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: Responsive.text(context, size: TextSize.small),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    final canEdit = widget.loggedInUser?.role != 'Student';

    if (!canEdit) return const SizedBox.shrink();

    return FloatingActionButton(
      heroTag: 'material_links_fab',
      onPressed: _showAddMaterialDialog,
      backgroundColor: Colors.black,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  void _deleteMaterial(MaterialLink materialLink) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('حذف المحتوى'),
            content: const Text('هل أنت متأكد من رغبتك في حذف هذا المحتوى؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('حذف'),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      try {
        final provider = context.read<MaterialLinksProvider>();
        await provider.deleteMaterialLink(widget.lecture.id, materialLink);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف المحتوى بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل في حذف المحتوى: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _rateMaterial(MaterialLink materialLink, double rating) async {
    debugPrint(
      'MaterialLinksScreen: Rating material: ${materialLink.title} with rating: $rating',
    );
    debugPrint(
      'MaterialLinksScreen: Logged in user: ${widget.loggedInUser?.id}',
    );

    if (widget.loggedInUser == null) {
      debugPrint('MaterialLinksScreen: No logged in user');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب تسجيل الدخول لتقييم المواد'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      debugPrint('MaterialLinksScreen: Calling provider.rateMaterial');
      final provider = context.read<MaterialLinksProvider>();
      await provider.rateMaterial(
        widget.lecture.id,
        materialLink,
        widget.loggedInUser!.id,
        rating,
      );

      debugPrint('MaterialLinksScreen: Rating successful');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تقييم المحتوى: ${rating.toInt()} نجوم'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('MaterialLinksScreen: Rating failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في تقييم المادة: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: EdgeInsets.all(Responsive.space(context, size: Space.small)),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.only(
            bottom: Responsive.space(context, size: Space.small),
          ),
          child: Column(
            children: [
              Container(
                height: Responsive.height(context) * 0.25,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(
                      Responsive.space(context, size: Space.medium),
                    ),
                    topRight: Radius.circular(
                      Responsive.space(context, size: Space.medium),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(
                  Responsive.space(context, size: Space.small),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 20,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      height: 16,
                      width: MediaQuery.of(context).size.width * 0.6,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
