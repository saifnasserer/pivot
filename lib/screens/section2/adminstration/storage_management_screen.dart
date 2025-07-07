import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/services/storage_optimization_service.dart';

class StorageManagementScreen extends StatefulWidget {
  // = 'storage_management';

  const StorageManagementScreen({super.key});

  @override
  State<StorageManagementScreen> createState() =>
      _StorageManagementScreenState();
}

class _StorageManagementScreenState extends State<StorageManagementScreen> {
  final StorageOptimizationService _storageService =
      StorageOptimizationService();
  Map<String, dynamic> _storageStats = {};
  bool _isLoading = false;
  bool _isCleanupRunning = false;

  @override
  void initState() {
    super.initState();
    _loadStorageStats();
  }

  Future<void> _loadStorageStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await _storageService.getStorageStats();
      setState(() {
        _storageStats = stats;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading storage stats: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _performCleanup() async {
    setState(() {
      _isCleanupRunning = true;
    });

    try {
      await _storageService.performFullCleanup();
      await _loadStorageStats(); // Refresh stats after cleanup

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Storage cleanup completed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during cleanup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCleanupRunning = false;
      });
    }
  }

  Future<void> _cleanupOrphanedFiles() async {
    setState(() {
      _isCleanupRunning = true;
    });

    try {
      await _storageService.cleanupOrphanedFiles();
      await _loadStorageStats();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Orphaned files cleanup completed'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cleaning orphaned files: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCleanupRunning = false;
      });
    }
  }

  Widget _buildStorageCard(String folder, Map<String, dynamic> stats) {
    final fileCount = stats['fileCount'] as int? ?? 0;
    final totalSizeMB = stats['totalSizeMB'] as String? ?? '0.00';
    final totalSize = stats['totalSize'] as int? ?? 0;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.medium),
        vertical: Responsive.space(context, size: Space.small),
      ),
      child: Padding(
        padding: EdgeInsets.all(Responsive.space(context, size: Space.medium)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getFolderIcon(folder),
                  color: _getFolderColor(folder),
                  size: 24,
                ),
                SizedBox(width: Responsive.space(context, size: Space.small)),
                Expanded(
                  child: Text(
                    _getFolderDisplayName(folder),
                    style: TextStyle(
                      fontSize: Responsive.text(
                        context,
                        size: TextSize.heading,
                      ),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Files', fileCount.toString()),
                _buildStatItem('Size', '$totalSizeMB MB'),
              ],
            ),
            if (totalSize > 0) ...[
              SizedBox(height: Responsive.space(context, size: Space.small)),
              LinearProgressIndicator(
                value: _calculateUsagePercentage(totalSize),
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getFolderColor(folder),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.small),
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.medium),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  IconData _getFolderIcon(String folder) {
    switch (folder) {
      case 'announcements':
        return Icons.announcement;
      case 'profile_images':
        return Icons.person;
      case 'tasks':
        return Icons.task;
      case 'guides':
        return Icons.book;
      default:
        return Icons.folder;
    }
  }

  Color _getFolderColor(String folder) {
    switch (folder) {
      case 'announcements':
        return Colors.blue;
      case 'profile_images':
        return Colors.green;
      case 'tasks':
        return Colors.orange;
      case 'guides':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getFolderDisplayName(String folder) {
    switch (folder) {
      case 'announcements':
        return 'الإعلانات';
      case 'profile_images':
        return 'صور الملفات الشخصية';
      case 'tasks':
        return 'المهام';
      case 'guides':
        return 'الدليل الإرشادي';
      default:
        return folder;
    }
  }

  double _calculateUsagePercentage(int sizeInBytes) {
    // Calculate percentage based on a reasonable threshold (e.g., 100MB per folder)
    const maxSizePerFolder = 100 * 1024 * 1024; // 100MB
    return (sizeInBytes / maxSizePerFolder).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إدارة التخزين',
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.heading),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadStorageStats,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(
                  Responsive.space(context, size: Space.medium),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Storage Overview
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(
                          Responsive.space(context, size: Space.large),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'نظرة عامة على التخزين',
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.heading,
                                ),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildOverviewStat(
                                  'إجمالي الملفات',
                                  _getTotalFileCount(),
                                ),
                                _buildOverviewStat(
                                  'إجمالي الحجم',
                                  _getTotalSizeMB(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(
                      height: Responsive.space(context, size: Space.large),
                    ),

                    // Cleanup Actions
                    Text(
                      'عمليات التنظيف',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.heading,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                _isCleanupRunning
                                    ? null
                                    : _cleanupOrphanedFiles,
                            icon: const Icon(Icons.cleaning_services),
                            label: const Text('تنظيف الملفات اليتيمة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: Responsive.space(
                                  context,
                                  size: Space.medium,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: Responsive.space(context, size: Space.small),
                        ),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                _isCleanupRunning ? null : _performCleanup,
                            icon: const Icon(Icons.auto_fix_high),
                            label: const Text('تنظيف شامل'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: Responsive.space(
                                  context,
                                  size: Space.medium,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),

                    if (_isCleanupRunning) ...[
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),
                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text('جاري التنظيف...'),
                          ],
                        ),
                      ),
                    ],

                    SizedBox(
                      height: Responsive.space(context, size: Space.large),
                    ),

                    // Storage Breakdown
                    Text(
                      'تفصيل التخزين',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.heading,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),

                    // Storage cards for each folder
                    ..._storageStats.entries.map(
                      (entry) => _buildStorageCard(entry.key, entry.value),
                    ),

                    SizedBox(
                      height: Responsive.space(context, size: Space.large),
                    ),

                    // Storage Tips
                    Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: EdgeInsets.all(
                          Responsive.space(context, size: Space.medium),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb, color: Colors.blue[700]),
                                SizedBox(
                                  width: Responsive.space(
                                    context,
                                    size: Space.small,
                                  ),
                                ),
                                Text(
                                  'نصائح لتوفير التخزين',
                                  style: TextStyle(
                                    fontSize: Responsive.text(
                                      context,
                                      size: TextSize.medium,
                                    ),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
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
                            Text(
                              '• الصور يتم ضغطها تلقائياً قبل الرفع\n'
                              '• الملفات المكررة يتم اكتشافها وتجنبها\n'
                              '• الملفات اليتيمة يتم حذفها تلقائياً\n'
                              '• يتم تتبع استخدام الملفات عبر المجموعات',
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
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildOverviewStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.heading) * 1.2,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.small),
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _getTotalFileCount() {
    int total = 0;
    for (var stats in _storageStats.values) {
      total += stats['fileCount'] as int? ?? 0;
    }
    return total.toString();
  }

  String _getTotalSizeMB() {
    double totalMB = 0;
    for (var stats in _storageStats.values) {
      final sizeMB =
          double.tryParse(stats['totalSizeMB'] as String? ?? '0') ?? 0;
      totalMB += sizeMB;
    }
    return '${totalMB.toStringAsFixed(2)} MB';
  }
}
