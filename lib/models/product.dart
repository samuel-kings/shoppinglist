import 'dart:convert';
import 'package:flutter/foundation.dart';

/// can also be refereed to as item, shopping item
class Product {
  /// unique identifier for the product
  String? id;

  /// name of the product
  String? name;

  /// ID of family memeber who added the item to the shopping list
  String createdBy;

  /// can be marked true if the product has been checked as purchased
  bool? isDone;

  /// name of the category it falls under
  String? categoryName;

  /// list of members' IDs this item was assigned to
  List<String>? assignedTo;

  /// a reminder DateTime in ISO8601 string format
  String? remindAt;

  /// url of additional photo to give extra information about the product
  String? addedPhotoUrl;

  /// note to give extra information about the product
  String? note;

  /// last DateTime item was edited in ISO8601 string format
  String lastEdited;

  /// priority of the product: 0 - low, 1 - medium, 2 - high
  int? priority;

  /// estimated price of the product
  String? estimatedPrice;

  /// actual price of the product
  String? actualPrice;
  Product({
    this.id,
    this.name,
    required this.createdBy,
    this.isDone,
    this.categoryName,
    this.assignedTo,
    this.remindAt,
    this.addedPhotoUrl,
    this.note,
    required this.lastEdited,
    this.priority,
    this.estimatedPrice,
    this.actualPrice,
  });

  Product copyWith({
    String? id,
    String? name,
    String? createdBy,
    bool? isDone,
    String? categoryName,
    List<String>? assignedTo,
    String? remindAt,
    String? addedPhotoUrl,
    String? note,
    String? lastEdited,
    int? priority,
    String? estimatedPrice,
    String? actualPrice,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      createdBy: createdBy ?? this.createdBy,
      isDone: isDone ?? this.isDone,
      categoryName: categoryName ?? this.categoryName,
      assignedTo: assignedTo ?? this.assignedTo,
      remindAt: remindAt ?? this.remindAt,
      addedPhotoUrl: addedPhotoUrl ?? this.addedPhotoUrl,
      note: note ?? this.note,
      lastEdited: lastEdited ?? this.lastEdited,
      priority: priority ?? this.priority,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      actualPrice: actualPrice ?? this.actualPrice,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};
  
    if(id != null){
      result.addAll({'id': id});
    }
    if(name != null){
      result.addAll({'name': name});
    }
    result.addAll({'createdBy': createdBy});
    if(isDone != null){
      result.addAll({'isDone': isDone});
    }
    if(categoryName != null){
      result.addAll({'categoryName': categoryName});
    }
    if(assignedTo != null){
      result.addAll({'assignedTo': assignedTo});
    }
    if(remindAt != null){
      result.addAll({'remindAt': remindAt});
    }
    if(addedPhotoUrl != null){
      result.addAll({'addedPhotoUrl': addedPhotoUrl});
    }
    if(note != null){
      result.addAll({'note': note});
    }
    result.addAll({'lastEdited': lastEdited});
    if(priority != null){
      result.addAll({'priority': priority});
    }
    if(estimatedPrice != null){
      result.addAll({'estimatedPrice': estimatedPrice});
    }
    if(actualPrice != null){
      result.addAll({'actualPrice': actualPrice});
    }
  
    return result;
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      createdBy: map['createdBy'] ?? '',
      isDone: map['isDone'],
      categoryName: map['categoryName'],
      assignedTo: List<String>.from(map['assignedTo'] ?? []),
      remindAt: map['remindAt'],
      addedPhotoUrl: map['addedPhotoUrl'],
      note: map['note'],
      lastEdited: map['lastEdited'] ?? '',
      priority: map['priority'] == null ? 1 : map['priority'].toInt(),
      estimatedPrice: map['estimatedPrice'],
      actualPrice: map['actualPrice']
    );
  }

  String toJson() => json.encode(toMap());

  factory Product.fromJson(String source) => Product.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Product(id: $id, name: $name, createdBy: $createdBy, isDone: $isDone, categoryName: $categoryName, assignedTo: $assignedTo, remindAt: $remindAt, addedPhotoUrl: $addedPhotoUrl, note: $note, lastEdited: $lastEdited, priority: $priority, estimatedPrice: $estimatedPrice, actualPrice: $actualPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Product &&
      other.id == id &&
      other.name == name &&
      other.createdBy == createdBy &&
      other.isDone == isDone &&
      other.categoryName == categoryName &&
      listEquals(other.assignedTo, assignedTo) &&
      other.remindAt == remindAt &&
      other.addedPhotoUrl == addedPhotoUrl &&
      other.note == note &&
      other.lastEdited == lastEdited &&
      other.priority == priority &&
      other.estimatedPrice == estimatedPrice &&
      other.actualPrice == actualPrice;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      name.hashCode ^
      createdBy.hashCode ^
      isDone.hashCode ^
      categoryName.hashCode ^
      assignedTo.hashCode ^
      remindAt.hashCode ^
      addedPhotoUrl.hashCode ^
      note.hashCode ^
      lastEdited.hashCode ^
      priority.hashCode ^
      estimatedPrice.hashCode ^
      actualPrice.hashCode;
  }
}
