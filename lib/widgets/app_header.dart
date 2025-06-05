import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socialize/providers/theme_provider.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title; // Optional title, if needed beyond logo
  final bool showThemeToggle;

  const AppHeader({super.key, this.title = "Socialize", this.showThemeToggle = true, required List<Stack> actions});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return AppBar(
      automaticallyImplyLeading: ModalRoute.of(context)?.canPop ?? false,
      title: Row(
        children: [
          Image.asset(
            isDarkMode ? 'assets/images/logo_dark.png' : 'assets/images/logo_light.png',
            height: 30, // Adjust size as needed
            errorBuilder: (context, error, stackTrace) => Icon(Icons.ac_unit_sharp, color: Theme.of(context).colorScheme.primary), // Fallback icon
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).appBarTheme.titleTextStyle?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        if (showThemeToggle)
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Theme.of(context).appBarTheme.iconTheme?.color,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
      ],
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: Theme.of(context).appBarTheme.elevation,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight); // Standard AppBar height
}