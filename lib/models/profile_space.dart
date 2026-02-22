class ProfileSpace {
  final String id;
  final String? name;
  final String? profileImageUrl;
  final String? coverImageUrl;
  final String? description;
  final bool? isFriend;
  final String userId;

  ProfileSpace({
    required this.id,
    this.name,
    this.profileImageUrl,
    this.coverImageUrl,
    this.description,
    this.isFriend,
    required this.userId,
  });

  factory ProfileSpace.fromJson(Map<String, dynamic> json) {
    return ProfileSpace(
      id: json['id']?.toString() ?? '',
      name: json['name'],
      profileImageUrl: json['profileImageUrl'],
      coverImageUrl: json['coverImageUrl'],
      description: json['description'],
      isFriend: json['isFriend'],
      userId: json['createdBy']?.toString() ?? '',
    );
  }
}
