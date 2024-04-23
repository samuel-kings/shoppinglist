import 'dart:convert';

class User {
  /// unique identifier for the product. works as ID
  String address;

  /// user first name (plus optional last or middle name)
  String name;

  /// ID of family
  String familyId;

  /// date and time user account was created in string ISO8601 format
  String createdAt;

  User({
    required this.address,
    required this.name,
    required this.familyId,
    required this.createdAt,
  });

  User copyWith({
    String? address,
    String? name,
    String? familyId,
    String? createdAt,
  }) {
    return User(
      address: address ?? this.address,
      name: name ?? this.name,
      familyId: familyId ?? this.familyId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'address': address});
    result.addAll({'name': name});
    result.addAll({'familyId': familyId});
    result.addAll({'createdAt': createdAt});

    return result;
  }

  factory User.fromMap(Map<dynamic, dynamic> map) {
    return User(
      address: map['address'] ?? '',
      name: map['name'] ?? '',
      familyId: map['familyId'] ?? '',
      createdAt: map['createdAt'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) => User.fromMap(json.decode(source));

  @override
  String toString() {
    return 'User(address: $address, name: $name, familyId: $familyId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User &&
        other.address == address &&
        other.name == name &&
        other.familyId == familyId &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return address.hashCode ^ name.hashCode ^ familyId.hashCode ^ createdAt.hashCode;
  }
}
