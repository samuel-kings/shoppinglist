import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:shoppinglist/models/user.dart';

class Family {
  /// unique identifier for each family
  String id;

  /// name of family
  String name;

  /// a list of user objects for each member of the family
  List<User> members;

  /// ID of the user who cretaed the family
  String creator;

  Family({
    required this.id,
    required this.name,
    required this.members,
    required this.creator,
  });

  Family copyWith({
    String? id,
    String? name,
    List<User>? members,
    String? creator,
  }) {
    return Family(
      id: id ?? this.id,
      name: name ?? this.name,
      members: members ?? this.members,
      creator: creator ?? this.creator,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'id': id});
    result.addAll({'name': name});
    result.addAll({'members': members.map((x) => x.toMap()).toList()});
    result.addAll({'creator': creator});

    return result;
  }

  factory Family.fromMap(Map<dynamic, dynamic> map) {
    String id = map['id'] ?? '';
    String name = map['name'] ?? '';
    String creator = map['creator'] ?? '';
    List<User> members = List<User>.from(map['members']?.map((x) => User.fromMap(x)) ?? <User>[]);

    return Family(
      id: id,
      name: name,
      members: members,
      creator: creator,
    );
  }

  String toJson() => json.encode(toMap());

  factory Family.fromJson(String source) => Family.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Family(id: $id, name: $name, members: $members, creator: $creator)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Family &&
        other.id == id &&
        other.name == name &&
        listEquals(other.members, members) &&
        other.creator == creator;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ members.hashCode ^ creator.hashCode;
  }
}
