import 'package:flutter/material.dart';
import 'package:pivot/services/fcm_token_manager.dart';
import 'package:pivot/responsive.dart';

class FCMTokenManagementScreen extends StatefulWidget {
  const FCMTokenManagementScreen({super.key});

  @override
  State<FCMTokenManagementScreen> createState() =>
      _FCMTokenManagementScreenState();
}

class _FCMTokenManagementScreenState extends State<FCMTokenManagementScreen> {
  final FCMTokenManager _tokenManager = FCMTokenManager();
  bool _isLoading = false;
  Map<String, dynamic>? _statistics;
  Map<String, dynamic>? _cleanupResults;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await _tokenManager.getTokenStatistics();
      setState(() {
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل الإحصائيات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _runTokenCleanup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _tokenManager.cleanupInvalidTokens();
      setState(() {
        _cleanupResults = results;
        _isLoading = false;
      });

      // Reload statistics after cleanup
      await _loadStatistics();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تنظيف ${results['cleanedTokens']} رمز FCM غير صالح',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تنظيف الرموز: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة رموز FCM'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadStatistics,
            tooltip: 'تحديث الإحصائيات',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: Responsive.padding(context, size: Space.large),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistics Card
                    if (_statistics != null) ...[
                      _buildStatisticsCard(),
                      SizedBox(
                        height: Responsive.space(context, size: Space.large),
                      ),
                    ],

                    // Cleanup Results Card
                    if (_cleanupResults != null) ...[
                      _buildCleanupResultsCard(),
                      SizedBox(
                        height: Responsive.space(context, size: Space.large),
                      ),
                    ],

                    // Actions Card
                    _buildActionsCard(),
                  ],
                ),
              ),
    );
  }

  Widget _buildStatisticsCard() {
    final stats = _statistics!;
    final totalUsers = stats['totalUsers'] ?? 0;
    final activeTokens = stats['activeTokens'] ?? 0;
    final invalidTokens = stats['invalidTokens'] ?? 0;
    final activePercentage =
        totalUsers > 0
            ? (activeTokens / totalUsers * 100).toStringAsFixed(1)
            : '0';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
      ),
      child: Padding(
        padding: Responsive.padding(context, size: Space.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue[600], size: 28),
                SizedBox(width: Responsive.space(context, size: Space.small)),
                Text(
                  'إحصائيات رموز FCM',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.heading),
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.space(context, size: Space.medium)),

            // Statistics Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'إجمالي المستخدمين',
                    totalUsers.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: Responsive.space(context, size: Space.medium)),
                Expanded(
                  child: _buildStatItem(
                    'الرموز النشطة',
                    activeTokens.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'الرموز غير الصالحة',
                    invalidTokens.toString(),
                    Icons.error,
                    Colors.red,
                  ),
                ),
                SizedBox(width: Responsive.space(context, size: Space.medium)),
                Expanded(
                  child: _buildStatItem(
                    'نسبة الرموز النشطة',
                    '$activePercentage%',
                    Icons.percent,
                    Colors.orange,
                  ),
                ),
              ],
            ),

            if (stats['timestamp'] != null) ...[
              SizedBox(height: Responsive.space(context, size: Space.medium)),
              Text(
                'آخر تحديث: ${DateTime.parse(stats['timestamp']).toString().substring(0, 19)}',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.small),
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: Responsive.padding(context, size: Space.medium),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.small),
        ),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          Text(
            value,
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.heading),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: Responsive.space(context, size: Space.tiny)),
          Text(
            label,
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.small),
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCleanupResultsCard() {
    final results = _cleanupResults!;
    final totalUsers = results['totalUsers'] ?? 0;
    final cleanedTokens = results['cleanedTokens'] ?? 0;
    final errors = results['errors'] as List<String>? ?? [];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
      ),
      child: Padding(
        padding: Responsive.padding(context, size: Space.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cleaning_services,
                  color: Colors.green[600],
                  size: 28,
                ),
                SizedBox(width: Responsive.space(context, size: Space.small)),
                Text(
                  'نتائج التنظيف',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.heading),
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.space(context, size: Space.medium)),

            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'إجمالي المستخدمين المفحوصين',
                    totalUsers.toString(),
                    Icons.search,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: Responsive.space(context, size: Space.medium)),
                Expanded(
                  child: _buildStatItem(
                    'الرموز المنظفة',
                    cleanedTokens.toString(),
                    Icons.delete_sweep,
                    Colors.green,
                  ),
                ),
              ],
            ),

            if (errors.isNotEmpty) ...[
              SizedBox(height: Responsive.space(context, size: Space.medium)),
              Container(
                padding: Responsive.padding(context, size: Space.medium),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.small),
                  ),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 20),
                        SizedBox(
                          width: Responsive.space(context, size: Space.small),
                        ),
                        Text(
                          'الأخطاء (${errors.length})',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.small),
                    ),
                    ...errors
                        .take(3)
                        .map(
                          (error) => Padding(
                            padding: EdgeInsets.only(
                              bottom: Responsive.space(
                                context,
                                size: Space.tiny,
                              ),
                            ),
                            child: Text(
                              '• $error',
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.small,
                                ),
                                color: Colors.red[700],
                              ),
                            ),
                          ),
                        ),
                    if (errors.length > 3)
                      Text(
                        '... و ${errors.length - 3} خطأ آخر',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.small,
                          ),
                          color: Colors.red[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ],

            if (results['timestamp'] != null) ...[
              SizedBox(height: Responsive.space(context, size: Space.medium)),
              Text(
                'وقت التنظيف: ${DateTime.parse(results['timestamp']).toString().substring(0, 19)}',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.small),
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
      ),
      child: Padding(
        padding: Responsive.padding(context, size: Space.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.orange[600], size: 28),
                SizedBox(width: Responsive.space(context, size: Space.small)),
                Text(
                  'الإجراءات',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.heading),
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.space(context, size: Space.medium)),

            // Cleanup Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _runTokenCleanup,
                icon: const Icon(Icons.cleaning_services),
                label: const Text('تنظيف الرموز غير الصالحة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: Responsive.padding(context, size: Space.medium),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.small),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: Responsive.space(context, size: Space.medium)),

            // Refresh Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _loadStatistics,
                icon: const Icon(Icons.refresh),
                label: const Text('تحديث الإحصائيات'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue[600],
                  side: BorderSide(color: Colors.blue[600]!),
                  padding: Responsive.padding(context, size: Space.medium),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.small),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: Responsive.space(context, size: Space.medium)),

            // Information
            Container(
              padding: Responsive.padding(context, size: Space.medium),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.small),
                ),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[600], size: 20),
                      SizedBox(
                        width: Responsive.space(context, size: Space.small),
                      ),
                      Text(
                        'معلومات مهمة',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: Responsive.space(context, size: Space.small),
                  ),
                  Text(
                    '• يتم تنظيف الرموز غير الصالحة تلقائياً كل 24 ساعة\n'
                    '• الرموز التي يزيد عمرها عن 60 يوم تعتبر قديمة\n'
                    '• الرموز غير الصالحة يتم حذفها من قاعدة البيانات',
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.small),
                      color: Colors.blue[700],
                      height: 1.4,
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
}


