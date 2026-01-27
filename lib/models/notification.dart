enum NotificationType {
  post,
  comment,
  like,
  poll,
  system,
}

class AppNotificationDetails {
  final String? postId;
  final NotificationSpace? space;

  AppNotificationDetails({
    this.postId,
    this.space,
  });

  factory AppNotificationDetails.fromJson(Map<String, dynamic> json) {
    return AppNotificationDetails(
      postId: json['postId']?.toString(),
      space: json['space'] != null
          ? NotificationSpace.fromJson(json['space'])
          : null,
    );
  }
}

class NotificationSpace {
  final int? externalCourseId;

  NotificationSpace({this.externalCourseId});

  factory NotificationSpace.fromJson(Map<String, dynamic> json) {
    return NotificationSpace(
      externalCourseId: json['externalCourseId'],
    );
  }
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType referenceType;
  final String? refrenceId; // Note: typo is intentional - matches backend
  final String? senderName;
  final String? senderImage;
  final String? redirectUrl;
  final bool isRead;
  final DateTime createdAt;
  final AppNotificationDetails? notificationDetails;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.referenceType,
    this.refrenceId,
    this.senderName,
    this.senderImage,
    this.redirectUrl,
    this.isRead = false,
    required this.createdAt,
    this.notificationDetails,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? referenceType,
    String? refrenceId,
    String? senderName,
    String? senderImage,
    String? redirectUrl,
    bool? isRead,
    DateTime? createdAt,
    AppNotificationDetails? notificationDetails,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      referenceType: referenceType ?? this.referenceType,
      refrenceId: refrenceId ?? this.refrenceId,
      senderName: senderName ?? this.senderName,
      senderImage: senderImage ?? this.senderImage,
      redirectUrl: redirectUrl ?? this.redirectUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      notificationDetails: notificationDetails ?? this.notificationDetails,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      referenceType: _parseNotificationType(json['referenceType']),
      refrenceId: json['refrenceId']?.toString(),
      senderName: json['senderName'],
      senderImage: json['senderImage'],
      redirectUrl: json['redirectUrl'],
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      notificationDetails: json['notificationDetails'] != null
          ? AppNotificationDetails.fromJson(json['notificationDetails'])
          : null,
    );
  }

  static NotificationType _parseNotificationType(dynamic type) {
    if (type is int) {
      switch (type) {
        case 0:
          return NotificationType.post;
        case 1:
          return NotificationType.poll;
        case 2:
          return NotificationType.comment;
        case 3:
          return NotificationType.system;
        case 4:
          return NotificationType.like;
        default:
          return NotificationType.system;
      }
    }
    if (type is String) {
      switch (type.toLowerCase()) {
        case 'post':
          return NotificationType.post;
        case 'comment':
          return NotificationType.comment;
        case 'like':
          return NotificationType.like;
        case 'poll':
          return NotificationType.poll;
        default:
          return NotificationType.system;
      }
    }
    return NotificationType.system;
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 30) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      // Format date in Arabic locale style
      final months = [
        'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
      ];
      return '${createdAt.day} ${months[createdAt.month - 1]} ${createdAt.year}';
    }
  }
}

class GroupedNotification {
  final NotificationType type;
  final String? postId;
  final List<AppNotification> notifications;
  final int count;
  final List<String> senderNames;
  final bool isRead;

  GroupedNotification({
    required this.type,
    this.postId,
    required this.notifications,
    required this.count,
    required this.senderNames,
    required this.isRead,
  });

  AppNotification get latestNotification => notifications.first;

  String get groupedSenderText {
    if (senderNames.isEmpty) return '';
    if (senderNames.length == 1) return senderNames.first;
    if (senderNames.length == 2) return '${senderNames[0]} و ${senderNames[1]}';
    return '${senderNames[0]} و ${senderNames[1]} و ${senderNames.length - 2} آخرين';
  }

  String get groupedBodyText {
    switch (type) {
      case NotificationType.like:
        return '$groupedSenderText أعجبوا بمنشورك';
      case NotificationType.comment:
        return '$groupedSenderText علقوا على منشورك';
      default:
        return latestNotification.body;
    }
  }
}

class NotificationsApiResponse {
  final List<AppNotification> items;
  final int totalCount;
  final int unreadCount;

  NotificationsApiResponse({
    required this.items,
    required this.totalCount,
    required this.unreadCount,
  });

  factory NotificationsApiResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return NotificationsApiResponse(
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => AppNotification.fromJson(item))
              .toList() ??
          [],
      totalCount: data['totalCount'] ?? 0,
      unreadCount: data['unreadCount'] ?? 0,
    );
  }
}
