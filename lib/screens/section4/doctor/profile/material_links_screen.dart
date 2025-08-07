import 'package:flutter/material.dart' hide MaterialType;
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
    final Uri? url = Uri.tryParse(urlString);
    if (url != null && await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر فتح الرابط: $urlString')));
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
            content: Text('تم إضافة المادة بنجاح'),
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
        IconButton(
          icon: const Icon(Icons.filter_list, color: Colors.black),
          onPressed: _showFilterDialog,
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
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('جاري تحميل المواد...'),
                    ],
                  ),
                );
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
      child: Row(
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
    );
  }

  Widget _buildFilterChips(MaterialLinksProvider provider) {
    final typeCounts = provider.typeCounts;
    if (typeCounts.isEmpty) return const SizedBox.shrink();

    return Container(
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
        label: Text('$label ($count)'),
        selected: isSelected,
        onSelected: (selected) {
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
      onPressed: _showAddMaterialDialog,
      backgroundColor: Colors.black,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  void _showFilterDialog() {
    // TODO: Implement advanced filter dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم إضافة خيارات التصفية المتقدمة قريباً'),
      ),
    );
  }

  void _deleteMaterial(MaterialLink materialLink) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('حذف المادة'),
            content: const Text('هل أنت متأكد من رغبتك في حذف هذه المادة؟'),
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
              content: Text('تم حذف المادة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل في حذف المادة: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _rateMaterial(MaterialLink materialLink, double rating) async {
    if (widget.loggedInUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب تسجيل الدخول لتقييم المواد'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final provider = context.read<MaterialLinksProvider>();
      await provider.rateMaterial(
        widget.lecture.id,
        materialLink,
        widget.loggedInUser!.id,
        rating,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تقييم المادة: ${rating.toInt()} نجوم'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
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
}
