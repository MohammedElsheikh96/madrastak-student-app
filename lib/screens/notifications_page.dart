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

  int _selectedFilter = 0; // 0 = all, 1 = academic, 2 = social

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

  void _onFilterChanged(int filter) {
    if (_selectedFilter == filter) return;
    setState(() {
      _selectedFilter = filter;
    });
    // null = all, 1 = academic, 2 = social
    int? filterType;
    if (filter == 1) filterType = 1;
    if (filter == 2) filterType = 2;
    _notificationService.refreshWithFilter(filterType);
  }

  Future<void> _markAllAsRead() async {
    await _notificationService.markAllAsRead();
  }

  Future<void> _clearAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.delete_forever, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                'مسح السجل',
                style: GoogleFonts.alexandria(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'هل أنت متأكد من مسح جميع الإشعارات؟',
            style: GoogleFonts.alexandria(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'إلغاء',
                style: GoogleFonts.alexandria(color: const Color(0xFF757575)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'مسح الكل',
                style: GoogleFonts.alexandria(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await _notificationService.clearAllNotifications();
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    await _notificationService.deleteNotification(notificationId);
  }

  void _handleGroupedNotificationTap(GroupedNotification grouped) {
    // Mark all unread notifications in group as read
    for (final n in grouped.notifications) {
      if (!n.isRead) {
        _notificationService.markAsRead(n.id);
      }
    }
    final postId = grouped.postId ?? grouped.latestNotification.refrenceId;
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildActionButtons(),
              _buildFilterTabs(),
              const Divider(height: 1, color: Color(0xFFE0E0E0)),
              Expanded(child: _buildNotificationList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: ListenableBuilder(
              listenable: _notificationService,
              builder: (context, child) {
                final unreadCount = _notificationService.unreadCount;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مركز التنبيهات',
                      style: GoogleFonts.alexandria(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (unreadCount > 0)
                      Text(
                        'لديك $unreadCount تنبيهات غير مقروءة',
                        style: GoogleFonts.alexandria(
                          fontSize: 13,
                          color: const Color(0xFF757575),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.close,
                color: Color(0xFF333333),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Clear history button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _clearAllNotifications,
              icon: const Icon(Icons.delete_outline, size: 17),
              label: Text(
                'مسح السجل',
                style: GoogleFonts.alexandria(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Mark all as read button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, size: 17),
              label: Text(
                'تحديد الكل كمقروء',
                style: GoogleFonts.alexandria(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF757575),
                side: const BorderSide(color: Color(0xFFBDBDBD), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterPill('الكل', 0),
          const SizedBox(width: 10),
          _buildFilterPill('أكاديمي', 1),
          const SizedBox(width: 10),
          _buildFilterPill('اجتماعي', 2),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String label, int filterIndex) {
    final isSelected = _selectedFilter == filterIndex;
    return GestureDetector(
      onTap: () => _onFilterChanged(filterIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F6EB7) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0F6EB7)
                : const Color(0xFFBDBDBD),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.alexandria(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : const Color(0xFF757575),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationList() {
    return ListenableBuilder(
      listenable: _notificationService,
      builder: (context, child) {
        final grouped = _notificationService.groupedNotifications;
        final isLoading = _notificationService.isLoading;

        if (isLoading && grouped.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF0F6EB7)),
          );
        }

        if (grouped.isEmpty) {
          return _buildEmptyState();
        }

        final bottomPadding = MediaQuery.of(context).padding.bottom;
        return RefreshIndicator(
          onRefresh: _loadNotifications,
          color: const Color(0xFF0F6EB7),
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.only(bottom: 8 + bottomPadding),
            itemCount: grouped.length + (isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == grouped.length) {
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
              return _buildGroupedNotificationItem(grouped[index]);
            },
          ),
        );
      },
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

  Widget _buildGroupedNotificationItem(GroupedNotification grouped) {
    final notification = grouped.latestNotification;
    final isUnread = !grouped.isRead;
    final iconData = _getNotificationIcon(grouped.type);
    final iconBgColor = _getNotificationBgColor(grouped.type);
    final iconColor = _getNotificationColor(grouped.type);
    final hasDetails = notification.notificationDetails?.space != null;

    return GestureDetector(
      onTap: () => _handleGroupedNotificationTap(grouped),
      child: Container(
        color: isUnread ? const Color(0xFFE8F4FD) : Colors.white,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Unread colored left border strip
              if (isUnread)
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                ),
              // Main content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: isUnread ? 12 : 16,
                    left: 16,
                    top: 14,
                    bottom: 14,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type icon circle
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(iconData, color: iconColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title row with time
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: GoogleFonts.alexandria(
                                      fontSize: 14,
                                      fontWeight: isUnread
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: const Color(0xFF333333),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  notification.timeAgo,
                                  style: GoogleFonts.alexandria(
                                    fontSize: 11,
                                    color: const Color(0xFF9E9E9E),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Body text
                            Text(
                              grouped.count > 1
                                  ? grouped.groupedBodyText
                                  : notification.body.isNotEmpty
                                  ? notification.body
                                  : notification.title,
                              style: GoogleFonts.alexandria(
                                fontSize: 13,
                                color: const Color(0xFF757575),
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // "عرض التفاصيل" link
                            if (hasDetails) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    'عرض التفاصيل',
                                    style: GoogleFonts.alexandria(
                                      fontSize: 12,
                                      color: const Color(0xFF0F6EB7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.open_in_new,
                                    size: 14,
                                    color: Color(0xFF0F6EB7),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Delete button
                      GestureDetector(
                        onTap: () => _deleteNotification(notification.id),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFAFA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Color(0xFFBDBDBD),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.comment:
        return Icons.chat_bubble_outline;
      case NotificationType.like:
        return Icons.favorite;
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
        return const Color(0xFF4CAF50);
      case NotificationType.like:
        return const Color(0xFFE91E63);
      case NotificationType.post:
        return const Color(0xFF0F6EB7);
      case NotificationType.poll:
        return const Color(0xFFFF9800);
      case NotificationType.system:
        return const Color(0xFF9E9E9E);
    }
  }

  Color _getNotificationBgColor(NotificationType type) {
    switch (type) {
      case NotificationType.comment:
        return const Color(0xFFE0F5E8);
      case NotificationType.like:
        return const Color(0xFFFFE0E8);
      case NotificationType.post:
        return const Color(0xFFE3F2FD);
      case NotificationType.poll:
        return const Color(0xFFFFF3E0);
      case NotificationType.system:
        return const Color(0xFFF5F5F5);
    }
  }
}
