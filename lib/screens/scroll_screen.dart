import 'package:flutter/material.dart';

class ScrollScreen extends StatelessWidget {
  const ScrollScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: const [
        ListTile(
          leading: Icon(Icons.person, color: Color(0xFF8B4513)), // Brown accent
          title: Text('Guest1'),
          subtitle: Text('Howdy from Katy! Loved the local BBQ.'),
        ),
        ListTile(
          leading: Icon(Icons.person, color: Color(0xFF8B4513)),
          title: Text('Host'),
          subtitle: Text('Welcome! Check out the rodeo this weekend.'),
        ),
        // Add more dummy posts as needed
      ],
    );
  }
}
