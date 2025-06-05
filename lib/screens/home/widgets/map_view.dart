import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:socialize/models/activity_category.dart';
import 'package:socialize/models/activity_model.dart';
import 'package:socialize/providers/app_data_provider.dart';
import 'package:socialize/services/location_service.dart';

class MapView extends StatefulWidget {
  final Function(ActivityModel) onMarkerTapped;
  final Function(LatLng) onMapLongPress; // For creating activity at location
  final LatLng? highlightedLocation; // To move map to a specific activity

  const MapView({
    super.key,
    required this.onMarkerTapped,
    required this.onMapLongPress,
    this.highlightedLocation,
  });

  @override
  State<MapView> createState() => MapViewState();
}

class MapViewState extends State<MapView> {
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();
  LatLng? _currentPosition;
  StreamSubscription<ServiceStatus>? _serviceStatusStreamSubscription; // Not used actively yet

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(-6.2088, 106.8456), // Default to Jakarta, Indonesia
    zoom: 12.0,
  );

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

   @override
  void didUpdateWidget(covariant MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlightedLocation != null &&
        widget.highlightedLocation != oldWidget.highlightedLocation) {
      _animateToLocation(widget.highlightedLocation!);
    }
  }


  Future<void> _determinePosition() async {
    try {
      final position = await _locationService.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      _animateToLocation(_currentPosition!, zoom: 15.0);
    } catch (e) {
      print("Error getting current location: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: ${e.toString()}')),
        );
      }
      // Keep default initial position or handle error appropriately
    }
  }

  Future<void> _animateToLocation(LatLng target, {double zoom = 14.0}) async {
    if (_mapController == null) {
      // Wait for controller to be ready
      _mapController = await _mapControllerCompleter.future;
    }
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom),
      ),
    );
  }

  // Public method to be called from HomeScreen to move map
  void moveToLocation(LatLng location) {
    _animateToLocation(location, zoom: 16.0);
  }


  Set<Marker> _createMarkers(List<ActivityModel> activities, AppDataProvider appData) {
    final Set<Marker> markers = {};

    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentPosition!,
          infoWindow: const InfoWindow(title: 'My Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }

    for (var activity in activities) {
      markers.add(
        Marker(
          markerId: MarkerId(activity.id),
          position: activity.location,
          infoWindow: InfoWindow(
            title: activity.name,
            snippet: categoryToString(activity.category),
          ),
          onTap: () {
            widget.onMarkerTapped(activity);
          },
          // TODO: Add custom icons based on category or coordinator status
           icon: (appData.selectedActivity?.id == activity.id)
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen) // Highlight selected
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
    return markers;
  }

  @override
  void dispose() {
    _serviceStatusStreamSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appDataProvider = Provider.of<AppDataProvider>(context);
    final activities = appDataProvider.activities;

    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: _currentPosition != null
          ? CameraPosition(target: _currentPosition!, zoom: 15.0)
          : _initialCameraPosition,
      onMapCreated: (GoogleMapController controller) {
        if (!_mapControllerCompleter.isCompleted) {
          _mapControllerCompleter.complete(controller);
          _mapController = controller; // Store it for later use
        }
      },
      myLocationEnabled: true, // Shows the blue dot for current location
      myLocationButtonEnabled: true, // Button to center on current location
      markers: _createMarkers(activities, appDataProvider),
      onLongPress: widget.onMapLongPress,
      onTap: (_) {
        // Clear selected activity when tapping on map (not on a marker)
        // This logic could also be in HomeScreen
         if (appDataProvider.selectedActivity != null) {
           // appDataProvider.clearSelectedActivity();
         }
      },
      padding: EdgeInsets.only(
        // Adjust padding if parts of the map are obscured by other UI elements
        // bottom: MediaQuery.of(context).size.height * 0.3, // Example if bottom sheet is persistent
      ),
    );
  }
}