import 'package:flutter/material.dart';
import 'services/change_detection_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final service = ChangeDetectionService();
  final result = await service.compareLatestScans();
  final history = await service.getRecentChangeHistory();

  runApp(Module73TestApp(
    result: result,
    history: history,
  ));
}

class Module73TestApp extends StatelessWidget {
  final Map<String, dynamic> result;
  final List<Map<String, dynamic>> history;

  const Module73TestApp({
    super.key,
    required this.result,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final changes = result['changes'] as List<String>;

    return MaterialApp(
      title: 'Module 7.3 - Persistent Change History',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Module 7.3 - Persistent Change History Test'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              const Text(
                'Latest Change Detection',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text('Ready: ${result['ready']}'),
              if (result['previousScanId'] != null)
                Text('Previous Scan ID: ${result['previousScanId']}'),
              if (result['currentScanId'] != null)
                Text('Current Scan ID: ${result['currentScanId']}'),
              const SizedBox(height: 20),
              const Text(
                'Detected Changes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ...changes.map(
                (change) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.change_circle),
                    title: Text(change),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Persistent Change History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ...history.map(
                (item) => Card(
                  child: ListTile(
                    title: Text(item['title'].toString()),
                    subtitle: Text(
                      'Scan ID: ${item['scan_id']}\n'
                      'Type: ${item['change_type']}\n'
                      'Severity: ${item['severity']}\n'
                      'Detected: ${item['detected_at']}',
                    ),
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
