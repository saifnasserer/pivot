import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/services/remote_config_service.dart';
import 'package:pivot/services/update_service.dart';
import 'package:pivot/widgets/custom_text_field.dart';
import 'package:pivot/widgets/custom_dropdown.dart';

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
  final _maintenanceMessageController = TextEditingController();

  bool _isUpdateRequired = false;
  bool _isUpdateForce = false;
  bool _isMaintenanceMode = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _downloadUrlController.dispose();
    _versionController.dispose();
    _changelogController.dispose();
    _maintenanceMessageController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentSettings() async {
    setState(() => _isLoading = true);

    try {
      // First try to load from Firestore (most recent)
      final firestoreDoc =
          await FirebaseFirestore.instance
              .collection('settings')
              .doc('update_management')
              .get();

      if (firestoreDoc.exists) {
        final data = firestoreDoc.data()!;
        print('📄 [UpdateManagement] Loading settings from Firestore');

        _titleController.text = data['app_update_title'] ?? '';
        _messageController.text = data['app_update_message'] ?? '';
        _downloadUrlController.text = data['app_update_download_url'] ?? '';
        _versionController.text = data['app_update_version'] ?? '';
        _changelogController.text = data['app_update_changelog'] ?? '';
        _maintenanceMessageController.text = data['maintenance_message'] ?? '';

        _isUpdateRequired = data['app_update_required'] ?? false;
        _isUpdateForce = data['app_update_force'] ?? false;
        _isMaintenanceMode = data['maintenance_mode'] ?? false;
      } else {
        // Fallback to Remote Config if Firestore document doesn't exist
        print(
          '📄 [UpdateManagement] Loading settings from Remote Config (fallback)',
        );
        final remoteConfig = RemoteConfigService.instance;

        _titleController.text = remoteConfig.updateTitle;
        _messageController.text = remoteConfig.updateMessage;
        _downloadUrlController.text = remoteConfig.updateDownloadUrl;
        _versionController.text = remoteConfig.updateVersion;
        _changelogController.text = remoteConfig.updateChangelog;
        _maintenanceMessageController.text = remoteConfig.maintenanceMessage;

        _isUpdateRequired = remoteConfig.isUpdateRequired;
        _isUpdateForce = remoteConfig.isUpdateForce;
        _isMaintenanceMode = remoteConfig.isMaintenanceMode;
      }

      setState(() {}); // Trigger rebuild with new values
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
      // Update Firestore with new settings
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('update_management')
          .set({
            'app_update_required': _isUpdateRequired,
            'app_update_force': _isUpdateForce,
            'app_update_message': _messageController.text.trim(),
            'app_update_title': _titleController.text.trim(),
            'app_update_download_url': _downloadUrlController.text.trim(),
            'app_update_version': _versionController.text.trim(),
            'app_update_changelog': _changelogController.text.trim(),
            'maintenance_mode': _isMaintenanceMode,
            'maintenance_message': _maintenanceMessageController.text.trim(),
            'updated_at': FieldValue.serverTimestamp(),
            'updated_by': 'super_admin', // You can get actual user ID here
          }, SetOptions(merge: true));

      // Force refresh remote config
      final success = await RemoteConfigService.instance.forceFetch();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الإعدادات بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم الحفظ ولكن فشل في تحديث التطبيق'),
            backgroundColor: Colors.orange,
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

  Future<void> _testUpdateDialog() async {
    try {
      // Force show the update dialog for testing purposes
      final remoteConfig = RemoteConfigService.instance;

      // Temporarily set test values
      final testTitle =
          _titleController.text.trim().isNotEmpty
              ? _titleController.text.trim()
              : 'تحديث التطبيق';
      final testMessage =
          _messageController.text.trim().isNotEmpty
              ? _messageController.text.trim()
              : 'تحديث جديد متاح للتطبيق';
      final testVersion =
          _versionController.text.trim().isNotEmpty
              ? _versionController.text.trim()
              : '1.1.0';
      final testDownloadUrl =
          _downloadUrlController.text.trim().isNotEmpty
              ? _downloadUrlController.text.trim()
              : 'https://example.com/download';
      final testChangelog =
          _changelogController.text.trim().isNotEmpty
              ? _changelogController.text.trim()
              : 'تحسينات عامة وإصلاحات للأخطاء';
      final testForceUpdate = _isUpdateForce;

      // Show test dialog
      _showTestUpdateDialog(
        context,
        title: testTitle,
        message: testMessage,
        version: testVersion,
        downloadUrl: testDownloadUrl,
        changelog: testChangelog,
        isForceUpdate: testForceUpdate,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في اختبار التحديث: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showTestUpdateDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String version,
    required String downloadUrl,
    required String changelog,
    required bool isForceUpdate,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !isForceUpdate,
      builder:
          (context) => Directionality(
            textDirection: TextDirection.rtl,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue[600]!,
                      Colors.blue[700]!,
                      Colors.purple[600]!,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with animated background
                    Container(
                      padding: Responsive.padding(context, size: Space.large),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(
                            Responsive.space(context, size: Space.large),
                          ),
                          topRight: Radius.circular(
                            Responsive.space(context, size: Space.large),
                          ),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          // Animated icon container
                          Container(
                            padding: Responsive.padding(
                              context,
                              size: Space.medium,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(
                                Responsive.space(context, size: Space.medium),
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Stack(
                              children: [
                                // Background glow
                                Container(
                                  width: Responsive.space(
                                    context,
                                    size: Space.xlarge,
                                  ),
                                  height: Responsive.space(
                                    context,
                                    size: Space.xlarge,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.3),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                                // Main icon
                                Icon(
                                  Icons.system_update,
                                  color: Colors.white,
                                  size: Responsive.space(
                                    context,
                                    size: Space.large,
                                  ),
                                ),
                                // Sparkle effects
                                Positioned(
                                  top: Responsive.space(
                                    context,
                                    size: Space.tiny,
                                  ),
                                  right: Responsive.space(
                                    context,
                                    size: Space.tiny,
                                  ),
                                  child: Icon(
                                    Icons.star,
                                    color: Colors.yellow[300],
                                    size: Responsive.space(
                                      context,
                                      size: Space.small,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: Responsive.space(
                                    context,
                                    size: Space.tiny,
                                  ),
                                  left: Responsive.space(
                                    context,
                                    size: Space.tiny,
                                  ),
                                  child: Icon(
                                    Icons.star,
                                    color: Colors.yellow[300],
                                    size: Responsive.space(
                                      context,
                                      size: Space.small,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: Responsive.space(
                              context,
                              size: Space.medium,
                            ),
                          ),

                          // Title with glow effect
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                              vertical: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                Responsive.space(context, size: Space.medium),
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.heading,
                                ),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                    color: Colors.black26,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Container(
                      padding: Responsive.padding(context, size: Space.large),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(
                            Responsive.space(context, size: Space.large),
                          ),
                          bottomRight: Radius.circular(
                            Responsive.space(context, size: Space.large),
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Exciting message
                          Container(
                            padding: Responsive.padding(
                              context,
                              size: Space.medium,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue[50]!, Colors.purple[50]!],
                              ),
                              borderRadius: BorderRadius.circular(
                                Responsive.space(context, size: Space.medium),
                              ),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: Responsive.padding(
                                    context,
                                    size: Space.small,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[600],
                                    borderRadius: BorderRadius.circular(
                                      Responsive.space(
                                        context,
                                        size: Space.small,
                                      ),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.celebration,
                                    color: Colors.white,
                                    size: Responsive.space(
                                      context,
                                      size: Space.medium,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: Responsive.space(
                                    context,
                                    size: Space.small,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    message,
                                    style: TextStyle(
                                      fontSize: Responsive.text(
                                        context,
                                        size: TextSize.medium,
                                      ),
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(
                            height: Responsive.space(
                              context,
                              size: Space.medium,
                            ),
                          ),

                          // Version badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                              vertical: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green[400]!,
                                  Colors.green[600]!,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(
                                Responsive.space(context, size: Space.medium),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.new_releases,
                                  color: Colors.white,
                                  size: Responsive.space(
                                    context,
                                    size: Space.small,
                                  ),
                                ),
                                SizedBox(
                                  width: Responsive.space(
                                    context,
                                    size: Space.small,
                                  ),
                                ),
                                Text(
                                  'الإصدار الجديد: $version',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: Responsive.text(
                                      context,
                                      size: TextSize.small,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(
                            height: Responsive.space(
                              context,
                              size: Space.medium,
                            ),
                          ),

                          // Changelog with enhanced styling
                          Container(
                            padding: Responsive.padding(
                              context,
                              size: Space.medium,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(
                                Responsive.space(context, size: Space.medium),
                              ),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(
                                        Responsive.space(
                                          context,
                                          size: Space.tiny,
                                        ),
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[600],
                                        borderRadius: BorderRadius.circular(
                                          Responsive.space(
                                            context,
                                            size: Space.tiny,
                                          ),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.whatshot,
                                        color: Colors.white,
                                        size: Responsive.space(
                                          context,
                                          size: Space.small,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: Responsive.space(
                                        context,
                                        size: Space.small,
                                      ),
                                    ),
                                    Text(
                                      'ما الجديد في هذا التحديث:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: Responsive.text(
                                          context,
                                          size: TextSize.medium,
                                        ),
                                        color: Colors.orange[700],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: Responsive.space(
                                    context,
                                    size: Space.small,
                                  ),
                                ),
                                Container(
                                  padding: Responsive.padding(
                                    context,
                                    size: Space.small,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      Responsive.space(
                                        context,
                                        size: Space.small,
                                      ),
                                    ),
                                    border: Border.all(
                                      color: Colors.orange[200]!,
                                    ),
                                  ),
                                  child: Text(
                                    changelog,
                                    style: TextStyle(
                                      fontSize: Responsive.text(
                                        context,
                                        size: TextSize.small,
                                      ),
                                      color: Colors.grey[700],
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Force update warning
                          if (isForceUpdate) ...[
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),
                            Container(
                              padding: Responsive.padding(
                                context,
                                size: Space.medium,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.red[50]!, Colors.orange[50]!],
                                ),
                                borderRadius: BorderRadius.circular(
                                  Responsive.space(context, size: Space.medium),
                                ),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: Responsive.padding(
                                      context,
                                      size: Space.small,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red[600],
                                      borderRadius: BorderRadius.circular(
                                        Responsive.space(
                                          context,
                                          size: Space.small,
                                        ),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.priority_high,
                                      color: Colors.white,
                                      size: Responsive.space(
                                        context,
                                        size: Space.medium,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: Responsive.space(
                                      context,
                                      size: Space.small,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'تحديث إجباري - لا يمكن تخطي هذا التحديث',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: Responsive.text(
                                          context,
                                          size: TextSize.small,
                                        ),
                                        color: Colors.red[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          SizedBox(
                            height: Responsive.space(
                              context,
                              size: Space.large,
                            ),
                          ),

                          // Action buttons
                          Row(
                            children: [
                              if (!isForceUpdate) ...[
                                Expanded(
                                  child: Container(
                                    height:
                                        Responsive.space(
                                          context,
                                          size: Space.xlarge,
                                        ) *
                                        1.5,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(
                                        Responsive.space(
                                          context,
                                          size: Space.medium,
                                        ),
                                      ),
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    child: TextButton(
                                      onPressed:
                                          () => Navigator.of(context).pop(),
                                      style: TextButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            Responsive.space(
                                              context,
                                              size: Space.medium,
                                            ),
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'لاحقاً',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: Responsive.text(
                                            context,
                                            size: TextSize.medium,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: Responsive.space(
                                    context,
                                    size: Space.small,
                                  ),
                                ),
                              ],
                              Expanded(
                                flex: 2,
                                child: Container(
                                  height: Responsive.space(
                                    context,
                                    size: Space.xlarge,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.green[500]!,
                                        Colors.green[600]!,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      Responsive.space(
                                        context,
                                        size: Space.medium,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'سيتم فتح رابط التحميل: $downloadUrl',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          Responsive.space(
                                            context,
                                            size: Space.medium,
                                          ),
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.download,
                                          color: Colors.white,
                                          size: Responsive.space(
                                            context,
                                            size: Space.medium,
                                          ),
                                        ),
                                        SizedBox(
                                          width: Responsive.space(
                                            context,
                                            size: Space.small,
                                          ),
                                        ),
                                        Flexible(
                                          child: Text(
                                            'تحميل التحديث',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: Responsive.text(
                                                context,
                                                size: TextSize.small,
                                              ),
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
                  print('🔄 [UpdateManagement] Manual refresh requested');
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
                    child: SingleChildScrollView(
                      padding: Responsive.padding(context, size: Space.large),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeaderCard(),
                          SizedBox(
                            height: Responsive.space(
                              context,
                              size: Space.large,
                            ),
                          ),
                          _buildUpdateSettingsCard(),
                          SizedBox(
                            height: Responsive.space(
                              context,
                              size: Space.large,
                            ),
                          ),
                          _buildMaintenanceSettingsCard(),
                          SizedBox(
                            height: Responsive.space(
                              context,
                              size: Space.large,
                            ),
                          ),
                          _buildActionButtons(),
                          SizedBox(
                            height: Responsive.space(
                              context,
                              size: Space.large,
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

  Widget _buildHeaderCard() {
    return Container(
      padding: Responsive.padding(context, size: Space.large),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[700]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.settings_system_daydream,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نظام إدارة التحديثات',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.text(context, size: TextSize.heading),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'تحكم في تحديثات التطبيق ووضع الصيانة',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: Responsive.text(context, size: TextSize.small),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateSettingsCard() {
    return Container(
      padding: Responsive.padding(context, size: Space.large),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient background
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[50]!, Colors.blue[100]!],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.system_update,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إعدادات التحديث',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.heading,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'تحكم في كيفية عرض التحديثات للمستخدمين',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.small,
                          ),
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Switches with enhanced styling
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                _buildEnhancedSwitchTile(
                  title: 'تفعيل التحديث',
                  subtitle: 'إظهار رسالة التحديث للمستخدمين',
                  value: _isUpdateRequired,
                  onChanged:
                      (value) => setState(() => _isUpdateRequired = value),
                  activeColor: Colors.blue[600]!,
                  icon: Icons.notifications_active,
                ),
                Divider(height: 1, color: Colors.grey[200]),
                _buildEnhancedSwitchTile(
                  title: 'تحديث إجباري',
                  subtitle: 'إجبار المستخدمين على التحديث',
                  value: _isUpdateForce,
                  onChanged: (value) => setState(() => _isUpdateForce = value),
                  activeColor: Colors.red[600]!,
                  icon: Icons.block,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Form fields with enhanced styling
          _buildFormSection(
            title: 'تفاصيل التحديث',
            icon: Icons.edit,
            children: [
              _buildEnhancedTextField(
                controller: _titleController,
                hint: 'عنوان رسالة التحديث',
                icon: Icons.title,
                validator: (value) {
                  if (_isUpdateRequired &&
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
                  if (_isUpdateRequired &&
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
                  if (_isUpdateRequired &&
                      (value == null || value.trim().isEmpty)) {
                    return 'يرجى إدخال رقم الإصدار';
                  }
                  if (_isUpdateRequired &&
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
                  if (_isUpdateRequired &&
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
                  if (_isUpdateRequired &&
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

  Widget _buildMaintenanceSettingsCard() {
    return Container(
      padding: Responsive.padding(context, size: Space.large),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient background
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[50]!, Colors.orange[100]!],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange[600],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.engineering,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'وضع الصيانة',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.heading,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'إيقاف التطبيق مؤقتاً للصيانة والإصلاحات',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.small,
                          ),
                          color: Colors.orange[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Maintenance switch with enhanced styling
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: _buildEnhancedSwitchTile(
              title: 'تفعيل وضع الصيانة',
              subtitle: 'إيقاف التطبيق مؤقتاً للصيانة',
              value: _isMaintenanceMode,
              onChanged: (value) => setState(() => _isMaintenanceMode = value),
              activeColor: Colors.orange[600]!,
              icon: Icons.engineering,
            ),
          ),

          const SizedBox(height: 24),

          // Maintenance message field
          _buildFormSection(
            title: 'رسالة الصيانة',
            icon: Icons.message,
            children: [
              _buildEnhancedTextField(
                controller: _maintenanceMessageController,
                hint: 'رسالة الصيانة',
                icon: Icons.warning,
                maxLines: 3,
                validator: (value) {
                  if (_isMaintenanceMode &&
                      (value == null || value.trim().isEmpty)) {
                    return 'يرجى إدخال رسالة الصيانة';
                  }
                  return null;
                },
              ),
            ],
          ),

          // Warning message when maintenance mode is enabled
          if (_isMaintenanceMode) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange[700],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تحذير',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'سيتم إيقاف التطبيق لجميع المستخدمين حتى يتم إلغاء وضع الصيانة',
                          style: TextStyle(
                            color: Colors.orange[600],
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.small,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: Responsive.padding(context, size: Space.large),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.green[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'إجراءات التحديث',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.heading),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Buttons
          Row(
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
                    onPressed: _isLoading ? null : _testUpdateDialog,
                    icon: const Icon(Icons.preview, size: 20),
                    label: const Text(
                      'اختبار التحديث',
                      style: TextStyle(
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
                    onPressed:
                        _isLoading
                            ? null
                            : () {
                              print(
                                '🔧 [UpdateManagement] Save button pressed',
                              );
                              _saveSettings();
                            },
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

          // Info text
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'معلومات الإعدادات',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• استخدم "اختبار التحديث" لمعاينة التحديث قبل النشر',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: Responsive.text(context, size: TextSize.small),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '• الإعدادات محفوظة في Firestore ويمكن تحديثها فوراً',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: Responsive.text(context, size: TextSize.small),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '• استخدم زر التحديث (🔄) لتحميل أحدث الإعدادات',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: Responsive.text(context, size: TextSize.small),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
