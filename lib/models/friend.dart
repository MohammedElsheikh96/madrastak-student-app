class Friend {
  final String? userId;
  final String? spaceId;
  final String? profileImageUrl;
  final String? name;
  final String? role;

  Friend({
    this.userId,
    this.spaceId,
    this.profileImageUrl,
    this.name,
    this.role,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return Friend(
      userId: user?['id']?.toString(),
      spaceId: user?['spaceId']?.toString(),
      profileImageUrl: user?['profileImageUrl'],
      name: user?['name'],
      role: json['role']?.toString(),
    );
  }
}

class FriendsPagedResponse {
  final List<Friend> friends;
  final int totalCount;

  FriendsPagedResponse({required this.friends, required this.totalCount});

  factory FriendsPagedResponse.fromJson(Map<String, dynamic> json) {
    List<Friend> friendsList = [];
    if (json['friends'] != null) {
      for (var friend in json['friends']) {
        friendsList.add(Friend.fromJson(friend));
      }
    }
    return FriendsPagedResponse(
      friends: friendsList,
      totalCount: json['totalCount'] ?? 0,
    );
  }
}
