import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socialize/providers/app_data_provider.dart';
import 'package:socialize/providers/theme_provider.dart';
import 'package:socialize/screens/auth/login_screen.dart';
import 'package:socialize/screens/home/home_screen.dart';
import 'package:socialize/screens/notifications/notifications_screen.dart';
import 'package:socialize/screens/profile/profile_screen.dart';
import 'package:socialize/utils/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socialize/utils/helpers.dart'; // For loadCustomMarker

// Ensure you have configured API keys for Maps_flutter
// Android: android/app/src/main/AndroidManifest.xml
// <meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_ANDROID_API_KEY_HERE"/>
// iOS: ios/Runner/AppDelegate.swift (or .m)
// import GoogleMaps
// GMSServices.provideAPIKey("YOUR_IOS_API_KEY_HERE")

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load custom map marker if you have one (optional)
  // await loadCustomMarker(); // You need to implement this in helpers.dart if you want custom image markers

  // Initialize providers that need async setup (like SharedPreferences in ThemeProvider)
  final themeProvider = ThemeProvider();
  await themeProvider.isDarkMode; // Ensure theme is loaded
  final appDataProvider = AppDataProvider();
  await appDataProvider.currentUser; // Ensure user is loaded
  await dotenv.load(fileName: ".env");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: appDataProvider),
      ],
      child: const SocializeApp(),
    ),
  );
}

class SocializeApp extends StatelessWidget {
  const SocializeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final appDataProvider = Provider.of<AppDataProvider>(context, listen: false);


    return MaterialApp(
      title: 'Socialize',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.currentThemeMode,
      debugShowCheckedModeBanner: false,
      // Initial route depends on whether a user is already logged in
      initialRoute: appDataProvider.currentUser != null ? HomeScreen.routeName : LoginScreen.routeName,
      routes: {
        LoginScreen.routeName: (context) => const LoginScreen(),
        HomeScreen.routeName: (context) => const HomeScreen(),
        ProfileScreen.routeName: (context) => const ProfileScreen(),
        NotificationsScreen.routeName: (context) => const NotificationsScreen(),
        // CreateEditActivityScreen is usually pushed, not a named route directly from main routes,
        // unless you want to deep link to it.
      },
      // If you push CreateEditActivityScreen often with specific arguments,
      // you might consider onGenerateRoute for more complex routing logic.
    );
  }
}