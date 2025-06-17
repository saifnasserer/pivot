import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pivot/providers/settings_provider.dart';
import 'package:pivot/responsive.dart';

class SectionManagementScreen extends StatefulWidget {
  static const String id = 'section_management_screen';

  const SectionManagementScreen({super.key});

  @override
  State<SectionManagementScreen> createState() =>
      _SectionManagementScreenState();
}

class _SectionManagementScreenState extends State<SectionManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> _controllers;
  bool _isLoading = false;

  final Map<String, String> _departmentDisplayNames = const {
    'CS': 'CS',
    'IS': 'IS',
    'AI': 'AI',
    'SC': 'SC',
    'General': 'عام',
  };

  @override
  void initState() {
    super.initState();
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    _controllers = {
      for (var deptKey in _departmentDisplayNames.keys)
        deptKey: TextEditingController(
          text: (settingsProvider.sectionCounts[deptKey] ?? 8).toString(),
        ),
    };
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  IconData _getDeptIcon(String deptKey) {
    switch (deptKey) {
      case 'CS':
        return Icons.computer;
      case 'IS':
        return Icons.info_outline;
      case 'AI':
        return Icons.psychology;
      case 'SC':
        return Icons.science_outlined;
      case 'General':
      default:
        return Icons.school;
    }
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final newCounts = <String, int>{};
      _controllers.forEach((dept, controller) {
        newCounts[dept] = int.tryParse(controller.text) ?? 8;
      });

      try {
        await Provider.of<SettingsProvider>(
          context,
          listen: false,
        ).updateSectionCounts(newCounts);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حفظ الإعدادات بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ أثناء الحفظ: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إدارة السكاشن'), centerTitle: true),
        body: Consumer<SettingsProvider>(
          builder: (context, settingsProvider, child) {
            if (settingsProvider.isLoading && _controllers.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            return Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16.0),
                      children:
                          _departmentDisplayNames.entries.map((entry) {
                            final deptKey = entry.key;
                            final deptName = entry.value;
                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                  horizontal: 16.0,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _getDeptIcon(deptKey),
                                      size: 30,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        'قسم $deptName',
                                        style: TextStyle(
                                          fontSize: Responsive.text(
                                            context,
                                            size: TextSize.medium,
                                          ),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 80,
                                      child: TextFormField(
                                        controller: _controllers[deptKey],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        decoration: InputDecoration(
                                          labelText: 'العدد',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 8,
                                              ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty)
                                            return 'مطلوب';
                                          if (int.tryParse(value) == null)
                                            return 'رقم غير صالح';
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveSettings,
                      icon: _isLoading ? Container() : const Icon(Icons.save),
                      label:
                          _isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text('حفظ التغييرات'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        textStyle: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
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
