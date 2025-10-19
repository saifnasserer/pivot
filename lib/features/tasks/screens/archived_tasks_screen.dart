import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/tasks/providers/tasks_provider.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:pivot/services/offline_service.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/task.dart';
import 'package:pivot/screens/models/task_model.dart';
import 'package:pivot/widgets/unified_dialog.dart';

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
  bool _isServerPagination = false; // Track if we're using server pagination

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
    final position = _scrollController.position;
    final threshold = position.maxScrollExtent * 0.85; // Load when 85% scrolled

    if (position.pixels >= threshold && !_isLoadingMore && _hasMore) {
      print('📜 ArchivedTasks: Scroll threshold reached - loading more tasks');
      _loadMoreTasks();
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
        _isLoadingMore = false;
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
          _isLoadingMore = false;
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
      _isLoadingMore = false;
    });

    try {
      print('🌐 ArchivedTasks: Fetching from server...');
      final allTasks =
          await ref.read(tasksProvider.notifier).getAllArchivedTasks();

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

    try {
      if (_isServerPagination) {
        // Server-side pagination - fetch next page from server
        print('🌐 ArchivedTasks: Loading page $_currentPage from server...');

        // TODO: Implement server-side pagination when backend supports it
        // For now, fall back to client-side pagination
        await _loadMoreFromCache();
      } else {
        // Client-side pagination - use cached data
        await _loadMoreFromCache();
      }
    } catch (e) {
      print('❌ ArchivedTasks: Error loading more tasks - $e');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل المزيد: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _loadMoreFromCache() async {
    // Simulate loading delay for better UX
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() {
        _currentPage++;
        final startIndex = _currentPage * _pageSize;
        final endIndex = startIndex + _pageSize;

        if (startIndex < _cachedAllTasks.length) {
          final newTasks =
              _cachedAllTasks.skip(startIndex).take(_pageSize).toList();
          _archivedTasks.addAll(newTasks);
          _hasMore = endIndex < _cachedAllTasks.length;
          print(
            '📄 ArchivedTasks: Loaded page $_currentPage (${newTasks.length} tasks) from cache',
          );
        } else {
          _hasMore = false;
          print('📄 ArchivedTasks: No more tasks to load');
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
      bool success = false;

      if (task.isPersonal) {
        // Personal task - restore from archive
        print('📦 ArchivedTasks: Restoring personal task from archive');
        success = await ref
            .read(tasksProvider.notifier)
            .restoreArchivedTask(task.id);
      } else {
        // Global task - just remove user from completedBy
        print('🌐 ArchivedTasks: Uncompleting global task');
        await ref.read(tasksProvider.notifier).toggleTaskCompletion(task.id);
        success = true; // toggleTaskCompletion handles the completion
      }

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

  Future<void> _cleanupArchive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => UnifiedDialog(
            title: 'تنظيف الأرشيف',
            subtitle:
                'سيتم حذف جميع التاسكات المؤرشفة الأقدم من 7 أيام نهائياً',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange[600],
                  size: Responsive.space(context, size: Space.xlarge),
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                Text(
                  'لا يمكن التراجع عن هذا الإجراء',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            onCancel: () => Navigator.of(context).pop(false),
            onConfirm: () => Navigator.of(context).pop(true),
            cancelText: 'إلغاء',
            confirmText: 'تنظيف',
            confirmIcon: Icons.cleaning_services,
          ),
    );

    if (confirmed != true) return;

    try {
      final success = await ref
          .read(tasksProvider.notifier)
          .cleanupOldArchivedTasks(daysToKeep: 7);

      if (mounted) {
        if (success) {
          // Invalidate cache and reload
          _lastFetchTime = null;
          await _loadArchivedTasks(forceRefresh: true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تنظيف الأرشيف بنجاح'),
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
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.white,
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
              Container(
                margin: EdgeInsets.only(
                  right: Responsive.space(context, size: Space.small),
                ),
                child: IconButton(
                  onPressed: _cleanupArchive,
                  icon: const Icon(
                    Icons.cleaning_services,
                    color: Colors.orange,
                  ),
                  tooltip: 'تنظيف الأرشيف',
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Header section with stats
              _buildHeaderSection(),

              // Offline indicator
              if (isOffline) _buildOfflineIndicator(),

              // Main content
              Expanded(
                child:
                    _isLoading
                        ? _buildLoadingState()
                        : _archivedTasks.isEmpty
                        ? _buildEmptyState()
                        : _buildTasksList(userId),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build modern header section with stats
  Widget _buildHeaderSection() {
    return Column(
      children: [
        // Main header
        Container(
          margin: EdgeInsets.all(Responsive.space(context, size: Space.medium)),
          padding: EdgeInsets.all(Responsive.space(context, size: Space.large)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Colors.green.withOpacity(0.1),
                Colors.green.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.large),
            ),
            border: Border.all(color: Colors.green.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  Responsive.space(context, size: Space.medium),
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.medium),
                  ),
                ),
                child: Icon(
                  Icons.celebration,
                  color: Colors.green[700],
                  size: Responsive.space(context, size: Space.xlarge),
                ),
              ),
              SizedBox(width: Responsive.space(context, size: Space.medium)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إنجازاتك الشخصية',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.heading,
                        ),
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.tiny),
                    ),
                    Text(
                      '${_archivedTasks.length} تاسك شخصي مكتمل',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        color: Colors.green[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (_archivedTasks.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.space(context, size: Space.small),
                    vertical: Responsive.space(context, size: Space.tiny),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.small),
                    ),
                  ),
                  child: Text(
                    '${_archivedTasks.length}',
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.small),
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build modern loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(
              Responsive.space(context, size: Space.xlarge),
            ),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              color: Colors.blue[700],
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: Responsive.space(context, size: Space.large)),
          Text(
            'جاري تحميل التاسكات المؤرشفة...',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.medium),
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build modern tasks list
  Widget _buildTasksList(String? userId) {
    return RefreshIndicator(
      onRefresh: () => _loadArchivedTasks(forceRefresh: true),
      color: Colors.blue[700],
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.space(context, size: Space.medium),
            vertical: Responsive.space(context, size: Space.small),
          ),
          itemCount: _archivedTasks.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            // Show loading indicator at the end
            if (index == _archivedTasks.length) {
              return _buildPaginationLoader();
            }

            final task = _archivedTasks[index];
            return _buildArchivedTaskCard(task, userId);
          },
        ),
      ),
    );
  }

  Widget _buildOfflineIndicator() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.medium),
        vertical: Responsive.space(context, size: Space.small),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.medium),
        vertical: Responsive.space(context, size: Space.small),
      ),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 16, color: Colors.orange.shade700),
          SizedBox(width: Responsive.space(context, size: Space.small)),
          Text(
            'لا يوجد اتصال - عرض البيانات المحفوظة',
            style: TextStyle(
              color: Colors.orange.shade700,
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
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Colors.blue.withOpacity(0.1),
                  Colors.blue.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue.withOpacity(0.2), width: 2),
            ),
            child: Icon(
              Icons.archive_outlined,
              size: Responsive.space(context, size: Space.xlarge) * 2,
              color: Colors.blue[400],
            ),
          ),
          SizedBox(height: Responsive.space(context, size: Space.large)),
          Text(
            'لا توجد إنجازات شخصية بعد',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.heading),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          Text(
            'أكمل التاسكات الشخصية لرؤية إنجازاتك هنا',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.medium),
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build pagination loading indicator
  Widget _buildPaginationLoader() {
    return Container(
      padding: EdgeInsets.all(Responsive.space(context, size: Space.large)),
      child: Column(
        children: [
          CircularProgressIndicator(color: Colors.blue[700], strokeWidth: 2),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          Text(
            'جاري تحميل المزيد...',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.small),
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
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
          Responsive.space(context, size: Space.large),
        ),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.large),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: TaskModel(
            task: task,
            admin: false,
            // Checkbox is enabled - clicking restores the task
            onStatusChanged: () => _restoreTask(task),
            onEdit: () {}, // Disabled for archived tasks
            onDelete: () {}, // Disabled for archived tasks
          ),
        ),
      ),
    );
  }
}
