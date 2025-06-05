// lib/models/activity_category.dart (Example structure)
enum ActivityCategory {
  socialGathering,
  sports,
  foodAndDrink,
  artsAndCulture,
  outdoorAdventure,
  learning,
  community,
  entertainment,
  volunteering,
  other,
}

String categoryToString(ActivityCategory category) {
  switch (category) {
    case ActivityCategory.socialGathering:
      return 'Social Gathering';
    case ActivityCategory.sports:
      return 'Sports';
    case ActivityCategory.foodAndDrink:
      return 'Food & Drink';
    case ActivityCategory.artsAndCulture:
      return 'Arts & Culture';
    case ActivityCategory.outdoorAdventure:
      return 'Outdoor Adventure';
    case ActivityCategory.learning:
      return 'Learning';
    case ActivityCategory.community:
      return 'Community';
    case ActivityCategory.entertainment:
      return 'Entertainment';
    case ActivityCategory.volunteering:
      return 'Volunteering';
    case ActivityCategory.other:
      return 'Other';
    default:
      // Fallback for any new categories not explicitly handled, or just use the enum name
      return category.toString().split('.').last.replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}').trim();
  }
}

// Helper to get all categories as a list
List<ActivityCategory> getAllActivityCategories() {
  return ActivityCategory.values;
}