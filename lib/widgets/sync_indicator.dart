import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/services/offline_queue_service.dart';
import 'package:pivot/services/offline_service.dart';
import 'package:pivot/responsive.dart';

/// Shows a small indicator when there are pending operations to sync
class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final queueCount = OfflineQueueService().getQueueCount();

    // Only show if offline and have pending operations
    if (isOnline || queueCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.small),
        vertical: Responsive.space(context, size: Space.tiny),
      ),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.small),
        ),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sync, size: 14, color: Colors.blue.shade700),
          SizedBox(width: Responsive.space(context, size: Space.tiny)),
          Text(
            '$queueCount عملية معلقة',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: Responsive.text(context, size: TextSize.small),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full sync status banner with sync button
class SyncStatusBanner extends ConsumerStatefulWidget {
  const SyncStatusBanner({super.key});

  @override
  ConsumerState<SyncStatusBanner> createState() => _SyncStatusBannerState();
}

class _SyncStatusBannerState extends ConsumerState<SyncStatusBanner> {
  bool _isSyncing = false;

  Future<void> _triggerManualSync() async {
    setState(() => _isSyncing = true);

    try {
      final queueService = OfflineQueueService();

      await queueService.processQueue(
        processor: (operation) async {
          // Process based on operation type
          print('📦 Processing: ${operation.type}');
          // The actual sync logic will be implemented by providers
          // For now, we'll just simulate success
          await Future.delayed(const Duration(milliseconds: 100));
        },
        onProgress: (completed, total) {
          print('⏳ Sync: $completed/$total');
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم المزامنة بنجاح'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.large),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشلت المزامنة: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.large),
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider);
    final queueCount = OfflineQueueService().getQueueCount();

    // Only show if online and have pending operations
    if (!isOnline || queueCount == 0) {
      return const SizedBox.shrink();
    }

    return Material(
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: Responsive.space(context, size: Space.small),
          horizontal: Responsive.space(context, size: Space.medium),
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.blue.shade700],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Sync button
              ElevatedButton.icon(
                onPressed: _isSyncing ? null : _triggerManualSync,
                icon:
                    _isSyncing
                        ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue.shade700,
                            ),
                          ),
                        )
                        : Icon(Icons.sync, size: 16),
                label: Text(
                  'مزامنة',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.small),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue.shade700,
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.space(context, size: Space.medium),
                    vertical: Responsive.space(context, size: Space.tiny),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.small),
                    ),
                  ),
                ),
              ),

              // Status text
              Row(
                children: [
                  Icon(Icons.cloud_upload, size: 16, color: Colors.white),
                  SizedBox(width: Responsive.space(context, size: Space.small)),
                  Text(
                    '$queueCount عملية بانتظار المزامنة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.text(context, size: TextSize.small),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
