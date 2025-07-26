import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/services/notification_test_service.dart';

class NotificationTestWidget extends StatefulWidget {
  // = 'notification_test_widget';
  const NotificationTestWidget({super.key});

  @override
  State<NotificationTestWidget> createState() => _NotificationTestWidgetState();
}

class _NotificationTestWidgetState extends State<NotificationTestWidget> {
  final NotificationTestService _testService = NotificationTestService();
  Map<String, dynamic>? _testResults;
  Map<String, dynamic>? _healthStatus;
  bool _isRunningTests = false;
  bool _isCheckingHealth = false;
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
}
