import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(SmartSprayerApp());
}

class SmartSprayerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Smart Sprayer",
      theme: ThemeData(primarySwatch: Colors.green),
      home: HomeScreen(),
    );
  }
}

