import 'package:flutter/material.dart';
import '../account/MyAccountScreen.dart';

class MyAccountDemo extends StatelessWidget {
  const MyAccountDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account Demo'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: const MyAccountScreen(),
    );
  }
}