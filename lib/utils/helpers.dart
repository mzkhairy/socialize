import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

String formatDateTimeRange(DateTime start, DateTime end) {
  final DateFormat dateFormatter = DateFormat('EEE, MMM d, yyyy');
  final DateFormat timeFormatter = DateFormat('h:mm a');
  return '${dateFormatter.format(start)} ${timeFormatter.format(start)} - ${timeFormatter.format(end)}';
}

String formatDateTimeSimple(DateTime dt) {
   final DateFormat dateFormatter = DateFormat('MMM d, h:mm a');
   return dateFormatter.format(dt);
}


// Helper to show a snackbar
void showAppSnackBar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.secondary,
    ),
  );
}

// For map marker generation (simple example)
BitmapDescriptor? customMarkerIcon;

Future<void> loadCustomMarker(BuildContext context) async {
  // You can load a custom image as a marker
  // For simplicity, using default marker or a color-tinted one
  // customMarkerIcon = await BitmapDescriptor.fromAssetImage(
  //     ImageConfiguration(devicePixelRatio: 2.5), 'assets/your_marker_icon.png');
  // Using default hue for now.
}

/// Calculates the distance between two LatLng points in kilometers.
double calculateDistanceKm(LatLng startLatLng, LatLng endLatLng) {
  double distanceInMeters = Geolocator.distanceBetween(
    startLatLng.latitude,
    startLatLng.longitude,
    endLatLng.latitude,
    endLatLng.longitude,
  );
  return distanceInMeters / 1000.0;
}