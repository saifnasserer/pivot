import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/administration/providers/sections_provider.dart';
import 'package:pivot/features/media/services/materials_service.dart';
import 'package:pivot/models/material_link.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/responsive.dart';

class MaterialSelectionFeature {
  /// Show materials selection dialog
  Future<void> showMaterialsSelectionDialog(
    BuildContext context, {
    required String? selectedSubjectId,
    required String? selectedSectionId,
    required List<String> alreadySelectedUrls,
    required Function(List<MaterialLink>) onMaterialsSelected,
    required WidgetRef ref,
  }) async {
    if (kDebugMode) {
      print('🎯 [MaterialSelectionFeature] Materials selection button pressed');
      print('   Selected Subject ID: $selectedSubjectId');
      print('   Selected Section ID: $selectedSectionId');
    }

    if (selectedSubjectId == null || selectedSectionId == null) {
      if (kDebugMode) {
        print('   ❌ Missing subject or section ID');
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى اختيار المادة والسكشن أولاً'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Get section to find assistant ID
    final sectionsState = ref.read(sectionsProvider);
    if (kDebugMode) {
      print('   📋 Total sections available: ${sectionsState.sections.length}');
    }

    // Safe section lookup without throwing exception
    Section? section;
    try {
      section = sectionsState.sections.firstWhere(
        (s) => s.id == selectedSectionId,
      );
    } catch (e) {
      section = null;
    }

    if (section == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('السكشن المحدد غير موجود'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (kDebugMode) {
      print('   ✅ Found section: ${section.name}');
      print('   👤 Assistant ID: ${section.assistantId}');
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Center(
            child: Card(
              child: Padding(
                padding: Responsive.padding(context, size: Space.large),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.black),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    Text('جاري تحميل المواد...'),
                  ],
                ),
              ),
            ),
          ),
    );

    try {
      if (kDebugMode) {
        print('   🔄 Starting to load materials...');
      }

      // Use service directly to avoid AutoDispose issues
      final materialsService = MaterialsService();
      final availableMaterials = await materialsService
          .getMaterialsBySubjectAndAssistant(
            selectedSubjectId,
            section.assistantId,
          );

      if (kDebugMode) {
        print('   ✅ Materials loaded successfully');
      }

      if (!context.mounted) {
        if (kDebugMode) {
          print('   ⚠️ Widget not mounted, aborting');
        }
        Navigator.of(context).pop(); // Close loading
        return;
      }

      if (kDebugMode) {
        print('   📚 Available materials count: ${availableMaterials.length}');
        for (var i = 0; i < availableMaterials.length; i++) {
          print(
            '      [$i] ${availableMaterials[i].displayTitle} (${availableMaterials[i].type.name})',
          );
        }
      }

      // Close loading indicator
      Navigator.of(context).pop();

      if (!context.mounted) return;

      if (availableMaterials.isEmpty) {
        if (kDebugMode) {
          print('   ⚠️ No materials available, showing warning');
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لا توجد مواد متاحة لهذا السكشن'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (kDebugMode) {
        print('   📖 Opening material selection dialog...');
      }

      // Show selection dialog
      final selected = await showDialog<List<MaterialLink>>(
        context: context,
        builder:
            (context) => _MaterialSelectionDialog(
              materials: availableMaterials,
              alreadySelected: alreadySelectedUrls,
            ),
      );

      if (selected != null && selected.isNotEmpty && context.mounted) {
        if (kDebugMode) {
          print('   ✅ User selected ${selected.length} material(s):');
          for (var material in selected) {
            print('      - ${material.displayTitle}');
          }
        }

        onMaterialsSelected(selected);

        if (kDebugMode) {
          print('   📊 Materials selected successfully');
        }
      } else {
        if (kDebugMode) {
          print('   ❌ No materials selected or dialog cancelled');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('   ❌ ERROR in material selection: $e');
        print('   Stack trace: ${StackTrace.current}');
      }

      // Close loading indicator if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في تحميل المواد: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Material Selection Dialog
class _MaterialSelectionDialog extends StatefulWidget {
  final List<MaterialLink> materials;
  final List<String> alreadySelected;

  const _MaterialSelectionDialog({
    required this.materials,
    required this.alreadySelected,
  });

  @override
  State<_MaterialSelectionDialog> createState() =>
      _MaterialSelectionDialogState();
}

class _MaterialSelectionDialogState extends State<_MaterialSelectionDialog> {
  final Set<String> _selectedUrls = {};

  @override
  void initState() {
    super.initState();
    _selectedUrls.addAll(widget.alreadySelected);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.large),
          ),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: Responsive.width(context) * 0.9,
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: Responsive.padding(context, size: Space.medium),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(
                      Responsive.space(context, size: Space.large),
                    ),
                    topRight: Radius.circular(
                      Responsive.space(context, size: Space.large),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.library_books, color: Colors.blue.shade700),
                    SizedBox(
                      width: Responsive.space(context, size: Space.small),
                    ),
                    Expanded(
                      child: Text(
                        'اختار المرفقات ',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.heading,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Materials List
              Expanded(
                child: ListView.builder(
                  padding: Responsive.padding(context, size: Space.medium),
                  itemCount: widget.materials.length,
                  itemBuilder: (context, index) {
                    final material = widget.materials[index];
                    final isSelected = _selectedUrls.contains(material.url);

                    return Card(
                      margin: EdgeInsets.only(
                        bottom: Responsive.space(context, size: Space.small),
                      ),
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedUrls.add(material.url);
                            } else {
                              _selectedUrls.remove(material.url);
                            }
                          });
                        },
                        title: Text(
                          material.displayTitle,
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle:
                            material.description != null
                                ? Text(
                                  material.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: Responsive.text(
                                      context,
                                      size: TextSize.small,
                                    ),
                                  ),
                                )
                                : null,
                        secondary: Icon(
                          material.typeIcon,
                          color: Colors.blue.shade600,
                        ),
                        activeColor: Colors.blue,
                      ),
                    );
                  },
                ),
              ),

              // Action Buttons
              Container(
                padding: Responsive.padding(context, size: Space.medium),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('إلغاء'),
                      ),
                    ),
                    SizedBox(
                      width: Responsive.space(context, size: Space.small),
                    ),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final selected =
                              widget.materials
                                  .where((m) => _selectedUrls.contains(m.url))
                                  .toList();
                          Navigator.of(context).pop(selected);
                        },
                        icon: Icon(Icons.check),
                        label: Text('إضافة (${_selectedUrls.length})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: Responsive.space(
                              context,
                              size: Space.medium,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
