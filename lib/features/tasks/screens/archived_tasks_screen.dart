import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/tasks/providers/tasks_provider.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:pivot/services/offline_service.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/task.dart';
import 'package:pivot/screens/models/task_model.dart';

/// Archived Tasks Screen - View and manage completed/archived tasks
class ArchivedTasksScreen extends ConsumerStatefulWidget {
  const ArchivedTasksScreen({super.key});

  @override
  ConsumerState<ArchivedTasksScreen> createState() =>
      _ArchivedTasksScreenState();
}

class _ArchivedTasksScreenState extends ConsumerState<ArchivedTasksScreen>
    with SingleTickerProviderStateMixin {
  List<Task> _archivedTasks = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();

  // Pagination
  static const int _pageSize = 20;
  int _currentPage = 0;
  bool _hasMore = true;

  // Cache management
  List<Task> _cachedAllTasks = []; // Full cached list
  DateTime? _lastFetchTime;
  static const Duration _cacheValidity = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _scrollController.addListener(_onScroll);

    _loadArchivedTasks();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoadingMore && _hasMore) {
        _loadMoreTasks();
      }
    }
  }

  Future<void> _loadArchivedTasks({bool forceRefresh = false}) async {
    final offlineService = ref.read(offlineServiceProvider);
    final now = DateTime.now();
    final isCacheValid =
        _lastFetchTime != null &&
        now.difference(_lastFetchTime!) < _cacheValidity;

    // Use cache if valid and not forcing refresh
    if (!forceRefresh && isCacheValid && _cachedAllTasks.isNotEmpty) {
      print(
        '📦 ArchivedTasks: Using cached data (${_cachedAllTasks.length} tasks)',
      );
      setState(() {
        _isLoading = true;
        _currentPage = 0;
        _hasMore = true;
      });

      // Simulate brief loading for smooth UX
      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        setState(() {
          _archivedTasks = _cachedAllTasks.take(_pageSize).toList();
          _hasMore = _cachedAllTasks.length > _pageSize;
          _isLoading = false;
        });
        _animationController.forward();
      }
      return;
    }

    // If offline and no cache, show cached data or error
    if (!offlineService.hasConnection) {
      if (_cachedAllTasks.isNotEmpty) {
        print('📡 ArchivedTasks: Offline - using stale cache');
        setState(() {
          _isLoading = true;
          _currentPage = 0;
          _hasMore = true;
        });

        await Future.delayed(const Duration(milliseconds: 100));

        if (mounted) {
          setState(() {
            _archivedTasks = _cachedAllTasks.take(_pageSize).toList();
            _hasMore = _cachedAllTasks.length > _pageSize;
            _isLoading = false;
          });
          _animationController.forward();
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لا يوجد اتصال بالإنترنت ولا توجد بيانات محفوظة'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
      return;
    }

    // Fetch from server
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _hasMore = true;
    });

    try {
      print('🌐 ArchivedTasks: Fetching from server...');
      final allTasks =
          await ref.read(tasksProvider.notifier).getArchivedTasks();

      if (mounted) {
        setState(() {
          // Update cache
          _cachedAllTasks = allTasks;
          _lastFetchTime = DateTime.now();

          // Take first page
          _archivedTasks = allTasks.take(_pageSize).toList();
          _hasMore = allTasks.length > _pageSize;
          _isLoading = false;
        });
        _animationController.forward();
        print('✅ ArchivedTasks: Loaded ${allTasks.length} tasks from server');
      }
    } catch (e) {
      print('❌ ArchivedTasks: Error loading - $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // If we have cache, use it as fallback
        if (_cachedAllTasks.isNotEmpty) {
          setState(() {
            _archivedTasks = _cachedAllTasks.take(_pageSize).toList();
            _hasMore = _cachedAllTasks.length > _pageSize;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تعذر تحديث البيانات - عرض البيانات المحفوظة'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل تحميل التاسكات المؤرشفة: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _loadMoreTasks() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Use cached data for pagination - no need to fetch again
    await Future.delayed(const Duration(milliseconds: 200)); // Simulate loading

    if (mounted) {
      setState(() {
        _currentPage++;
        final startIndex = _currentPage * _pageSize;
        final endIndex = startIndex + _pageSize;

        if (startIndex < _cachedAllTasks.length) {
          _archivedTasks.addAll(
            _cachedAllTasks.skip(startIndex).take(_pageSize).toList(),
          );
          _hasMore = endIndex < _cachedAllTasks.length;
          print('📄 ArchivedTasks: Loaded page $_currentPage from cache');
        } else {
          _hasMore = false;
        }

        _isLoadingMore = false;
      });
    }
  }

  Future<void> _restoreTask(Task task) async {
    // OPTIMISTIC UPDATE: Remove from UI immediately
    final taskIndex = _archivedTasks.indexWhere((t) => t.id == task.id);
    if (taskIndex == -1) return;

    final removedTask = _archivedTasks[taskIndex];

    setState(() {
      // Remove from displayed list
      _archivedTasks.removeAt(taskIndex);
      // Remove from cache
      _cachedAllTasks.removeWhere((t) => t.id == task.id);
    });

    print(
      '✅ ArchivedTasks: Optimistic update - task removed from UI instantly',
    );

    // Show immediate feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('جاري استعادة "${task.title}"...'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 1),
        ),
      );
    }

    try {
      // Restore task in background
      final success = await ref
          .read(tasksProvider.notifier)
          .restoreArchivedTask(task.id);

      if (mounted) {
        if (success) {
          print('✅ ArchivedTasks: Task restored successfully in background');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم استعادة "${task.title}" بنجاح'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          // Revert on failure
          print('❌ ArchivedTasks: Restore failed - reverting');
          setState(() {
            _archivedTasks.insert(taskIndex, removedTask);
            _cachedAllTasks.add(removedTask);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('فشل استعادة التاسك'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ ArchivedTasks: Restore error - $e');
      // Revert on error
      if (mounted) {
        setState(() {
          _archivedTasks.insert(taskIndex, removedTask);
          _cachedAllTasks.add(removedTask);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الاستعادة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cleanupOldTasks() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('تنظيف التاسكات القديمة'),
            content: const Text(
              'هل تريد حذف جميع التاسكات المؤرشفة الأقدم من 30 يوم؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text(
                  'تنظيف',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      final success =
          await ref.read(tasksProvider.notifier).cleanupOldArchivedTasks();

      if (mounted) {
        if (success) {
          // Invalidate cache and reload
          _lastFetchTime = null;
          await _loadArchivedTasks(forceRefresh: true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تنظيف التاسكات القديمة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لا توجد تاسكات قديمة للحذف'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileState = ref.watch(userProfileProvider);
    final userId = userProfileState.loggedInUserProfile?.id;
    final connectivityStatus = ref.watch(connectivityStatusProvider);
    final isOffline = connectivityStatus.when(
      data: (isOnline) => !isOnline,
      loading: () => false,
      error: (_, __) => false,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.black),
          ),
          title: Text(
            'التاسكات المؤرشفة',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.heading),
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
          actions: [
            if (_archivedTasks.isNotEmpty)
              IconButton(
                onPressed: _cleanupOldTasks,
                icon: const Icon(Icons.cleaning_services, color: Colors.orange),
                tooltip: 'تنظيف التاسكات القديمة',
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Offline indicator
              if (isOffline) _buildOfflineIndicator(),

              // Main content
              Expanded(
                child:
                    _isLoading
                        ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Colors.black),
                              SizedBox(height: 16),
                              Text('جاري تحميل التاسكات المؤرشفة...'),
                            ],
                          ),
                        )
                        : _archivedTasks.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                          onRefresh:
                              () => _loadArchivedTasks(forceRefresh: true),
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.all(
                                Responsive.space(context, size: Space.medium),
                              ),
                              itemCount:
                                  _archivedTasks.length +
                                  (_isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                // Show loading indicator at the end
                                if (index == _archivedTasks.length) {
                                  return Padding(
                                    padding: EdgeInsets.all(
                                      Responsive.space(
                                        context,
                                        size: Space.large,
                                      ),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.black,
                                      ),
                                    ),
                                  );
                                }

                                final task = _archivedTasks[index];
                                return _buildArchivedTaskCard(task, userId);
                              },
                            ),
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineIndicator() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.medium),
        vertical: Responsive.space(context, size: Space.small),
      ),
      color: Colors.orange.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 16, color: Colors.orange.shade900),
          SizedBox(width: 8),
          Text(
            'لا يوجد اتصال - عرض البيانات المحفوظة',
            style: TextStyle(
              color: Colors.orange.shade900,
              fontSize: Responsive.text(context, size: TextSize.small),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(
              Responsive.space(context, size: Space.xlarge),
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.archive_outlined,
              size: Responsive.space(context, size: Space.xlarge) * 2,
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: Responsive.space(context, size: Space.large)),
          Text(
            'لا توجد تاسكات مؤرشفة',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.heading),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          Text(
            'التاسكات المكتملة سيتم أرشفتها هنا',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.medium),
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchivedTaskCard(Task task, String? userId) {
    return Container(
      margin: EdgeInsets.only(
        bottom: Responsive.space(context, size: Space.medium),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Opacity(
        opacity: 0.7,
        child: TaskModel(
          task: task,
          admin: false,
          // Checkbox is enabled - clicking restores the task
          onStatusChanged: () => _restoreTask(task),
          onEdit: () {}, // Disabled for archived tasks
          onDelete: () {}, // Disabled for archived tasks
        ),
      ),
    );
  }
}
