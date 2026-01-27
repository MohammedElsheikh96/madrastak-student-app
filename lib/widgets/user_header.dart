import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../screens/notifications_page.dart';
import 'notification_dropdown.dart';

class UserHeader extends StatefulWidget {
  final String userName;
  final String? userImage;
  final VoidCallback? onNotificationTap;

  const UserHeader({
    super.key,
    required this.userName,
    this.userImage,
    this.onNotificationTap,
  });

  @override
  State<UserHeader> createState() => _UserHeaderState();
}

class _UserHeaderState extends State<UserHeader> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    // Load notifications on init
    _notificationService.refreshNotifications();
  }

  void _openNotificationsPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NotificationsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 12,
        right: 16,
        left: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile image on the right
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
            ),
            child: ClipOval(
              child: widget.userImage != null && widget.userImage!.isNotEmpty
                  ? Image.network(
                      widget.userImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAvatar();
                      },
                    )
                  : _buildDefaultAvatar(),
            ),
          ),
          const SizedBox(width: 12),
          // User name
          Text(
            widget.userName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const Spacer(),
          // Notification bell icon with badge
          NotificationBellIcon(
            onTap: widget.onNotificationTap ?? _openNotificationsPage,
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: const Icon(
        Icons.person_outline,
        color: Color(0xFF9E9E9E),
        size: 24,
      ),
    );
  }
}
