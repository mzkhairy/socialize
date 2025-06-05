import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.blue, // Primary color like Twitter's blue
    scaffoldBackgroundColor: Colors.white, // Main background
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0, // Flat app bar
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
          color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    colorScheme: const ColorScheme.light(
      primary: Colors.blue,
      secondary: Colors.blueAccent,
      onPrimary: Colors.white, // Text on primary color
      onSecondary: Colors.white,
      background: Colors.white,
      surface: Colors.white, // Cards, dialogs
      onBackground: Colors.black,
      onSurface: Colors.black, // Text on surface
      error: Colors.redAccent,
      onError: Colors.white,
    ),
    textTheme: const TextTheme(
      // Define X-like fonts here if you have specific ones
      // For simplicity, using Material defaults which are clean (Roboto)
      displayLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: Colors.black87, fontSize: 16),
      bodyMedium: TextStyle(color: Colors.black54, fontSize: 14),
      labelLarge: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold), // For buttons
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.black54),
    ),
    cardTheme: CardTheme(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
    ),
    dividerColor: Colors.grey[300],
    iconTheme: const IconThemeData(color: Colors.black54),
    toggleButtonsTheme: ToggleButtonsThemeData(
      selectedColor: Colors.blue,
      borderColor: Colors.grey,
      selectedBorderColor: Colors.blue,
      borderRadius: BorderRadius.circular(8),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.lightBlueAccent, // Lighter blue for dark mode
    scaffoldBackgroundColor: const Color(0xFF15202B), // Twitter dark background
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF15202B),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
          color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Colors.lightBlueAccent,
      secondary: Colors.blue,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      background: Color(0xFF15202B),
      surface: Color(0xFF192734), // Slightly lighter for cards, dialogs
      onBackground: Colors.white,
      onSurface: Colors.white,
      error: Colors.red,
      onError: Colors.black,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
      bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
      labelLarge: TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.lightBlueAccent,
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.lightBlueAccent, width: 2),
      ),
      labelStyle: TextStyle(color: Colors.white70),
      hintStyle: TextStyle(color: Colors.grey[600]),
    ),
    cardTheme: CardTheme(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: const Color(0xFF192734),
    ),
    dividerColor: Colors.grey[800],
    iconTheme: const IconThemeData(color: Colors.white70),
    toggleButtonsTheme: ToggleButtonsThemeData(
      selectedColor: Colors.lightBlueAccent,
      color: Colors.white70, // Color for unselected items
      fillColor: Colors.lightBlueAccent.withOpacity(0.2),
      borderColor: Colors.grey[700],
      selectedBorderColor: Colors.lightBlueAccent,
      borderRadius: BorderRadius.circular(8),
    ),
  );
}