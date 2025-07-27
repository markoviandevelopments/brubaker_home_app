import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  void _showPlaceholderDialog(BuildContext context, String title) {
    Widget content;
    if (title == 'House Rules') {
      content = const Text('1. No audiably brushing your teeth around Willoh. 2. Only chew with your mouth shut. 3. See rule 1. 4. Any mention of the Lorax should should include discourse on the system of political economy portrayed / defamed in the movie.');
    } else if (title == 'Coffee Machine') {
      content = const Text('Put coffee beans in grinder, and grind such that only a slight amount of coarseness is left. THen press into pod and run machine.');
    } else if (title == 'WiFi Setup') {
      content = const Text('WiFi Name: BrubakerWifi\nWifi Pass: Pre\$ton01');
    } else {
      content = const Text('No information available');
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: content,
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
