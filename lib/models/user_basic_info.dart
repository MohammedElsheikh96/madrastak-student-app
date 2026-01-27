class UserBasicInfo {
  final String? name;
  final String? email;
  final String? phone;
  final String? profilePicture;

  UserBasicInfo({
    this.name,
    this.email,
    this.phone,
    this.profilePicture,
  });

  factory UserBasicInfo.fromJson(Map<String, dynamic> json) {
    return UserBasicInfo(
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      profilePicture: json['profilePicture'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'profilePicture': profilePicture,
    };
  }
}
