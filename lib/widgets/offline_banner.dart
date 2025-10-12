import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/services/offline_service.dart';
import 'package:pivot/services/offline_queue_service.dart';
import 'package:pivot/responsive.dart';

/// Reusable offline banner that shows connectivity status
/// and pending operations count
class OfflineBanner extends ConsumerStatefulWidget {
  final bool showPendingCount;
  final VoidCallback? onTap;

  const OfflineBanner({super.key, this.showPendingCount = true, this.onTap});

  @override
  ConsumerState<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends ConsumerState<OfflineBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  bool _wasOnline = true;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectivityStatus = ref.watch(connectivityStatusProvider);

    return connectivityStatus.when(
      data: (isOnline) {
        // Handle online → offline transition
        if (_wasOnline && !isOnline) {
          _isDismissed = false;
          _controller.forward();
        }

        // Handle offline → online transition
        if (!_wasOnline && isOnline) {
          // Show "back online" message briefly then dismiss
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              _controller.reverse().then((_) {
                if (mounted) {
                  setState(() {
                    _isDismissed = true;
                  });
                }
              });
            }
          });
        }

        _wasOnline = isOnline;

        // Don't show if dismissed or online
        if (_isDismissed || (isOnline && _wasOnline)) {
          return const SizedBox.shrink();
        }

        return AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value * 60),
              child: child,
            );
          },
          child: _buildBanner(isOnline),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildBanner(bool isOnline) {
    final queueService = OfflineQueueService();
    final pendingCount =
        widget.showPendingCount ? queueService.getQueueCount() : 0;

    final backgroundColor =
        isOnline ? Colors.green.shade100 : Colors.orange.shade100;
    final iconColor = isOnline ? Colors.green.shade900 : Colors.orange.shade900;
    final textColor = isOnline ? Colors.green.shade900 : Colors.orange.shade900;
    final icon = isOnline ? Icons.cloud_done : Icons.cloud_off;
    final message =
        isOnline ? 'تم الاتصال بالإنترنت' : 'لا يوجد اتصال بالإنترنت';

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.space(context, size: Space.medium),
          vertical: Responsive.space(context, size: Space.small),
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: iconColor),
            SizedBox(width: Responsive.space(context, size: Space.small)),
            Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: Responsive.text(context, size: TextSize.small),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!isOnline && pendingCount > 0) ...[
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.space(context, size: Space.small),
                  vertical: Responsive.space(context, size: Space.tiny),
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$pendingCount عملية معلقة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.text(context, size: TextSize.small),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            if (widget.onTap != null) ...[
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Icon(Icons.arrow_forward_ios, size: 12, color: iconColor),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact offline indicator for small spaces (e.g., in cards)
class OfflineIndicator extends ConsumerWidget {
  final double? size;

  const OfflineIndicator({super.key, this.size});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityStatus = ref.watch(connectivityStatusProvider);

    return connectivityStatus.when(
      data: (isOnline) {
        if (isOnline) return const SizedBox.shrink();

        return Container(
          padding: EdgeInsets.all(Responsive.space(context, size: Space.tiny)),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.orange.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off,
                size: size ?? 12,
                color: Colors.orange.shade700,
              ),
              SizedBox(width: 4),
              Text(
                'غير متصل',
                style: TextStyle(
                  fontSize: size ?? 10,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
