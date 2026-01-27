import 'sub_interest.dart';

class AccountPreference {
  final List<String>? interests;
  final List<SubInterest>? subInterests;
  final String? preferredLanguage;

  AccountPreference({
    this.interests,
    this.subInterests,
    this.preferredLanguage,
  });

  factory AccountPreference.fromJson(Map<String, dynamic> json) {
    return AccountPreference(
      interests: (json['interests'] as List<dynamic>?)?.cast<String>(),
      subInterests: (json['subInterests'] as List<dynamic>?)
          ?.map((e) => SubInterest.fromJson(e as Map<String, dynamic>))
          .toList(),
      preferredLanguage: json['preferredLanguage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'interests': interests,
      'subInterests': subInterests?.map((e) => e.toJson()).toList(),
      'preferredLanguage': preferredLanguage,
    };
  }
}
