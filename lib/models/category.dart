import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Category model fro shopping list
class Category {
  /// unique category id
  String id;
  /// category name
  String name;
  /// names of products in the category
  List<String> products;
  /// false if category is a default  category, true if it was created by user
  bool isCustomCategory;

  Category({
    required this.id,
    required this.name,
    required this.products,
    required this.isCustomCategory,
  });

  Category copyWith({
    String? id,
    String? name,
    List<String>? products,
    bool? isCustomCategory,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      products: products ?? this.products,
      isCustomCategory: isCustomCategory ?? this.isCustomCategory,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'id': id});
    result.addAll({'name': name});
    result.addAll({'products': products});
    result.addAll({'isCustomCategory': isCustomCategory});

    return result;
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      products: map['products'] == null ? [] : List<String>.from(map['products']),
      isCustomCategory: map['isCustomCategory'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory Category.fromJson(String source) => Category.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Category(id: $id, name: $name, products: $products, isCustomCategory: $isCustomCategory)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Category &&
        other.id == id &&
        other.name == name &&
        listEquals(other.products, products) &&
        other.isCustomCategory == isCustomCategory;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ products.hashCode ^ isCustomCategory.hashCode;
  }
}
