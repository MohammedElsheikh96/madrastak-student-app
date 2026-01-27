import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

class NotificationDropdown extends StatefulWidget {
  final VoidCallback onClose;
  final void Function(AppNotification notification)? onNotificationTap;

  const NotificationDropdown({
    super.key,
    required this.onClose,
    this.onNotificationTap,
  });

  @override
  State<NotificationDropdown> createState() => _NotificationDropdownState();
}

class _NotificationDropdownState extends State<NotificationDropdown>
    with SingleTickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    // Start animation
    _animationController.forward();

    // Load notifications
    _loadNotifications();

    // Setup scroll listener for infinite scroll
    _scrollController.addListener(_onScroll);

    // Mark all as read when dropdown opens
    _markAllAsReadOnOpen();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _notificationService.loadMoreNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    await _notificationService.refreshNotifications();
  }

  Future<void> _markAllAsReadOnOpen() async {
    // Small delay to let dropdown animate in
    await Future.delayed(const Duration(milliseconds: 300));
    await _notificationService.markAllAsRead();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: widget.onClose,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withValues(alpha: 0.3),
          child: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 60,
                  left: 16,
                  right: 16,
                ),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      alignment: Alignment.topCenter,
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: GestureDetector(
                    onTap: () {}, // Prevent tap from closing dropdown
                    child: _buildDropdownContent(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownContent() {
    final mediaQuery = MediaQuery.of(context);
    final availableHeight = mediaQuery.size.height - 60 - 32 - mediaQuery.padding.bottom;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: availableHeight * 0.7,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Flexible(child: _buildNotificationList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'الإشعارات',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          GestureDetector(
            onTap: () {
              _notificationService.markAllAsRead();
            },
            child: const Text(
              'تحديد الكل كمقروء',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF0F6EB7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    return ListenableBuilder(
      listenable: _notificationService,
      builder: (context, child) {
        final groupedNotifications = _notificationService.groupedNotifications;
        final isLoading = _notificationService.isLoading;

        if (isLoading && groupedNotifications.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: Color(0xFF0F6EB7)),
            ),
          );
        }

        if (groupedNotifications.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          controller: _scrollController,
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: groupedNotifications.length + (isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == groupedNotifications.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF0F6EB7),
                    ),
                  ),
                ),
              );
            }

            return _buildNotificationItem(groupedNotifications[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          const Text(
            'لا توجد إشعارات جديدة',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(GroupedNotification groupedNotification) {
    final notification = groupedNotification.latestNotification;
    final isGrouped = groupedNotification.count > 1;

    return GestureDetector(
      onTap: () {
        if (!notification.isRead) {
          _notificationService.markAsRead(notification.id);
        }
        widget.onNotificationTap?.call(notification);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: groupedNotification.isRead
              ? Colors.transparent
              : const Color(0xFFF5F9FF),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification type icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getNotificationColor(notification.referenceType)
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getNotificationIcon(notification.referenceType),
                color: _getNotificationColor(notification.referenceType),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Body text
                  Text(
                    isGrouped
                        ? groupedNotification.groupedBodyText
                        : _buildNotificationText(notification),
                    style: TextStyle(
                      fontSize: 14,
                      color: groupedNotification.isRead
                          ? const Color(0xFF757575)
                          : const Color(0xFF333333),
                      fontWeight: groupedNotification.isRead
                          ? FontWeight.normal
                          : FontWeight.w500,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Time
                  Text(
                    notification.timeAgo,
                    style: TextStyle(
                      fontSize: 12,
                      color: groupedNotification.isRead
                          ? const Color(0xFF9E9E9E)
                          : const Color(0xFF0F6EB7),
                    ),
                  ),
                ],
              ),
            ),
            // Unread indicator
            if (!groupedNotification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6, right: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F6EB7),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _buildNotificationText(AppNotification notification) {
    if (notification.senderName != null) {
      return '${notification.senderName} ${notification.body}';
    }
    return notification.body.isNotEmpty ? notification.body : notification.title;
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.comment:
        return Icons.chat_bubble_outline;
      case NotificationType.like:
        return Icons.favorite_outline;
      case NotificationType.post:
        return Icons.article_outlined;
      case NotificationType.poll:
        return Icons.poll_outlined;
      case NotificationType.system:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.comment:
        return const Color(0xFF0F6EB7);
      case NotificationType.like:
        return const Color(0xFFE91E63);
      case NotificationType.post:
        return const Color(0xFF4CAF50);
      case NotificationType.poll:
        return const Color(0xFFFF9800);
      case NotificationType.system:
        return const Color(0xFF9E9E9E);
    }
  }
}

/// Bell icon widget with unread badge
class NotificationBellIcon extends StatelessWidget {
  final VoidCallback onTap;

  const NotificationBellIcon({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF757575),
              size: 26,
            ),
            // Badge
            StreamBuilder<int>(
              stream: notificationService.unreadCountStream,
              initialData: notificationService.unreadCount,
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                if (count == 0) return const SizedBox.shrink();

                return Positioned(
                  top: -4,
                  left: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE91E63),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
