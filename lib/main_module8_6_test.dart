import 'package:flutter/material.dart';
import 'screens/certificate_assignment_screen.dart';

void main() {
  runApp(const Module86TestApp());
}

class Module86TestApp extends StatelessWidget {
  const Module86TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Module 8.6 - Certificate Assignment',
      home: CertificateAssignmentScreen(),
    );
  }
}
