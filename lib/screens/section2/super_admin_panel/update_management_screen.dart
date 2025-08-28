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

class _UpdateManagementScreenState extends State<UpdateManagementScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _downloadUrlController = TextEditingController();
  final _versionController = TextEditingController();
  final _changelogController = TextEditingController();
  final _maintenanceMessageController = TextEditingController();

  bool _isUpdateForce = false;
  bool _showUpdateButton = false;
  bool _isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    print('🔧 [UpdateManagement] initState called');
    _loadCurrentSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      }

      print('📄 [UpdateManagement] Loaded values:');
      print('  - Title: "${_titleController.text}"');
      print('  - Message: "${_messageController.text}"');
      print('  - Version: "${_versionController.text}"');
      print('  - Download URL: "${_downloadUrlController.text}"');
      print('  - Changelog: "${_changelogController.text}"');
      print('  - Update Force: $_isUpdateForce');
      print('  - Show Update Button: $_showUpdateButton');

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
                  const SizedBox(height: 8),
                  Text('Should Show Update Button: $shouldShowButton'),
                  const SizedBox(height: 16),
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
                    const SizedBox(height: 8),
                    Text('Update Force: ${remoteConfig.isUpdateForce}'),
                    Text('Update Needed: $isUpdateNeeded'),
                    const SizedBox(height: 8),
                    Text('Update Title: ${remoteConfig.updateTitle}'),
                    Text('Update Version: ${remoteConfig.updateVersion}'),
                    const SizedBox(height: 8),
                    Text(
                      'Firestore Has Data: ${syncStatus['firestore_has_data']}',
                    ),
                    Text('Synced: ${syncStatus['synced']}'),
                    const SizedBox(height: 8),
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

  Future<void> _testRemoteConfigSync() async {
    try {
      print('🧪 [UpdateManagement] Testing Remote Config sync...');

      // Step 1: Check current Firestore values
      final bridgeService = RemoteConfigBridgeService();
      final firestoreData = await bridgeService.loadSettings();
      print('🧪 [UpdateManagement] Firestore data: $firestoreData');

      // Step 2: Check current Remote Config values
      final remoteConfig = RemoteConfigService.instance;
      final currentShowUpdateButton = remoteConfig.showUpdateButton;
      print(
        '🧪 [UpdateManagement] Current Remote Config showUpdateButton: $currentShowUpdateButton',
      );

      // Step 3: Force sync from Firestore to Remote Config
      print('🧪 [UpdateManagement] Force syncing...');
      final syncSuccess = await bridgeService.forceSync();
      print('🧪 [UpdateManagement] Sync success: $syncSuccess');

      // Step 4: Check Remote Config values after sync
      final afterSyncShowUpdateButton = remoteConfig.showUpdateButton;
      print(
        '🧪 [UpdateManagement] After sync - showUpdateButton: $afterSyncShowUpdateButton',
      );

      // Step 5: Test UpdateService
      final updateService = UpdateService();
      final shouldShow = updateService.shouldShowUpdateButton();
      print(
        '🧪 [UpdateManagement] UpdateService.shouldShowUpdateButton(): $shouldShow',
      );

      // Step 6: Force refresh Remote Config
      print('🧪 [UpdateManagement] Force refreshing Remote Config...');
      await updateService.forceRefreshRemoteConfig();

      // Step 7: Check final values
      final finalShowUpdateButton = remoteConfig.showUpdateButton;
      final finalShouldShow = updateService.shouldShowUpdateButton();
      print('🧪 [UpdateManagement] Final values:');
      print('  - Remote Config showUpdateButton: $finalShowUpdateButton');
      print('  - UpdateService shouldShowUpdateButton: $finalShouldShow');

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Remote Config Sync Test Results'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Firestore showUpdateButton: ${firestoreData?['show_update_button']}',
                    ),
                    const SizedBox(height: 8),
                    Text('Before sync: $currentShowUpdateButton'),
                    Text('After sync: $afterSyncShowUpdateButton'),
                    Text('After refresh: $finalShowUpdateButton'),
                    const SizedBox(height: 8),
                    Text(
                      'UpdateService.shouldShowUpdateButton(): $finalShouldShow',
                    ),
                    const SizedBox(height: 8),
                    Text('Sync success: $syncSuccess'),
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
      print('❌ [UpdateManagement] Error testing Remote Config sync: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في اختبار مزامنة Remote Config: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
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
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.refresh, color: Colors.blue[600]),
                onPressed: () async {
                  print('�� [UpdateManagement] Manual refresh requested');
                  await _loadCurrentSettings();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تحديث الإعدادات'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                tooltip: 'تحديث الإعدادات من Firestore',
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.sync, color: Colors.green[600]),
                onPressed: () async {
                  print('🔄 [UpdateManagement] Manual sync requested');
                  final bridgeService = RemoteConfigBridgeService();
                  final success = await bridgeService.forceSync();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? 'تم المزامنة بنجاح' : 'فشل في المزامنة',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                tooltip: 'مزامنة مع Remote Config',
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.bug_report, color: Colors.orange[600]),
                onPressed: () async {
                  print('🐛 [UpdateManagement] Debug Remote Config requested');
                  await _debugRemoteConfig();
                },
                tooltip: 'تصحيح Remote Config',
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.science, color: Colors.purple[600]),
                onPressed: () async {
                  print(
                    '🧪 [UpdateManagement] Remote Config sync test requested',
                  );
                  await _testRemoteConfigSync();
                },
                tooltip: 'اختبار مزامنة Remote Config',
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.refresh, color: Colors.purple[600]),
                onPressed: () async {
                  print(
                    '🔄 [UpdateManagement] Force refresh Remote Config requested',
                  );
                  await UpdateService().forceRefreshRemoteConfig();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تحديث Remote Config'),
                      backgroundColor: Colors.purple,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                tooltip: 'تحديث Remote Config',
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
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
        body:
            _isLoading
                ? Container(
                  color: const Color(0xFFF8F9FA),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
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
                              const SizedBox(height: 16),
                              Text(
                                'جاري تحميل الإعدادات...',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.medium,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                : Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFF8F9FA), Colors.white],
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Action Buttons at Top
                        _buildActionButtons(),

                        // Tabs
                        Container(
                          margin: const EdgeInsets.all(16),
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
                              TabBar(
                                controller: _tabController,
                                labelColor: Colors.white,
                                unselectedLabelColor: Colors.grey[600],
                                indicator: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue[600]!,
                                      Colors.blue[700]!,
                                    ],
                                  ),
                                ),
                                tabs: const [
                                  Tab(text: 'التحديثات'),
                                  Tab(text: 'الصيانة'),
                                ],
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.6,
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [_buildUpdateTab()],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: Responsive.padding(context, size: Space.large),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[500]!, Colors.green[600]!],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _testUpdateService,
                icon: const Icon(Icons.play_arrow, size: 20),
                label: const Text(
                  'اختبار خدمة التحديث',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[500]!, Colors.blue[600]!],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveSettings,
                icon:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Icon(Icons.save, size: 20),
                label: Text(
                  _isLoading ? 'جاري الحفظ...' : 'حفظ الإعدادات',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateTab() {
    return SingleChildScrollView(
      padding: Responsive.padding(context, size: Space.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Update Button Toggle
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: _buildEnhancedSwitchTile(
              title: 'إظهار زر التحديث',
              subtitle: 'إظهار زر التحديث في القائمة السريعة',
              value: _showUpdateButton,
              onChanged: (value) => setState(() => _showUpdateButton = value),
              activeColor: Colors.blue[600]!,
              icon: Icons.system_update,
            ),
          ),

          const SizedBox(height: 24),

          // Force Update Toggle
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: _buildEnhancedSwitchTile(
              title: 'تحديث إجباري',
              subtitle: 'إجبار المستخدمين على التحديث',
              value: _isUpdateForce,
              onChanged: (value) => setState(() => _isUpdateForce = value),
              activeColor: Colors.red[600]!,
              icon: Icons.block,
            ),
          ),

          const SizedBox(height: 24),

          // Update Details Form
          _buildFormSection(
            title: 'تفاصيل التحديث',
            icon: Icons.edit,
            children: [
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
            ],
          ),

          const SizedBox(height: 20),

          _buildFormSection(
            title: 'معلومات الإصدار',
            icon: Icons.info,
            children: [
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
        ],
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
            activeColor: activeColor,
            activeTrackColor: activeColor.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey[700], size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
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
        color: Colors.white,
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
