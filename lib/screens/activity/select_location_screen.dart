// lib/screens/activity/select_location_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socialize/services/location_service.dart';
import 'package:google_maps_webservice/places.dart' as gm_places;
import 'package:socialize/config/app_config.dart'; // Ensure you have your Google Places API key set in app_config.dart

class SelectLocationScreen extends StatefulWidget {
  final LatLng? initialLocation;
  const SelectLocationScreen({super.key, this.initialLocation});

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  Marker? _currentMarker;
  final LocationService _locationService = LocationService();

  final TextEditingController _searchController = TextEditingController();
  // Use the aliased import for GoogleMapsPlaces
  gm_places.GoogleMapsPlaces _places = gm_places.GoogleMapsPlaces(apiKey: AppConfig.googleApiKey);
  List<gm_places.Prediction> _placePredictions = [];
  Timer? _debounce;
  bool _isLoadingPredictions = false;

  @override
  void initState() {
    super.initState();
    final apiKey = AppConfig.googleApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      // Handle missing API key - show an error, disable search, etc.
      print("ERROR: Google Places API Key is missing. Location search will not work.");
      // For simplicity, we'll proceed, but _places calls will likely fail.
      // In a real app, you might want to prevent this screen from functioning fully.
      _places = gm_places.GoogleMapsPlaces(apiKey: "FALLBACK_OR_EMPTY_KEY_DOES_NOT_WORK"); // This will cause errors
    } else {
      _places = gm_places.GoogleMapsPlaces(apiKey: apiKey);
    }
    if (widget.initialLocation != null) {
      _updateMapAndMarker(widget.initialLocation!, placeName: "Initial Location");
    } else {
      _fetchInitialLocation();
    }

    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 600), () {
        if (_searchController.text.length > 2) { // Start search after 2 characters
          _fetchPlaceAutocomplete(_searchController.text);
        } else {
          setState(() {
            _placePredictions = [];
          });
        }
      });
    });
  }

  Future<void> _fetchInitialLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      _updateMapAndMarker(LatLng(position.latitude, position.longitude), placeName: "My Current Location");
    } catch (e) {
      // Default to a known location if current cannot be fetched
      _updateMapAndMarker(const LatLng(-6.2088, 106.8456), placeName: "Default Location"); // Jakarta
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get current location: $e')),
        );
      }
    }
  }

  void _updateMapAndMarker(LatLng location, {String? placeName}) {
    setState(() {
      _selectedLocation = location;
      _currentMarker = Marker(
        markerId: const MarkerId('selectedLocation'),
        position: location,
        infoWindow: InfoWindow(title: placeName ?? 'Selected Location'),
      );
    });
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: location, zoom: 15.0),
      ),
    );
  }

  void _onMapTapped(LatLng location) async {
    // Optionally perform reverse geocoding to get a name
    String tappedPlaceName = 'Pinned Location';
    try {
      // Using your existing geocoding service if available, or add here
      String address = await _locationService.getAddressFromLatLng(location);
      tappedPlaceName = address.split(',').take(2).join(','); // Get first two parts of address
    } catch (e) {
      print("Reverse geocoding failed: $e");
    }
    _updateMapAndMarker(location, placeName: tappedPlaceName);
    setState(() {
      _placePredictions = []; // Clear predictions
      _searchController.clear(); // Clear search text
    });
  }

  Future<void> _fetchPlaceAutocomplete(String input) async {
    if (input.isEmpty) {
      setState(() => _placePredictions = []);
      return;
    }
    setState(() => _isLoadingPredictions = true);
    try {
      gm_places.PlacesAutocompleteResponse response = await _places.autocomplete(
        input,
        // Optional: Add location biasing based on current map view or user location
        // location: _mapController != null ? await _mapController!.getVisibleRegion().then((bounds) => gm_places.Location(lat: (bounds.northeast.latitude + bounds.southwest.latitude)/2, lng: (bounds.northeast.longitude + bounds.southwest.longitude)/2)) : null,
        // radius: 50000, // in meters, use with location
        // language: 'en', // or 'id' for Indonesian
        // components: [gm_places.Component(gm_places.Component.country, "id")] // Restrict to Indonesia
      );

      if (response.isOkay) {
        setState(() {
          _placePredictions = response.predictions;
        });
      } else {
        print("Places Autocomplete Error: ${response.errorMessage}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching places: ${response.errorMessage}')),
          );
        }
        setState(() => _placePredictions = []);
      }
    } catch (e) {
      print("Exception during place autocomplete: $e");
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not connect to places service.')),
          );
        }
      setState(() => _placePredictions = []);
    } finally {
      setState(() => _isLoadingPredictions = false);
    }
  }

  Future<void> _onPredictionSelected(gm_places.Prediction prediction) async {
    if (prediction.placeId == null) return;

    FocusScope.of(context).unfocus(); // Hide keyboard
    setState(() => _isLoadingPredictions = true); // Show loading for details fetch

    try {
      gm_places.PlacesDetailsResponse detail = await _places.getDetailsByPlaceId(prediction.placeId!);
      if (detail.isOkay && detail.result.geometry != null) {
        final location = detail.result.geometry!.location;
        _updateMapAndMarker(LatLng(location.lat, location.lng), placeName: prediction.description);
        _searchController.text = prediction.description ?? ''; // Update search text to selection
      } else {
        print("Place Details Error: ${detail.errorMessage}");
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error getting place details: ${detail.errorMessage}')),
          );
        }
      }
    } catch (e) {
      print("Exception during place details: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get place details.')),
        );
      }
    } finally {
      setState(() {
        _placePredictions = []; // Clear predictions after selection
        _isLoadingPredictions = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    // _mapController?.dispose(); // GoogleMap widget handles its own controller disposal
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Activity Location'),
        actions: [
          if (_selectedLocation != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.of(context).pop(_selectedLocation);
              },
            ),
        ],
      ),
      body: Column( // Changed to Column to hold map and search results
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Location',
                hintText: 'Enter address or place name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() { _placePredictions = []; });
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          if (_isLoadingPredictions) const LinearProgressIndicator(),
          if (_placePredictions.isNotEmpty)
            Expanded( // Make the list scrollable and take available space
              flex: 0, // Do not let it expand if map is also expanded, make it take natural height or fixed height
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3), // Limit height
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _placePredictions.length,
                  itemBuilder: (context, index) {
                    final prediction = _placePredictions[index];
                    return ListTile(
                      title: Text(prediction.description ?? 'N/A'),
                      onTap: () => _onPredictionSelected(prediction),
                    );
                  },
                ),
              ),
            ),
          Expanded( // Map takes remaining space
            flex: 1,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.initialLocation ?? _selectedLocation ?? const LatLng(-6.2088, 106.8456), // Default to Jakarta
                zoom: 12.0, // Initial zoom
              ),
              onMapCreated: (GoogleMapController controller) {
                 if (!_mapControllerCompleter.isCompleted) _mapControllerCompleter.complete(controller);
                _mapController = controller;
                // If initial location was fetched after map created, move camera
                if(_selectedLocation != null && widget.initialLocation == null) {
                   _updateMapAndMarker(_selectedLocation!, placeName: "Initial Location");
                }
              },
              onTap: _onMapTapped,
              markers: _currentMarker != null ? {_currentMarker!} : {},
              myLocationButtonEnabled: true,
              myLocationEnabled: true, // Shows blue dot for user's current location
              // compassEnabled: true, // Optional
              // zoomControlsEnabled: true, // Optional
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedLocation != null ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pop(_selectedLocation);
        },
        label: const Text('Confirm Location'),
        icon: const Icon(Icons.check),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}