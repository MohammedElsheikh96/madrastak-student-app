import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../widgets/post_card.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  final ScrollController _scrollController = ScrollController();
  String _currentUserName = 'مستخدم';
  String? _currentUserImage;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadUserData();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadUserData() async {
    final studentData = await _authService.getStudentData();
    if (mounted && studentData != null) {
      setState(() {
        _currentUserName = studentData.userBasicInfo.name ?? 'مستخدم';
        _currentUserImage = studentData.userBasicInfo.profilePicture;
        _currentUserId = studentData.id;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _markAsRead(String notificationId) async {
    await _notificationService.markAsRead(notificationId);
  }

  Future<void> _markAllAsRead() async {
    await _notificationService.markAllAsRead();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'الإشعارات',
          style: GoogleFonts.alexandria(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        centerTitle: true,
        actions: [
          ListenableBuilder(
            listenable: _notificationService,
            builder: (context, child) {
              final hasUnread = _notificationService.unreadCount > 0;
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton(
                onPressed: _markAllAsRead,
                child: Text(
                  'قراءة الكل',
                  style: GoogleFonts.alexandria(
                    fontSize: 14,
                    color: const Color(0xFF0F6EB7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _notificationService,
        builder: (context, child) {
          final notifications = _notificationService.notifications;
          final isLoading = _notificationService.isLoading;

          if (isLoading && notifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0F6EB7)),
            );
          }

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          final bottomPadding = MediaQuery.of(context).padding.bottom;
          return RefreshIndicator(
            onRefresh: _loadNotifications,
            color: const Color(0xFF0F6EB7),
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.only(top: 8, bottom: 8 + bottomPadding),
              itemCount: notifications.length + (isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == notifications.length) {
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
                return _buildNotificationItem(notifications[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد إشعارات',
            style: GoogleFonts.alexandria(
              fontSize: 16,
              color: const Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(AppNotification notification) {
    return GestureDetector(
      onTap: () {
        if (!notification.isRead) {
          _markAsRead(notification.id);
        }
        _handleNotificationTap(notification);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : const Color(0xFFE8F4FD),
          borderRadius: BorderRadius.circular(12),
          border: notification.isRead
              ? null
              : Border.all(color: const Color(0xFF0F6EB7).withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification type icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getNotificationColor(notification.referenceType)
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getNotificationIcon(notification.referenceType),
                color: _getNotificationColor(notification.referenceType),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sender name and content
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.alexandria(
                        fontSize: 14,
                        color: const Color(0xFF333333),
                        height: 1.4,
                      ),
                      children: [
                        if (notification.senderName != null) ...[
                          TextSpan(
                            text: notification.senderName,
                            style: GoogleFonts.alexandria(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: ' '),
                        ],
                        TextSpan(
                          text: notification.body.isNotEmpty
                              ? notification.body
                              : notification.title,
                          style: GoogleFonts.alexandria(
                            color: notification.isRead
                                ? const Color(0xFF757575)
                                : const Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Time
                  Text(
                    notification.timeAgo,
                    style: GoogleFonts.alexandria(
                      fontSize: 12,
                      color: notification.isRead
                          ? const Color(0xFF9E9E9E)
                          : const Color(0xFF0F6EB7),
                      fontWeight:
                          notification.isRead ? FontWeight.normal : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Unread indicator
            if (!notification.isRead)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
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

  void _handleNotificationTap(AppNotification notification) {
    // Extract post ID from notification
    final postId = notification.notificationDetails?.postId ?? notification.refrenceId;

    // If we have a postId, open the SinglePostSheet
    if (postId != null && postId.isNotEmpty) {
      _showSinglePostSheet(postId);
    }
  }

  void _showSinglePostSheet(String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SinglePostSheet(
        postId: postId,
        currentUserName: _currentUserName,
        currentUserImage: _currentUserImage,
        currentUserId: _currentUserId,
        onPostDeleted: _loadNotifications,
      ),
    );
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
