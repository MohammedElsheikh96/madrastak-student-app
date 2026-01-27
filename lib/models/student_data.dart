import 'user_basic_info.dart';
import 'account_preference.dart';

class StudentData {
  final String token;
  final String id;
  final UserBasicInfo userBasicInfo;
  final AccountPreference? accountPreference;
  final String? onBoardingStatus;
  final String? language;
  final String? gender;
  final double? weight;
  final double? height;
  final String? countryName;

  StudentData({
    required this.token,
    required this.id,
    required this.userBasicInfo,
    this.accountPreference,
    this.onBoardingStatus,
    this.language,
    this.gender,
    this.weight,
    this.height,
    this.countryName,
  });

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'id': id,
      'userBasicInfo': userBasicInfo.toJson(),
      'accountPreference': accountPreference?.toJson(),
      'onBoardingStatus': onBoardingStatus,
      'language': language,
      'gender': gender,
      'weight': weight,
      'height': height,
      'countryName': countryName,
    };
  }

  factory StudentData.fromJson(Map<String, dynamic> json) {
    return StudentData(
      token: json['token'] as String,
      id: json['id'] as String,
      userBasicInfo: UserBasicInfo.fromJson(json['userBasicInfo']),
      accountPreference: json['accountPreference'] != null
          ? AccountPreference.fromJson(json['accountPreference'])
          : null,
      onBoardingStatus: json['onBoardingStatus'] as String?,
      language: json['language'] as String?,
      gender: json['gender'] as String?,
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      countryName: json['countryName'] as String?,
    );
  }
}
