import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:pivot/features/administration/providers/sections_provider.dart';
import 'package:pivot/features/subjects/providers/subjects_provider.dart';
import 'package:pivot/services/offline_service.dart';
import 'package:pivot/widgets/offline_banner.dart';
import 'package:pivot/features/profile/screens/profile_widgets/sections/sections.dart';

/// Simplified SectionsTab using snapshot-based approach
/// Load once from cache, refresh manually with pull-to-refresh
class SectionsTab extends ConsumerStatefulWidget {
  const SectionsTab({super.key});

  @override
  ConsumerState<SectionsTab> createState() => _SectionsTabState();
}

class _SectionsTabState extends ConsumerState<SectionsTab>
    with AutomaticKeepAliveClientMixin {
  bool _hasInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Load sections snapshot on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasInitialized) {
        _loadSectionsSnapshot();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload sections if we were navigated away and back
    // This ensures we show the logged-in user's sections after viewing another profile
    if (_hasInitialized && mounted) {
      final sectionsState = ref.read(sectionsProvider);
      final userProfileState = ref.read(userProfileProvider);
      final loggedInUser = userProfileState.loggedInUserProfile;

      // Check if the current sections belong to a different user (e.g., after viewing assistant profile)
      if (loggedInUser != null &&
          sectionsState.currentUserId != null &&
          sectionsState.currentUserId != loggedInUser.id) {
        print(
          '🔄 [SectionsTab] Detected sections mismatch, reloading for logged-in user',
        );
        _loadSectionsSnapshot();
      }
    }
  }

  /// Load sections snapshot for logged-in user
  /// Uses cache-first approach (zero Firestore reads if cache valid)
  void _loadSectionsSnapshot() async {
    final userProfileState = ref.read(userProfileProvider);
    final loggedInUser = userProfileState.loggedInUserProfile;

    if (loggedInUser == null) {
      print('⚠️ [SectionsTab] No logged-in user found');
      return;
    }

    print('📊 [SectionsTab] Loading sections snapshot');
    print('   User: ${loggedInUser.name} (${loggedInUser.id})');
    print('   Enrolled subjects: ${loggedInUser.enrolledSubjects}');

    // Load subjects first (needed for display)
    ref.read(subjectsProvider.notifier).fetchAndFilterSubjects(loggedInUser);

    // Load sections snapshot (cache-first)
    await ref
        .read(sectionsProvider.notifier)
        .loadSectionsForUser(loggedInUser.id, loggedInUser.enrolledSubjects);

    if (mounted) {
      setState(() {
        _hasInitialized = true;
      });
    }
  }

  /// Refresh sections snapshot from Firestore
  Future<void> _refreshSectionsSnapshot() async {
    final userProfileState = ref.read(userProfileProvider);
    final loggedInUser = userProfileState.loggedInUserProfile;

    if (loggedInUser == null) {
      print('⚠️ [SectionsTab] No logged-in user found for refresh');
      return;
    }

    print('🔄 [SectionsTab] Manually refreshing sections snapshot');

    // Refresh subjects
    await ref
        .read(subjectsProvider.notifier)
        .fetchAndFilterSubjects(loggedInUser);

    // Force refresh sections from Firestore
    await ref
        .read(sectionsProvider.notifier)
        .refreshSections(loggedInUser.id, loggedInUser.enrolledSubjects);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final sectionsState = ref.watch(sectionsProvider);

    // Show loading state during initialization
    if (!_hasInitialized || sectionsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error state
    if (sectionsState.error != null && sectionsState.sections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'خطأ: ${sectionsState.error}',
              style: TextStyle(fontSize: 16, color: Colors.red.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshSectionsSnapshot,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    // Build sections list with pull-to-refresh
    return RefreshIndicator(
      onRefresh: _refreshSectionsSnapshot,
      child: Column(
        children: [
          // Offline banner
          Consumer(
            builder: (context, ref, _) {
              final connectivityStatus = ref.watch(connectivityStatusProvider);
              return connectivityStatus.when(
                data:
                    (isOnline) =>
                        isOnline
                            ? const SizedBox.shrink()
                            : const OfflineBanner(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
          // Main content
          Expanded(
            child: CustomScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(), // Enable pull-to-refresh
              slivers: [
                // Show offline indicator if using cached data
                if (sectionsState.error != null)
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      color: Colors.orange.shade100,
                      child: Row(
                        children: [
                          Icon(
                            Icons.cloud_off,
                            size: 16,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sectionsState.error!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Build sections slivers
                ...buildSectionsSlivers(context, ref),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
