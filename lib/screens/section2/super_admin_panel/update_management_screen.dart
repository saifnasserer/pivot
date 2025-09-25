import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/services/remote_config_service.dart';
import 'package:pivot/services/remote_config_bridge_service.dart';
import 'package:pivot/services/update_service.dart';
import 'package:pivot/widgets/custom_text_field.dart';

class UpdateManagementScreen extends StatefulWidget {
  const UpdateManagementScreen({super.key});

  @override
  State<UpdateManagementScreen> createState() => _UpdateManagementScreenState();
}

class _UpdateManagementScreenState extends State<UpdateManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _downloadUrlController = TextEditingController();
  final _versionController = TextEditingController();
  final _changelogController = TextEditingController();

  bool _isUpdateForce = false;
  bool _showUpdateButton = false;
  bool _showTeamFormationButton = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print('🔧 [UpdateManagement] initState called');
    _loadCurrentSettings();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _downloadUrlController.dispose();
    _versionController.dispose();
    _changelogController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentSettings() async {
    setState(() => _isLoading = true);

    try {
      final bridgeService = RemoteConfigBridgeService();
      final firestoreData = await bridgeService.loadSettings();

      if (firestoreData != null) {
        print('📄 [UpdateManagement] Loading settings from Firestore');
        print('📄 [UpdateManagement] Firestore data: $firestoreData');

        _titleController.text = firestoreData['app_update_title'] ?? '';
        _messageController.text = firestoreData['app_update_message'] ?? '';
        _downloadUrlController.text =
            firestoreData['app_update_download_url'] ?? '';
        _versionController.text = firestoreData['app_update_version'] ?? '';
        _changelogController.text = firestoreData['app_update_changelog'] ?? '';
        _isUpdateForce = firestoreData['app_update_force'] ?? false;
        _showUpdateButton = firestoreData['show_update_button'] ?? false;
        _showTeamFormationButton =
            firestoreData['show_team_formation_button'] ?? false;
      }

      print('📄 [UpdateManagement] Loaded values:');
      print('  - Title: "${_titleController.text}"');
      print('  - Message: "${_messageController.text}"');
      print('  - Version: "${_versionController.text}"');
      print('  - Download URL: "${_downloadUrlController.text}"');
      print('  - Changelog: "${_changelogController.text}"');
      print('  - Update Force: $_isUpdateForce');
      print('  - Show Update Button: $_showUpdateButton');
      print('  - Show Team Formation Button: $_showTeamFormationButton');

      setState(() {});
    } catch (e) {
      print('❌ [UpdateManagement] Error loading settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحميل الإعدادات: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    print('🔧 [UpdateManagement] Save settings button pressed');

    if (!_formKey.currentState!.validate()) {
      print('❌ [UpdateManagement] Form validation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تصحيح الأخطاء في النموذج'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('✅ [UpdateManagement] Form validation passed, starting save...');
    setState(() => _isLoading = true);

    try {
      final settings = {
        'app_update_force': _isUpdateForce,
        'app_update_message': _messageController.text.trim(),
        'app_update_title': _titleController.text.trim(),
        'app_update_download_url': _downloadUrlController.text.trim(),
        'app_update_version': _versionController.text.trim(),
        'app_update_changelog': _changelogController.text.trim(),
        'show_update_button': _showUpdateButton,
        'show_team_formation_button': _showTeamFormationButton,
      };

      print('🔧 [UpdateManagement] Saving settings: $settings');

      final bridgeService = RemoteConfigBridgeService();
      final success = await bridgeService.saveSettings(settings);

      if (success) {
        final syncSuccess = await bridgeService.forceSync();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              syncSuccess
                  ? 'تم حفظ الإعدادات ومزامنتها مع Remote Config بنجاح'
                  : 'تم الحفظ ولكن فشل في المزامنة مع Remote Config',
            ),
            backgroundColor: syncSuccess ? Colors.green : Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل في حفظ الإعدادات'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في حفظ الإعدادات: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testUpdateService() async {
    try {
      print('🧪 [UpdateManagement] Testing Update Service...');

      final updateService = UpdateService();
      final updatesAvailable = await updateService.areUpdatesAvailable();
      final shouldShowButton = updateService.shouldShowUpdateButton();

      print('🧪 [UpdateManagement] Updates Available: $updatesAvailable');
      print(
        '🧪 [UpdateManagement] Should Show Update Button: $shouldShowButton',
      );

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Update Service Test Results'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Updates Available: $updatesAvailable'),
                  SizedBox(
                    height: Responsive.space(context, size: Space.small),
                  ),
                  Text('Should Show Update Button: $shouldShowButton'),
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),
                  const Text(
                    'This tests the actual UpdateService that the app uses to check for updates.',
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
      );
    } catch (e) {
      print('❌ [UpdateManagement] Error testing Update Service: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في اختبار خدمة التحديث: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _debugRemoteConfig() async {
    try {
      print('🐛 [UpdateManagement] Starting Remote Config debug...');

      final remoteConfig = RemoteConfigService.instance;
      final bridgeService = RemoteConfigBridgeService();

      final syncStatus = await bridgeService.getSyncStatus();
      final remoteConfigValues = bridgeService.getCurrentRemoteConfigValues();
      final currentVersion = await remoteConfig.getCurrentAppVersion();
      final isUpdateNeeded = await remoteConfig.isAppUpdateNeeded();

      print('🐛 [UpdateManagement] Sync Status: $syncStatus');
      print('🐛 [UpdateManagement] Remote Config Values: $remoteConfigValues');
      print('🐛 [UpdateManagement] Current App Version: $currentVersion');
      print('🐛 [UpdateManagement] Update Needed: $isUpdateNeeded');

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Remote Config Debug Info'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Current App Version: $currentVersion'),
                    SizedBox(
                      height: Responsive.space(context, size: Space.small),
                    ),
                    Text('Update Force: ${remoteConfig.isUpdateForce}'),
                    Text('Update Needed: $isUpdateNeeded'),
                    SizedBox(
                      height: Responsive.space(context, size: Space.small),
                    ),
                    Text('Update Title: ${remoteConfig.updateTitle}'),
                    Text('Update Version: ${remoteConfig.updateVersion}'),
                    SizedBox(
                      height: Responsive.space(context, size: Space.small),
                    ),
                    Text(
                      'Firestore Has Data: ${syncStatus['firestore_has_data']}',
                    ),
                    Text('Synced: ${syncStatus['synced']}'),
                    SizedBox(
                      height: Responsive.space(context, size: Space.small),
                    ),
                    const Text('Remote Config Values:'),
                    ...remoteConfigValues.entries.map(
                      (entry) => Text('  ${entry.key}: ${entry.value}'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
      );
    } catch (e) {
      print('❌ [UpdateManagement] Error debugging Remote Config: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تصحيح Remote Config: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'إدارة التحديثات',
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.heading),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            Responsive.space(context, size: Space.tiny),
          ),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey[300]!,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading ? _buildLoadingState() : _buildMainContent(),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: Responsive.padding(context, size: Space.medium),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue[600]!,
                    ),
                  ),
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),
                  Text(
                    'جاري تحميل الإعدادات...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: Responsive.text(context, size: TextSize.medium),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F9FA), Colors.white],
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: Responsive.padding(context, size: Space.medium),
            child: Column(
              children: [
                _buildSettingsSection(),

                SizedBox(height: Responsive.space(context, size: Space.large)),

                // Update Details Section
                _buildUpdateDetailsSection(),

                SizedBox(height: Responsive.space(context, size: Space.large)),

                // Version Info Section
                _buildVersionInfoSection(),

                SizedBox(height: Responsive.space(context, size: Space.xlarge)),

                // Save Button
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      padding: Responsive.padding(context, size: Space.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings,
                color: Colors.grey[700],
                size: Responsive.text(context, size: TextSize.heading),
              ),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Text(
                'إعدادات عامة',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.heading),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),
          _buildEnhancedSwitchTile(
            title: 'إظهار زر التحديث',
            subtitle: 'إظهار زر التحديث في القائمة السريعة',
            value: _showUpdateButton,
            onChanged: (value) => setState(() => _showUpdateButton = value),
            activeColor: Colors.blue[600]!,
            icon: Icons.system_update,
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),
          _buildEnhancedSwitchTile(
            title: 'إظهار زر تكوين الفريق',
            subtitle: 'إظهار زر تكوين الفريق في القائمة السريعة',
            value: _showTeamFormationButton,
            onChanged:
                (value) => setState(() => _showTeamFormationButton = value),
            activeColor: Colors.green[600]!,
            icon: Icons.group_add,
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateDetailsSection() {
    return Container(
      padding: Responsive.padding(context, size: Space.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit,
                color: Colors.blue[600],
                size: Responsive.text(context, size: TextSize.heading),
              ),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Text(
                'تفاصيل التحديث',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.heading),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildEnhancedTextField(
            controller: _titleController,
            hint: 'عنوان رسالة التحديث',
            icon: Icons.title,
            validator: (value) {
              if (_showUpdateButton &&
                  (value == null || value.trim().isEmpty)) {
                return 'يرجى إدخال عنوان رسالة التحديث';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildEnhancedTextField(
            controller: _messageController,
            hint: 'رسالة التحديث',
            icon: Icons.message,
            maxLines: 3,
            validator: (value) {
              if (_showUpdateButton &&
                  (value == null || value.trim().isEmpty)) {
                return 'يرجى إدخال رسالة التحديث';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildEnhancedTextField(
            controller: _changelogController,
            hint: 'ملاحظات التحديث (التحديثات الجديدة)',
            icon: Icons.notes,
            maxLines: 4,
            validator: (value) {
              if (_showUpdateButton &&
                  (value == null || value.trim().isEmpty)) {
                return 'يرجى إدخال ملاحظات التحديث';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVersionInfoSection() {
    return Container(
      padding: Responsive.padding(context, size: Space.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info,
                color: Colors.green[600],
                size: Responsive.text(context, size: TextSize.heading),
              ),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Text(
                'معلومات الإصدار',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.heading),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildEnhancedTextField(
            controller: _versionController,
            hint: 'رقم الإصدار المطلوب (مثال: 1.2.0)',
            icon: Icons.tag,
            validator: (value) {
              if (_showUpdateButton &&
                  (value == null || value.trim().isEmpty)) {
                return 'يرجى إدخال رقم الإصدار';
              }
              if (_showUpdateButton &&
                  value != null &&
                  value.trim().isNotEmpty &&
                  !RegExp(r'^\d+\.\d+\.\d+$').hasMatch(value.trim())) {
                return 'يرجى إدخال رقم إصدار صحيح (مثال: 1.2.0)';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildEnhancedTextField(
            controller: _downloadUrlController,
            hint: 'رابط تحميل التحديث',
            icon: Icons.link,
            validator: (value) {
              if (_showUpdateButton &&
                  (value == null || value.trim().isEmpty)) {
                return 'يرجى إدخال رابط التحميل';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: Responsive.space(context, size: Space.xlarge) * 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[500]!, Colors.green[600]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: Responsive.space(context, size: Space.medium),
            offset: Offset(0, Responsive.space(context, size: Space.medium)),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _saveSettings,
        icon:
            _isLoading
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : const Icon(Icons.save, size: 24),
        label: Text(
          _isLoading ? 'جاري الحفظ...' : 'حفظ الإعدادات',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: value ? activeColor.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? activeColor.withOpacity(0.3) : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value ? activeColor.withOpacity(0.1) : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: value ? activeColor : Colors.grey[600],
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.small),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: activeColor,
            activeTrackColor: activeColor.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }
}
