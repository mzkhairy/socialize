import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socialize/providers/app_data_provider.dart';
import 'package:socialize/providers/theme_provider.dart'; // <-- IMPORT ThemeProvider
import 'package:socialize/screens/home/home_screen.dart';
import 'package:socialize/widgets/app_header.dart'; // For theme toggle on login screen

class LoginScreen extends StatefulWidget {
  static const String routeName = '/login';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final appDataProvider = Provider.of<AppDataProvider>(context, listen: false);
      final success = await appDataProvider.login(_nameController.text.trim());
      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid name.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context); // <-- GET ThemeProvider instance

    return Scaffold(
      appBar: const AppHeader(title: "Welcome", showThemeToggle: true, actions: [],), 
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center, 
              children: <Widget>[
                Image.asset(
                  themeProvider.isDarkMode
                      ? 'assets/images/logo_dark.png'
                      : 'assets/images/logo_light.png',
                  height: 150, // Adjust height for "big" logo as needed
                  // width: 150, // Optionally set width too
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback if images are missing
                    return Icon(
                      Icons.connect_without_contact, // Placeholder icon
                      size: 100,
                      color: theme.colorScheme.primary,
                    );
                  },
                ),
                const SizedBox(height: 20), // Spacing between logo and "Socialize" text
                // --- END NEW LOGO ---
                Text(
                  'Socialize',
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Enter Your Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name cannot be empty';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Login / Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}