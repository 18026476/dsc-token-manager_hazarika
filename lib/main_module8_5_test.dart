import 'package:flutter/material.dart';
import 'screens/ownership_report_screen.dart';

void main() {
  runApp(const Module85TestApp());
}

class Module85TestApp extends StatelessWidget {
  const Module85TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Module 8.5 - Ownership Report',
      home: OwnershipReportScreen(),
    );
  }
}
