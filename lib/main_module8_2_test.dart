import 'package:flutter/material.dart';
import 'screens/employee_management_screen.dart';

void main() {
  runApp(const Module82TestApp());
}

class Module82TestApp extends StatelessWidget {
  const Module82TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Module 8.2 - Employee Management',
      home: EmployeeManagementScreen(),
    );
  }
}
