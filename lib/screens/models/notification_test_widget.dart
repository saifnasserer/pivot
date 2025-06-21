import 'package:flutter/material.dart';
import 'package:pivot/services/notification_test_service.dart';
import 'package:pivot/responsive.dart';

class NotificationTestWidget extends StatefulWidget {
  static const String id = 'notification_test_widget';
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Health Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.health_and_safety, size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          'System Health',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_healthStatus != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                _healthStatus!['overall_status'],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _healthStatus!['overall_status']
                                  .toString()
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                              const SizedBox(width: 8),
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
                    const SizedBox(height: 16),
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
            const SizedBox(height: 16),

            // Test Results Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.science, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Test Results',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                              const SizedBox(width: 8),
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
                    const SizedBox(height: 16),
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
                        const SizedBox(width: 8),
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
