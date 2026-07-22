import 'package:flutter/material.dart';
import 'services/change_detection_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final service = ChangeDetectionService();
  final result = await service.compareLatestScans();

  runApp(Module7TestApp(result: result));
}

class Module7TestApp extends StatelessWidget {
  final Map<String, dynamic> result;

  const Module7TestApp({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final changes = result['changes'] as List<String>;

    return MaterialApp(
      title: 'Module 7 - Change Detection',
      home: Scaffold(
        appBar: AppBar(title: const Text('Module 7 - Change Detection Test')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              const Text(
                'Change Detection Result',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text('Ready: ${result['ready']}'),
              if (result['previousScanId'] != null)
                Text('Previous Scan ID: ${result['previousScanId']}'),
              if (result['currentScanId'] != null)
                Text('Current Scan ID: ${result['currentScanId']}'),
              const SizedBox(height: 24),
              const Text(
                'Detected Changes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...changes.map(
                (change) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.change_circle),
                    title: Text(change),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
