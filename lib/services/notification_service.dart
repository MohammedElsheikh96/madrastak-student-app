import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/notification.dart';
import '../config/azure_ad_config.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Temporary static token - same as in ApiClient
  static const String _staticToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1bmlxdWVfbmFtZSI6IjJiODVmZTk2LTU3ZjgtNDBiNi05NjAxLTMyYTA3Mjg4NmUxMSIsImh0dHA6Ly9zY2hlbWFzLm1pY3Jvc29mdC5jb20vd3MvMjAwOC8wNi9pZGVudGl0eS9jbGFpbXMvdXNlcmRhdGEiOiJjNTA2MTY3My01YjVmLTRlNWUtYWI3OC1kOWY1MWVlZjNkZDIiLCJuYW1lIjoi2LnYqNiv2KfZhNmH2KfYr9mJINmF2K3ZhdivINi52KjYr9in2YTZh9in2K_ZiSDYudmE2Ykg2KfZhNi02YrZiNmJIiwiZW1haWwiOiIxNDU0MUBzYWJyb2FkLm1vZS5lZHUuZWciLCJwaG9uZV9udW1iZXIiOiIiLCJwcm9maWxlX3BpY3R1cmVfdXJsIjoiIiwic3RhZ2VfbmFtZSI6Itin2YTYqti52YTZitmFINin2YTYp9i52K_Yp9iv2YogIiwiZ3JhZGVfbmFtZSI6Itin2YTYtdmBINin2YTYq9in2YbZiiDYp9mE2KfYudiv2KfYr9mKIiwiY291bnRyeV9uYW1lIjoi2KXZiti32KfZhNmK2KciLCJuYmYiOjE3Njk1MTQ3MTEsImV4cCI6MTc2OTg2MDMxMSwiaWF0IjoxNzY5NTE0NzExfQ.uLbi6Ih3MsUq-Hyastmj2HP7IPpw9EgGz01gvsi3NiY';

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_staticToken',
    };
  }

  List<AppNotification> _notifications = [];
  List<GroupedNotification> _groupedNotifications = [];
  int _totalCount = 0;
  int _unreadCount = 0;
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  static const int _pageSize = 20;

  // Getters
  List<AppNotification> get notifications => _notifications;
  List<GroupedNotification> get groupedNotifications => _groupedNotifications;
  int get totalCount => _totalCount;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  // Stream controller for real-time unread count updates
  final StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  Future<void> getMyNotifications({
    int page = 1,
    int pageSize = _pageSize,
    bool append = false,
  }) async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final headers = _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.tawasolApiUrl}/Notification/GetMyNotifications?pageNumber=$page&pageSize=$pageSize'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final notificationResponse = NotificationsApiResponse.fromJson(jsonData);

        if (append) {
          _notifications.addAll(notificationResponse.items);
        } else {
          _notifications = notificationResponse.items;
        }

        _totalCount = notificationResponse.totalCount;
        _unreadCount = notificationResponse.unreadCount;
        _currentPage = page;
        _hasMore = _notifications.length < _totalCount;

        // Update grouped notifications
        _groupNotifications();

        // Notify unread count stream
        _unreadCountController.add(_unreadCount);
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshNotifications() async {
    _currentPage = 1;
    _hasMore = true;
    await getMyNotifications(page: 1, append: false);
  }

  Future<void> loadMoreNotifications() async {
    if (!_hasMore || _isLoading) return;
    await getMyNotifications(page: _currentPage + 1, append: true);
  }

  bool hasMoreNotifications() => _hasMore;

  Future<bool> markAsRead(String notificationId) async {
    try {
      final headers = _getHeaders();
      final response = await http.patch(
        Uri.parse('${ApiConfig.tawasolApiUrl}/Notification/MarkAsRead'),
        headers: headers,
        body: jsonEncode({'id': notificationId}),
      );

      if (response.statusCode == 200) {
        // Update local state
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1 && !_notifications[index].isRead) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
          _unreadCount = (_unreadCount - 1).clamp(0, _totalCount);
          _groupNotifications();
          _unreadCountController.add(_unreadCount);
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
    return false;
  }

  Future<bool> markAllAsRead() async {
    try {
      final headers = _getHeaders();
      final response = await http.patch(
        Uri.parse('${ApiConfig.tawasolApiUrl}/Notification/MarkAllAsRead'),
        headers: headers,
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        // Update local state
        _notifications = _notifications
            .map((n) => n.copyWith(isRead: true))
            .toList();
        _unreadCount = 0;
        _groupNotifications();
        _unreadCountController.add(_unreadCount);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
    return false;
  }

  Future<bool> registerDevice(String token, String deviceType) async {
    try {
      final headers = _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.tawasolApiUrl}/UserDevice/Register'),
        headers: headers,
        body: jsonEncode({
          'deviceToken': token,
          'deviceType': deviceType,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error registering device: $e');
      return false;
    }
  }

  void addNotification(AppNotification notification) {
    // Add to the beginning of the list
    _notifications.insert(0, notification);
    _totalCount++;
    if (!notification.isRead) {
      _unreadCount++;
      _unreadCountController.add(_unreadCount);
    }
    _groupNotifications();
    notifyListeners();
  }

  void _groupNotifications() {
    final Map<String, List<AppNotification>> groupedByPost = {};
    final List<GroupedNotification> result = [];

    for (final notification in _notifications) {
      // Only group likes by postId
      if (notification.referenceType == NotificationType.like) {
        final postId = notification.notificationDetails?.postId ??
            notification.refrenceId ??
            notification.id;
        final key = 'like_$postId';

        if (!groupedByPost.containsKey(key)) {
          groupedByPost[key] = [];
        }
        groupedByPost[key]!.add(notification);
      } else {
        // Don't group other types
        result.add(GroupedNotification(
          type: notification.referenceType,
          postId: notification.notificationDetails?.postId,
          notifications: [notification],
          count: 1,
          senderNames: notification.senderName != null
              ? [notification.senderName!]
              : [],
          isRead: notification.isRead,
        ));
      }
    }

    // Convert grouped likes to GroupedNotification
    for (final entry in groupedByPost.entries) {
      final notifications = entry.value;
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final senderNames = notifications
          .where((n) => n.senderName != null)
          .map((n) => n.senderName!)
          .toSet()
          .take(3)
          .toList();

      final allRead = notifications.every((n) => n.isRead);

      result.add(GroupedNotification(
        type: NotificationType.like,
        postId: entry.key.replaceFirst('like_', ''),
        notifications: notifications,
        count: notifications.length,
        senderNames: senderNames,
        isRead: allRead,
      ));
    }

    // Sort by latest notification time
    result.sort((a, b) =>
        b.latestNotification.createdAt.compareTo(a.latestNotification.createdAt));

    _groupedNotifications = result;
  }

  @override
  void dispose() {
    _unreadCountController.close();
    super.dispose();
  }
}
