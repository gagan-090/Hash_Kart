import 'package:flutter/material.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HelpCenterScreen')),
      body: const Center(child: Text('HelpCenterScreen Screen')),
    );
  }
}
