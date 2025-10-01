import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/settings/providers/settings_provider.dart';
import 'package:pivot/responsive.dart';

class SectionManagementScreen extends ConsumerStatefulWidget {
  // = 'section_management_screen';

  const SectionManagementScreen({super.key});

  @override
  ConsumerState<SectionManagementScreen> createState() =>
      _SectionManagementScreenState();
}

class _SectionManagementScreenState
    extends ConsumerState<SectionManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  bool _isSaving = false;
  bool _isInitialized = false;

  final Map<String, String> _departmentDisplayNames = const {
    'CS': 'CS',
    'IS': 'IS',
    'AI': 'AI',
    'SC': 'SC',
    'General': 'General',
  };

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (var deptKey in _departmentDisplayNames.keys)
        deptKey: TextEditingController(),
    };
    // Fetch data after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsProvider.notifier).fetchSectionCounts();
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final newCounts = <String, int>{};
      _controllers.forEach((dept, controller) {
        newCounts[dept] = int.tryParse(controller.text) ?? 8;
      });

      try {
        await ref
            .read(settingsProvider.notifier)
            .updateSectionCounts(newCounts);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم حفظ إعدادات السكاشن بنجاح'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ أثناء الحفظ: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);

    // Populate controllers only once after data is loaded
    if (!settingsState.isLoading &&
        !_isInitialized &&
        settingsState.sectionCounts.isNotEmpty) {
      for (var key in _departmentDisplayNames.keys) {
        final count = settingsState.sectionCounts[key] ?? 8;
        _controllers[key]?.text = count.toString();
      }
      // Use a post frame callback to avoid calling setState during a build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isInitialized = true);
      });
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'إدارة السكاشن',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.heading),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Builder(
          builder: (context) {
            // Show loading indicator until controllers are initialized
            if (!_isInitialized) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.black),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    Text(
                      'جاري تحميل إعدادات السكاشن...',
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
              );
            }

            // Main UI
            return Form(
              key: _formKey,
              child: Column(
                children: [
                  // Departments List
                  Expanded(
                    child: ListView(
                      padding: Responsive.padding(context, size: Space.large),
                      children:
                          _departmentDisplayNames.entries.map((entry) {
                            final deptKey = entry.key;
                            final deptName = entry.value;

                            return Container(
                              margin: EdgeInsets.only(
                                bottom: Responsive.space(
                                  context,
                                  size: Space.medium,
                                ),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: Responsive.padding(
                                  context,
                                  size: Space.large,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Department Header
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'قسم $deptName',
                                          style: TextStyle(
                                            fontSize: Responsive.text(
                                              context,
                                              size: TextSize.medium,
                                            ),
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          'عدد السكاشن المطلوبة',
                                          style: TextStyle(
                                            fontSize: Responsive.text(
                                              context,
                                              size: TextSize.small,
                                            ),
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(
                                      height: Responsive.space(
                                        context,
                                        size: Space.medium,
                                      ),
                                    ),

                                    // Section Count Input
                                    TextFormField(
                                      controller: _controllers[deptKey],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        labelText: 'عدد السكاشن',
                                        hintText: 'أدخل العدد المطلوب',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                        prefixIcon: Icon(
                                          Icons.numbers,
                                          color: Colors.black87,
                                        ),
                                        suffixText: 'سكاشن',
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'مطلوب إدخال عدد السكاشن';
                                        }
                                        if (int.tryParse(value) == null) {
                                          return 'يجب إدخال رقم صحيح';
                                        }
                                        final count = int.parse(value);
                                        if (count < 1) {
                                          return 'يجب أن يكون العدد أكبر من صفر';
                                        }
                                        if (count > 50) {
                                          return 'يجب أن يكون العدد أقل من 50';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),

                  // Save Button
                  Container(
                    padding: Responsive.padding(context, size: Space.large),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton.icon(
                        onPressed: _isSaving ? null : _saveSettings,
                        icon:
                            _isSaving
                                ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : Icon(Icons.save, color: Colors.white),
                        label: Text(
                          _isSaving ? 'جاري الحفظ...' : 'حفظ إعدادات السكاشن',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: Responsive.space(
                              context,
                              size: Space.medium,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
