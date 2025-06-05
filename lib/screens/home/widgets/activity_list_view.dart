import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socialize/models/activity_model.dart';
import 'package:socialize/providers/app_data_provider.dart';
import 'package:socialize/models/activity_category.dart';
import 'package:socialize/utils/helpers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ActivityWithDistance {
  final ActivityModel activity;
  final double? distanceKm; // Nullable if location isn't available

  ActivityWithDistance({required this.activity, this.distanceKm});
}

class ActivityListView extends StatelessWidget { // Can be StatelessWidget now
  final Function(ActivityModel) onActivityTap;
  final Function(Set<ActivityCategory>) onCategoryFilterChanged; // Updated type
  final Set<ActivityCategory> selectedCategories;
  final LatLng? currentUserLocation; // Updated type

  const ActivityListView({
    super.key,
    required this.onActivityTap,
    required this.onCategoryFilterChanged,
    required this.selectedCategories,
    required this.currentUserLocation,
  });

  String _getFilterButtonText(BuildContext context) {
    final allAvailableCategories = getAllActivityCategories(); // Get all defined categories

    if (selectedCategories.isEmpty || selectedCategories.length == allAvailableCategories.length) {
      return 'All Categories';
    } else if (selectedCategories.length == 1) {
      return categoryToString(selectedCategories.first);
    } else if (selectedCategories.length <= 3) {
      return selectedCategories.map((c) => categoryToString(c).split(' ')[0]).join(', '); // Abbreviated
    } else {
      return 'Multiple (${selectedCategories.length})';
    }
  }

  void _showCategoryFilterDialog(BuildContext context) {
    // Use a StatefulWidget for the dialog content to manage temporary checkbox states
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CategoryFilterDialog(
          allCategories: getAllActivityCategories(),
          initiallySelectedCategories: selectedCategories,
          onApplyFilters: (newlySelectedCategories) {
            onCategoryFilterChanged(newlySelectedCategories);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appDataProvider = Provider.of<AppDataProvider>(context);
    List<ActivityModel> activities = appDataProvider.activities;
    List<ActivityModel> filteredActivitiesBasedOnCategory = [];

    final allAvailableCategoriesCount = getAllActivityCategories().length;
    bool noCategoriesSelected = selectedCategories.isEmpty;
    bool allCategoriesEffectivelySelected = selectedCategories.length == allAvailableCategoriesCount;

    if (noCategoriesSelected || allCategoriesEffectivelySelected) {
      filteredActivitiesBasedOnCategory = List.from(activities); // Show all
    } else {
      filteredActivitiesBasedOnCategory = activities.where((activity) {
        return selectedCategories.contains(activity.category);
      }).toList();
    }

    //Create list of ActivityWithDistance and sort
    List<ActivityWithDistance> activitiesWithDistances = filteredActivitiesBasedOnCategory.map((activity) {
      double? distance;
      if (currentUserLocation != null) {
        distance = calculateDistanceKm(currentUserLocation!, activity.location);
      }
      return ActivityWithDistance(activity: activity, distanceKm: distance);
    }).toList();

    // Sort by distance if available, otherwise by start time as a fallback
    activitiesWithDistances.sort((a, b) {
      if (a.distanceKm != null && b.distanceKm != null) {
        return a.distanceKm!.compareTo(b.distanceKm!); // Closest first
      } else if (a.distanceKm != null) {
        return -1; // Activities with distance come first
      } else if (b.distanceKm != null) {
        return 1;  // Activities with distance come first
      }
      // Fallback sort by start time if distances are not available for comparison
      return a.activity.startTime.compareTo(b.activity.startTime);
    });

        // Theme-aware text styles
    final theme = Theme.of(context);
    final categoryTextStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withOpacity(0.7),
      fontSize: 11, // Make it small
    );
    final distanceTextStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withOpacity(0.9),
      fontSize: 12, // Slightly larger than category or same
      fontWeight: FontWeight.w500,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Activities Near You',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              InkWell( // Changed PopupMenuButton to InkWell to trigger dialog
                onTap: () {
                  _showCategoryFilterDialog(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getFilterButtonText(context),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.filter_list, size: 18, color: Theme.of(context).colorScheme.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (activitiesWithDistances.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                selectedCategories.isEmpty || selectedCategories.length == allAvailableCategoriesCount
                    ? 'No activities found nearby.\nTry creating one!'
                    : 'No activities found for the selected ${selectedCategories.length == 1 ? "category" : "categories"}.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              itemCount: activitiesWithDistances.length, // Use the sorted list
              itemBuilder: (context, index) {
                final item = activitiesWithDistances[index]; // Get ActivityWithDistance object
                final activity = item.activity;
                final distance = item.distanceKm;

                return ListTile(
                  title: Text(activity.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Vertically center the column content
                    crossAxisAlignment: CrossAxisAlignment.end,   // Align text to the right
                    children: [
                      Text(
                        categoryToString(activity.category),
                        style: categoryTextStyle,
                        textAlign: TextAlign.end,
                      ),
                      const SizedBox(height: 2), // Spacing between category and distance
                      if (distance != null)
                        Text(
                          '${distance.toStringAsFixed(1)} km away', // e.g., "2.5 km away"
                          style: distanceTextStyle,
                          textAlign: TextAlign.end,
                        )
                      else if (currentUserLocation != null) // Location is available but distance couldn't be calculated for this item (should not happen if activity.location is valid)
                        Text(
                          '- km away', // Fallback if distance is null but user location exists
                          style: distanceTextStyle,
                          textAlign: TextAlign.end,
                        ),
                    ],
                  ),
                  onTap: () => onActivityTap(activity),
                );
              },
              separatorBuilder: (context, index) => const Divider(indent: 16, endIndent: 16),
            ),
          ),
      ],
    );
  }
}

// Helper StatefulWidget for the Category Filter Dialog
class CategoryFilterDialog extends StatefulWidget {
  final List<ActivityCategory> allCategories;
  final Set<ActivityCategory> initiallySelectedCategories;
  final Function(Set<ActivityCategory>) onApplyFilters;

  const CategoryFilterDialog({
    super.key,
    required this.allCategories,
    required this.initiallySelectedCategories,
    required this.onApplyFilters,
  });

  @override
  State<CategoryFilterDialog> createState() => _CategoryFilterDialogState();
}

class _CategoryFilterDialogState extends State<CategoryFilterDialog> {
  late Set<ActivityCategory> _tempSelectedCategories;

  @override
  void initState() {
    super.initState();
    // Initialize temporary set with a copy of the initially selected categories
    _tempSelectedCategories = Set<ActivityCategory>.from(widget.initiallySelectedCategories);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter by Category'),
      content: SizedBox( // Constrain the height of the content
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.allCategories.length,
          itemBuilder: (context, index) {
            final category = widget.allCategories[index];
            return CheckboxListTile(
              title: Text(categoryToString(category)),
              value: _tempSelectedCategories.contains(category),
              onChanged: (bool? newValue) {
                setState(() {
                  if (newValue == true) {
                    _tempSelectedCategories.add(category);
                  } else {
                    _tempSelectedCategories.remove(category);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Reset'),
          onPressed: () {
            setState(() {
              _tempSelectedCategories.clear(); // Clears all selections
            });
            // Optionally apply immediately or wait for "Apply"
            // widget.onApplyFilters(_tempSelectedCategories);
            // Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: const Text('Apply'),
          onPressed: () {
            widget.onApplyFilters(_tempSelectedCategories);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}