class SubInterest {
  final int? id;
  final String? name;
  final String? arabicName;

  SubInterest({
    this.id,
    this.name,
    this.arabicName,
  });

  factory SubInterest.fromJson(Map<String, dynamic> json) {
    return SubInterest(
      id: json['id'] as int?,
      name: json['name'] as String?,
      arabicName: json['arabicName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'arabicName': arabicName,
    };
  }
}
