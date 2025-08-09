import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/services/notification_test_service.dart';
import 'package:pivot/services/notification_service.dart';
import 'package:pivot/services/local_notification_service.dart';

class NotificationTestWidget extends StatefulWidget {
  // = 'notification_test_widget';
  const NotificationTestWidget({super.key});

  @override
  State<NotificationTestWidget> createState() => _NotificationTestWidgetState();
}

class _NotificationTestWidgetState extends State<NotificationTestWidget> {
  final NotificationTestService _testService = NotificationTestService();
  final NotificationService _notificationService = NotificationService();
  Map<String, dynamic>? _testResults;
  Map<String, dynamic>? _healthStatus;
  Map<String, dynamic>? _tokenStats;
  Map<String, dynamic>? _localNotificationInfo;
  bool _isRunningTests = false;
  bool _isCheckingHealth = false;
  bool _isCleaningTokens = false;
  bool _isGettingStats = false;
  bool _isTestingLocal = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification System Test'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: Responsive.padding(context, size: Space.medium),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Health Status Card
              Card(
                child: Padding(
                  padding: Responsive.padding(context, size: Space.medium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.health_and_safety, size: 24),
                          SizedBox(
                            width: Responsive.space(context, size: Space.small),
                          ),
                          Text(
                            'System Health',
                            style: TextStyle(
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.medium,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (_healthStatus != null)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: Responsive.space(
                                  context,
                                  size: Space.small,
                                ),
                                vertical: Responsive.space(
                                  context,
                                  size: Space.tiny,
                                ),
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  _healthStatus!['overall_status'],
                                ),
                                borderRadius: BorderRadius.circular(
                                  Responsive.space(context, size: Space.large),
                                ),
                              ),
                              child: Text(
                                _healthStatus!['overall_status']
                                    .toString()
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.small,
                                  ),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),
                      if (_healthStatus != null) ...[
                        ..._healthStatus!['components'].entries.map((entry) {
                          final component = entry.value as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Icon(
                                  component['status'] == 'healthy'
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color:
                                      component['status'] == 'healthy'
                                          ? Colors.green
                                          : Colors.red,
                                  size: 16,
                                ),
                                SizedBox(
                                  width: Responsive.space(
                                    context,
                                    size: Space.small,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${entry.key}: ${component['details']}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ] else
                        const Text('No health data available'),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isCheckingHealth ? null : _checkHealth,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child:
                              _isCheckingHealth
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : const Text('Check System Health'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),

              // FCM Token Management Card
              Card(
                child: Padding(
                  padding: Responsive.padding(context, size: Space.medium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.token, size: 24),
                          SizedBox(
                            width: Responsive.space(context, size: Space.small),
                          ),
                          Text(
                            'FCM Token Management',
                            style: TextStyle(
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.medium,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),
                      if (_tokenStats != null) ...[
                        _buildTokenStatsDisplay(),
                        SizedBox(
                          height: Responsive.space(context, size: Space.medium),
                        ),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  _isGettingStats ? null : _getTokenStats,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              child:
                                  _isGettingStats
                                      ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                      : const Text('Get Token Stats'),
                            ),
                          ),
                          SizedBox(
                            width: Responsive.space(context, size: Space.small),
                          ),
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  _isCleaningTokens ? null : _cleanupTokens,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child:
                                  _isCleaningTokens
                                      ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                      : const Text('Clean Invalid Tokens'),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.small),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _refreshCurrentUserToken,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Refresh My Token'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),

              // Local Notifications Testing Card
              Card(
                child: Padding(
                  padding: Responsive.padding(context, size: Space.medium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.phone_android, size: 24),
                          SizedBox(
                            width: Responsive.space(context, size: Space.small),
                          ),
                          Text(
                            'Local Notifications (Mobile)',
                            style: TextStyle(
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.medium,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),
                      if (_localNotificationInfo != null) ...[
                        _buildLocalNotificationInfo(),
                        SizedBox(
                          height: Responsive.space(context, size: Space.medium),
                        ),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  _isTestingLocal
                                      ? null
                                      : _testLocalNotification,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                              ),
                              child:
                                  _isTestingLocal
                                      ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                      : const Text('Test Local Notification'),
                            ),
                          ),
                          SizedBox(
                            width: Responsive.space(context, size: Space.small),
                          ),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _getLocalNotificationInfo,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Get Scheduled Info'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: Responsive.space(context, size: Space.medium)),

              // Test Results Card
              Card(
                child: Padding(
                  padding: Responsive.padding(context, size: Space.medium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.science, size: 24),
                          SizedBox(
                            width: Responsive.space(context, size: Space.small),
                          ),
                          Text(
                            'Test Results',
                            style: TextStyle(
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.medium,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),
                      if (_testResults != null) ...[
                        ..._testResults!['tests'].entries.map((entry) {
                          final test = entry.value as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Icon(
                                  test['success'] == true
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color:
                                      test['success'] == true
                                          ? Colors.green
                                          : Colors.red,
                                  size: 16,
                                ),
                                SizedBox(
                                  width: Responsive.space(
                                    context,
                                    size: Space.small,
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.key,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (test['error'] != null)
                                        Text(
                                          test['error'],
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                          ),
                                        ),
                                      if (test['message'] != null)
                                        Text(
                                          test['message'],
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ] else
                        const Text('No test results available'),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isRunningTests ? null : _runFullTest,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child:
                                  _isRunningTests
                                      ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                      : const Text('Run Full Test'),
                            ),
                          ),
                          SizedBox(
                            width: Responsive.space(context, size: Space.small),
                          ),
                          ElevatedButton(
                            onPressed: _sendTestNotification,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Send Test Notification'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'healthy':
        return Colors.green;
      case 'degraded':
        return Colors.orange;
      case 'unhealthy':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _checkHealth() async {
    setState(() {
      _isCheckingHealth = true;
    });

    try {
      final health = await _testService.checkSystemHealth();
      setState(() {
        _healthStatus = health;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking health: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCheckingHealth = false;
      });
    }
  }

  Future<void> _runFullTest() async {
    setState(() {
      _isRunningTests = true;
    });

    try {
      final results = await _testService.runFullNotificationTest();
      setState(() {
        _testResults = results;
      });

      // Show summary
      final successfulTests =
          results['tests'].entries
              .where((entry) => entry.value['success'] == true)
              .length;
      final totalTests = results['tests'].length;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tests completed: $successfulTests/$totalTests successful',
          ),
          backgroundColor:
              successfulTests == totalTests ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error running tests: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isRunningTests = false;
      });
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      final success = await _testService.sendTestNotification();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Test notification sent successfully!'
                : 'Failed to send test notification',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending test notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Build token statistics display
  Widget _buildTokenStatsDisplay() {
    if (_tokenStats == null) return const SizedBox();

    return Column(
      children: [
        _buildStatRow('Total Users', _tokenStats!['totalUsers'].toString()),
        _buildStatRow(
          'Users with Tokens',
          _tokenStats!['usersWithTokens'].toString(),
        ),
        _buildStatRow(
          'Users without Tokens',
          _tokenStats!['usersWithoutTokens'].toString(),
        ),
        _buildStatRow(
          'Recent Tokens (≤30 days)',
          _tokenStats!['recentTokens'].toString(),
        ),
        _buildStatRow(
          'Old Tokens (>30 days)',
          _tokenStats!['oldTokens'].toString(),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Get FCM token statistics
  Future<void> _getTokenStats() async {
    setState(() {
      _isGettingStats = true;
    });

    try {
      final stats = await _notificationService.getTokenStatistics();
      setState(() {
        _tokenStats = stats;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token statistics retrieved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting token stats: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isGettingStats = false;
      });
    }
  }

  // Clean up invalid FCM tokens
  Future<void> _cleanupTokens() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Token Cleanup'),
            content: const Text(
              'This will remove invalid and expired FCM tokens from the database. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() {
      _isCleaningTokens = true;
    });

    try {
      final results = await _notificationService.cleanupInvalidTokens();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cleanup completed! Cleaned ${results['cleanedTokens']} tokens from ${results['totalUsers']} users.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh stats after cleanup
      if (_tokenStats != null) {
        _getTokenStats();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cleaning tokens: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCleaningTokens = false;
      });
    }
  }

  // Refresh current user's token
  Future<void> _refreshCurrentUserToken() async {
    try {
      final success = await _notificationService.refreshCurrentUserToken();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Your FCM token has been refreshed successfully!'
                : 'Failed to refresh your FCM token',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error refreshing token: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Build local notification info display
  Widget _buildLocalNotificationInfo() {
    if (_localNotificationInfo == null) return const SizedBox();

    return Column(
      children: [
        _buildStatRow(
          'Scheduled Notifications',
          _localNotificationInfo!['count'].toString(),
        ),
        if (_localNotificationInfo!['notifications'] != null)
          ...(_localNotificationInfo!['notifications'] as List)
              .take(3)
              .map(
                (notif) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    '• ${notif['title']}: ${notif['body']?.substring(0, 30)}...',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ),
        if ((_localNotificationInfo!['notifications'] as List).length > 3)
          Text(
            '...and ${(_localNotificationInfo!['notifications'] as List).length - 3} more',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
      ],
    );
  }

  // Test local notification
  Future<void> _testLocalNotification() async {
    setState(() {
      _isTestingLocal = true;
    });

    try {
      final success = await LocalNotificationService.instance
          .sendTestNotification(
            title: 'Local Test Notification',
            body: 'This is a local test notification sent at ${DateTime.now()}',
          );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Local test notification sent successfully!'
                : 'Failed to send local test notification',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error testing local notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isTestingLocal = false;
      });
    }
  }

  // Get local notification info
  Future<void> _getLocalNotificationInfo() async {
    try {
      final info =
          await LocalNotificationService.instance
              .getScheduledNotificationsInfo();
      setState(() {
        _localNotificationInfo = info;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Found ${info['count']} scheduled local notifications'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting local notification info: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
