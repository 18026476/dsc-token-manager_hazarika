import 'package:flutter/material.dart';
import 'services/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbService = DatabaseService();
  final dbPath = await dbService.getDatabasePath();
  final departments = await dbService.getDepartments();

  await dbService.addAuditLog(
    eventType: 'DATABASE_INITIALIZED',
    entityType: 'SYSTEM',
    description: 'Database foundation created successfully.',
  );

  runApp(DatabaseTestApp(
    dbPath: dbPath,
    departments: departments,
  ));
}

class DatabaseTestApp extends StatelessWidget {
  final String dbPath;
  final List<Map<String, dynamic>> departments;

  const DatabaseTestApp({
    super.key,
    required this.dbPath,
    required this.departments,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DSC Token Manager - Database Test',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Module 1 - Database Foundation Test'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              const Text(
                'Database Created Successfully',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Database Path:'),
              SelectableText(dbPath),
              const SizedBox(height: 24),
              const Text(
                'Default Departments:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ...departments.map(
                (dept) => ListTile(
                  title: Text(dept['name'].toString()),
                  subtitle: Text(dept['description'].toString()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
