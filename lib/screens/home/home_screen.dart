import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:socialize/models/activity_category.dart';
import 'package:socialize/models/activity_model.dart';
import 'package:socialize/providers/app_data_provider.dart';
import 'package:socialize/providers/theme_provider.dart';
import 'package:socialize/screens/activity/create_edit_activity_screen.dart';
import 'package:socialize/screens/home/widgets/activity_detail_view.dart';
import 'package:socialize/screens/home/widgets/activity_list_view.dart';
import 'package:socialize/screens/home/widgets/map_view.dart';
import 'package:socialize/screens/notifications/notifications_screen.dart';
import 'package:socialize/screens/profile/profile_screen.dart';
import 'package:socialize/services/location_service.dart';
import 'package:socialize/widgets/app_header.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<MapViewState> _mapViewKey = GlobalKey<MapViewState>();
  Set<ActivityCategory> _selectedFilterCategories = {};
  LatLng? _currentUserLocation; // <-- ADD STATE FOR USER LOCATION
  final LocationService _locationService = LocationService(); // <-- INSTANTIATE SERVICE

  @override
  void initState() {
  super.initState();
  _fetchCurrentUserLocation(); // <-- FETCH LOCATION ON INIT
  }
  Future<void> _fetchCurrentUserLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentUserLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      // Handle location fetch error
      print("HomeScreen: Error fetching current location: $e");
    }
  }
  // To control which view is in the bottom panel: list or details
  // bool _showActivityDetails = false; // Replaced by checking appDataProvider.selectedActivity

  void _onMarkerTapped(ActivityModel activity) {
    Provider.of<AppDataProvider>(context, listen: false).selectActivity(activity);
    // _mapViewKey.currentState?.moveToLocation(activity.location); // Center map on marker
  }

  void _onActivityListItemTapped(ActivityModel activity) {
    Provider.of<AppDataProvider>(context, listen: false).selectActivity(activity);
    _mapViewKey.currentState?.moveToLocation(activity.location);
  }

  void _onCloseActivityDetails() {
    Provider.of<AppDataProvider>(context, listen: false).clearSelectedActivity();
  }

  void _onCategoryFiltersChanged(Set<ActivityCategory> newSelectedCategories) {
      setState(() {
        _selectedFilterCategories = newSelectedCategories;
      });
  }

  void _handleMapLongPress(LatLng latLng) async {
     // Show a dialog to confirm creating an activity at this point
    final bool? create = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Create New Activity?'),
        content: Text('Do you want to create a new activity at this location?\nLat: ${latLng.latitude.toStringAsFixed(4)}, Lng: ${latLng.longitude.toStringAsFixed(4)}'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (create == true && mounted) {
      // Navigate to CreateEditActivityScreen, pre-filling the location
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CreateEditActivityScreen(
          // We can pass the latLng to CreateEditActivityScreen
          // and have it use this as the initial selectedLocation.
          // For now, CreateEditActivityScreen handles its own location picking,
          // but this is where you'd pass it.
          // Example: activityToEdit: ActivityModel(location: latLng, ... other defaults ...)
          // This requires modification in CreateEditActivityScreen or a different constructor.
          // For simplicity, we'll just open the create screen and user picks location again.
          // A better UX would pre-fill.
        ),
      ));
       // Or, directly pass the selected location to a modified CreateEditActivityScreen
       /*
       Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CreateEditActivityScreen(initialLocationFromMap: latLng),
        ),
      );
      */
      // This needs CreateEditActivityScreen to accept `initialLocationFromMap`
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final appDataProvider = Provider.of<AppDataProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Define heights based on screen proportions
    // kToolbarHeight is typically 56.0.
    // We want AppHeader to be roughly 1/10. Standard AppBar is fine.
    final double mapHeight = screenSize.height * 0.55; // Adjusted for header and potential bottom nav
    final double listDetailHeight = screenSize.height * 0.30;
    final bool hasUnreadNotifications = appDataProvider.notifications.isNotEmpty; // Getter for unread notifications


    return Scaffold(
      // AppHeader is PreferredSizeWidget, fits into AppBar slot.
      appBar: AppHeader(
        // No title needed here as logo is there. Or specific "Socialize" title.
        title: "Socialize", actions: [],
      ),
      body: Column(
        children: [
          SizedBox(
            height: mapHeight,
            child: Stack(
              children: [
                MapView(
                  key: _mapViewKey,
                  onMarkerTapped: _onMarkerTapped,
                  onMapLongPress: _handleMapLongPress,
                  highlightedLocation: appDataProvider.selectedActivity?.location,
                ),

                // New Activity Button (Bottom-most on the left)
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: FloatingActionButton.extended(
                    heroTag: "add_activity_fab_extended",
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const CreateEditActivityScreen(),
                      ));
                    },
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    label: const Text('New Activity', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                ),

                // Profile Button (Above "New Activity")
                Positioned(
                  left: 16,
                  // Approx height of FAB.extended is 48-56. Let's use 50 + 16 (padding) + 16 (bottom of New Activity)
                  bottom: 16 + 50 + 12, // e.g., 78. Adjust as needed.
                  child: FloatingActionButton.extended(
                    heroTag: "profile_fab_extended",
                    backgroundColor: themeProvider.isDarkMode ? Theme.of(context).colorScheme.surface : Colors.white,
                    onPressed: () {
                      Navigator.of(context).pushNamed(ProfileScreen.routeName);
                    },
                    icon: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary, size: 18),
                    label: Text('Profile', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 14)),
                  ),
                ),

                // Notification Button (NEW - Above "Profile")
                Positioned(
                  left: 16,
                  // Approx height of Profile FAB.extended (50) + its bottom position (78) + 12 spacing
                  bottom: 78 + 50 + 12, // e.g., 140. Adjust as needed.
                  child: Material( // Using Material for elevation and shape
                    color: themeProvider.isDarkMode ? Theme.of(context).colorScheme.surface : Colors.white,
                    elevation: 4.0,
                    shape: const CircleBorder(),
                    child: InkWell( // Using InkWell for tap effect on a custom shaped button
                      customBorder: const CircleBorder(),
                      onTap: () {
                        Navigator.of(context).pushNamed(NotificationsScreen.routeName);
                      },
                      child: Container(
                        width: 48, // Size of a mini FAB roughly
                        height: 48,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none_outlined, // Or Icons.notifications
                              color: Theme.of(context).colorScheme.primary,
                              size: 26,
                            ),
                            if (hasUnreadNotifications)
                              Positioned(
                                top: 8,  // Adjust for desired dot position
                                right: 8, // Adjust for desired dot position
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 8,
                                    minHeight: 8,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            height: listDetailHeight,
            child: appDataProvider.selectedActivity != null
                ? ActivityDetailView(
                    activity: appDataProvider.selectedActivity!,
                    onClose: _onCloseActivityDetails,
                  )
                : ActivityListView(
                    onActivityTap: _onActivityListItemTapped,
                    onCategoryFilterChanged: _onCategoryFiltersChanged, // Updated callback
                    selectedCategories: _selectedFilterCategories,
                    currentUserLocation: _currentUserLocation, 
                  ),
          ),
        ],
      ),
    );
  }
}