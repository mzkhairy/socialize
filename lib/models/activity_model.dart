import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socialize/models/activity_category.dart';


@immutable
class ActivityModel {
  final String id;
  final String name;
  final ActivityCategory category;
  final String locationDetails;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final LatLng location;
  final int maxUsers;
  final String creatorId; // User ID of the creator
  final String coordinatorId; // User ID of the current coordinator
  final List<String> joinedUserIds; // List of user IDs who joined

  const ActivityModel({
    required this.id,
    required this.name,
    required this.category,
    required this.locationDetails, 
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.maxUsers,
    required this.creatorId,
    required this.coordinatorId,
    this.joinedUserIds = const [],
  });

  bool get isFull => joinedUserIds.length >= maxUsers;
  bool get hasEnded => DateTime.now().isAfter(endTime);

  ActivityModel copyWith({
    String? id,
    String? name,
    ActivityCategory? category,
    String? nearbyLandmark,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    LatLng? location,
    int? maxUsers,
    String? creatorId,
    String? coordinatorId,
    List<String>? joinedUserIds,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      locationDetails: locationDetails ?? this.locationDetails,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      maxUsers: maxUsers ?? this.maxUsers,
      creatorId: creatorId ?? this.creatorId,
      coordinatorId: coordinatorId ?? this.coordinatorId,
      joinedUserIds: joinedUserIds ?? this.joinedUserIds,
    );
  }

   @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}