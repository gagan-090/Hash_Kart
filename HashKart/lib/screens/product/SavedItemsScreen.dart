import 'package:flutter/material.dart';

class SavedItemsScreen extends StatelessWidget {
  const SavedItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SavedItemsScreen')),
      body: const Center(child: Text('SavedItemsScreen Screen')),
    );
  }
}
