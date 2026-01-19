import 'package:flutter/material.dart';

class CarePage extends StatelessWidget {
  const CarePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Care (Diet & Workout)',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
