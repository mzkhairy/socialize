# Socialize App

## Brief Application Description

Socialize is a Flutter-based mobile application designed to help users discover, create, and join various local activities or events. This application aims to facilitate social interaction and participation in community activities around the user.

## Features and Functionalities

* Simple user authentication using a name.
* Interactive map display with the user's current location and activity pins.
* List of nearby activities sorted by distance, displaying distance (km).
* Activity filtering by category using a multi-select checkbox system.
* Complete details for each activity (description, time, participants, coordinator, etc.).
* New activity creation feature with map location selection and location search.
* Activity management by coordinators (edit, manage participants, transfer role, delete).
* Functionality to join and leave activities.
* User profile displaying basic info, related activities, and location coordinates.
* Activity-specific chat rooms for joined participants.
* In-app notification system with new message indicators.
* Theme customization (light/dark mode) with user preference saving.
* Secure API key management using a `.env` file.

## Prerequisites

* Flutter SDK (version 3.x.x or newer recommended)
* Android Studio or Visual Studio Code
* Android Emulator (API 23 or higher) or a physical Android device
* A valid Google Maps API Key

## Platform

* **Android** (Currently implemented and tested for the Android platform)

## Technology Stack

* **Framework:** Flutter
* **Language:** Dart
* **State Management:** Provider
* **Maps & Location:**
    * `google_maps_flutter` (Map Display)
    * `geolocator` (GPS Access & Distance Calculation)
    * `geocoding` (Coordinate to Address Conversion)
    * `google_maps_webservice` (Google Places API Integration for location search)
* **Local Storage:** `shared_preferences` (Theme Preferences, etc.)
* **Utilities:**
    * `intl` (Date & Time Formatting)
    * `uuid` (Unique ID Generator)
    * `flutter_dotenv` (Environment Variable Management)

## Setup to Run Locally

1.  **Clone this repository:**
    ```bash
    git clone [YOUR_REPOSITORY_URL]
    cd [YOUR_REPOSITORY_FOLDER_NAME]
    ```
2.  **Create a `.env` file:**
    In the project root directory, create a file named `.env` and add your Google API key:
    ```env
    GOOGLE_API_KEY=YOUR_OWN_GOOGLE_API_KEY_STRING
    ```
    *(Ensure this API Key has Maps SDK for Android, Places API, and Geocoding API enabled in your Google Cloud Console).*

3.  **Configure the Native Android Google Maps API Key:**
    Open the file `android/app/src/main/AndroidManifest.xml`. Find the following line and replace `YOUR_GOOGLE_API_KEY_HERE` with your Google Maps API Key:
    ```xml
    <meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_GOOGLE_API_KEY_HERE"/>
    ```
    *(You can use the same API Key as in your `.env` file if that key is configured for all required services).*

4.  **Get Flutter packages:**
    ```bash
    flutter pub get
    ```
5.  **Run the application:**
    ```bash
    flutter run
    ```