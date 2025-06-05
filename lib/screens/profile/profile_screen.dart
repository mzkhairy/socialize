import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:socialize/models/activity_category.dart';
import 'package:socialize/models/activity_model.dart';
import 'package:socialize/providers/app_data_provider.dart';
import 'package:socialize/screens/auth/login_screen.dart';
import 'package:socialize/services/location_service.dart';
import 'package:socialize/utils/helpers.dart';

class ProfileScreen extends StatelessWidget {
  static const String routeName = '/profile';

  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appDataProvider = Provider.of<AppDataProvider>(context);
    final currentUser = appDataProvider.currentUser;
    final LocationService locationService = LocationService();

    if (currentUser == null) {
      // This should ideally not happen if routing is correct, but as a fallback:
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<ActivityModel> userActivities = appDataProvider.getActivitiesForCurrentUser();
    userActivities.sort((a,b) => a.startTime.compareTo(b.startTime));


    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              appDataProvider.logout();
              Navigator.of(context).pushNamedAndRemoveUntil(
                  LoginScreen.routeName, (Route<dynamic> route) => false);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      currentUser.name.isNotEmpty ? currentUser.name[0].toUpperCase() : 'U',
                      style: TextStyle(fontSize: 40, color: Theme.of(context).colorScheme.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentUser.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Current Coordinate:',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                  ),
                  FutureBuilder<Position>(
                    future: locationService.getCurrentPosition(), // Call your service method
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('Fetching location...', style: TextStyle(fontSize: 14));
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}', style: const TextStyle(fontSize: 14, color: Colors.red));
                      } else if (snapshot.hasData) {
                        final position = snapshot.data!;
                        return Text(
                          'Lat: ${position.latitude.toStringAsFixed(5)}, Lng: ${position.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(fontSize: 14),
                        );
                      } else {
                        return const Text('Location not available.', style: TextStyle(fontSize: 14));
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'My Current Activities (${userActivities.length})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            if (userActivities.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Text('You have no upcoming activities.\nExplore the map or create one!'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: userActivities.length,
                itemBuilder: (context, index) {
                  final activity = userActivities[index];
                  final isCoordinator = activity.coordinatorId == currentUser.id;
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Icon(
                        isCoordinator ? Icons.star_border : Icons.event_available,
                        color: isCoordinator ? Theme.of(context).colorScheme.primary : Colors.green,
                      ),
                      title: Text(activity.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        "${categoryToString(activity.category)}\n${formatDateTimeSimple(activity.startTime)}",
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // Navigate to home page, select activity, and show details
                        appDataProvider.selectActivity(activity);
                        Navigator.of(context).popUntil((route) => route.isFirst); // Go back to home screen (if coming from there)
                        // If not already on home screen, navigate to it.
                        // This simple popUntil assumes HomeScreen is the root of the main stack after login.
                        // A more robust solution might use named routes with arguments or a global key for HomeScreen's state.
                        // For this example, if profile is pushed over home, this works.
                        // If coming from a different tab in a TabBar setup, a TabController would be needed.
                        // We ensure HomeScreen's state is updated via provider so it shows the selected activity.
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}