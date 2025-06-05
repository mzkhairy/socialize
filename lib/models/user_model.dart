import 'package:flutter/foundation.dart';

@immutable
class UserModel {
  final String id;
  final String name;
  // Store IDs of activities the user has joined or is coordinating
  final List<String> joinedActivityIds;
  final List<String> coordinatedActivityIds;

  const UserModel({
    required this.id,
    required this.name,
    this.joinedActivityIds = const [],
    this.coordinatedActivityIds = const [],
  });

  UserModel copyWith({
    String? id,
    String? name,
    List<String>? joinedActivityIds,
    List<String>? coordinatedActivityIds,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      joinedActivityIds: joinedActivityIds ?? this.joinedActivityIds,
      coordinatedActivityIds: coordinatedActivityIds ?? this.coordinatedActivityIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}