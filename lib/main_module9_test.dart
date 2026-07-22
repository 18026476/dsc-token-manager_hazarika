import 'package:flutter/material.dart';
import 'screens/renewal_centre_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const Module9TestApp());
}

class Module9TestApp extends StatelessWidget {
  const Module9TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DSC Token Manager - Module 9',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const RenewalCentreScreen(),
    );
  }
}
