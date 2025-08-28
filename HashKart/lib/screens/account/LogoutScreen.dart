import 'package:flutter/material.dart';

class LogoutScreen extends StatelessWidget {
  const LogoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LogoutScreen')),
      body: const Center(child: Text('LogoutScreen Screen')),
    );
  }
}
