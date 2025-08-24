import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pivot/services/remote_config_service.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  final RemoteConfigService _remoteConfig = RemoteConfigService.instance;

  // Check for updates and show dialog if needed
  Future<void> checkForUpdates(BuildContext context) async {
    try {
      // Check if app is in maintenance mode
      if (_remoteConfig.isAppInMaintenance()) {
        _showMaintenanceDialog(context);
        return;
      }

      // Check if update is required
      if (_remoteConfig.isUpdateRequired) {
        final isUpdateNeeded = await _remoteConfig.isAppUpdateNeeded();
        if (isUpdateNeeded) {
          _showUpdateDialog(context);
        }
      }
    } catch (e) {
      print('Error checking for updates: $e');
    }
  }

  // Show update dialog
  void _showUpdateDialog(BuildContext context) {
    final isForceUpdate = _remoteConfig.isUpdateForce;

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
                              _remoteConfig.updateTitle,
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
                                    _remoteConfig.updateMessage,
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
                                  'الإصدار الجديد: ${_remoteConfig.updateVersion}',
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
                                    _remoteConfig.updateChangelog,
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
                                    height: Responsive.space(
                                      context,
                                      size: Space.xlarge,
                                    ),
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
                                    onPressed: () => _downloadUpdate(context),
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

  // Show maintenance dialog
  void _showMaintenanceDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Can't dismiss maintenance dialog
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.engineering, color: Colors.orange[600], size: 28),
                SizedBox(width: Responsive.space(context, size: Space.small)),
                Text(
                  'وضع الصيانة',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.heading),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              _remoteConfig.maintenanceMessage,
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => _checkForUpdates(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'إعادة المحاولة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // Download update
  Future<void> _downloadUpdate(BuildContext context) async {
    final downloadUrl = _remoteConfig.updateDownloadUrl;

    if (downloadUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('رابط التحميل غير متاح حالياً'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse(downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        Navigator.of(context).pop(); // Close dialog
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن فتح رابط التحميل'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في فتح رابط التحميل: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Recheck for updates (used in maintenance dialog)
  Future<void> _checkForUpdates(BuildContext context) async {
    try {
      final success = await _remoteConfig.forceFetch();
      if (success) {
        Navigator.of(context).pop(); // Close maintenance dialog
        await checkForUpdates(context); // Check again
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل في التحقق من التحديثات'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في التحقق من التحديثات: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
