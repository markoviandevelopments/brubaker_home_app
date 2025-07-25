import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  void _showPlaceholderDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text('Placeholder: Instructions coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        ListTile(
          leading: Icon(
            Icons.coffee_maker,
            color: Theme.of(context).primaryColor,
          ), // Brown accent
          title: const Text('How to Use Coffee Machine'),
          onTap: () => _showPlaceholderDialog(context, 'Coffee Machine'),
        ),
        ListTile(
          leading: Icon(Icons.wifi, color: Theme.of(context).primaryColor),
          title: const Text('WiFi Setup'),
          onTap: () => _showPlaceholderDialog(context, 'WiFi Setup'),
        ),
        ListTile(
          leading: Icon(Icons.home, color: Theme.of(context).primaryColor),
          title: const Text('House Rules'),
          onTap: () => _showPlaceholderDialog(context, 'House Rules'),
        ),
        // Add more as needed
      ],
    );
  }
}
