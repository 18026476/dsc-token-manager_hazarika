import 'package:flutter/material.dart';

import '../models/employee_model.dart';
import '../repositories/asset_repository.dart';
import '../services/database_service.dart';

class TokenAssignmentScreen extends StatefulWidget {
  const TokenAssignmentScreen({super.key});

  @override
  State<TokenAssignmentScreen> createState() => _TokenAssignmentScreenState();
}

class _TokenAssignmentScreenState extends State<TokenAssignmentScreen> {
  final AssetRepository repository = AssetRepository();
  final DatabaseService databaseService = DatabaseService();

  List<EmployeeModel> employees = [];
  List<Map<String, dynamic>> tokens = [];
  Map<String, int?> assignments = {};

  bool loading = true;
  String statusMessage = '';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);

    await repository.ensureAssetTables();

    final db = await databaseService.database;

    employees = await repository.getEmployees();

    final tokenRows = await db.query(
      'usb_token_snapshots',
      orderBy: 'id DESC',
    );

    final unique = <String, Map<String, dynamic>>{};

    for (final token in tokenRows) {
      final id = token['instance_id']?.toString() ?? '';
      if (id.isNotEmpty && !unique.containsKey(id)) {
        unique[id] = token;
      }
    }

    final assignmentRows = await db.query('token_assignments');

    final loadedAssignments = <String, int?>{};

    for (final row in assignmentRows) {
      loadedAssignments[row['instance_id'].toString()] =
          row['employee_id'] as int?;
    }

    setState(() {
      tokens = unique.values.toList();
      assignments = loadedAssignments;
      loading = false;
    });
  }

  Future<void> saveAssignment(String instanceId, int employeeId) async {
    await repository.assignTokenToEmployee(
      instanceId: instanceId,
      employeeId: employeeId,
    );

    setState(() {
      assignments[instanceId] = employeeId;
      statusMessage = 'Signing device assigned successfully.';
    });
  }

  String employeeName(int? id) {
    if (id == null) return 'Unassigned';

    final result = employees.where((e) => e.id == id);

    if (result.isEmpty) return 'Unassigned';

    return result.first.fullName;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Signing Device Assignment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              statusMessage,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Device')),
                        DataColumn(label: Text('Type')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Current Owner')),
                        DataColumn(label: Text('Assign To')),
                        DataColumn(label: Text('Action')),
                      ],
                      rows: tokens.map((token) {
                        final id = token['instance_id']?.toString() ?? '';
                        final selected = assignments[id];

                        return DataRow(
                          cells: [
                            DataCell(Text(token['device_name']?.toString() ?? '')),
                            DataCell(Text(token['possible_token_type']?.toString() ?? '')),
                            DataCell(Text(token['status']?.toString() ?? '')),
                            DataCell(Text(employeeName(selected))),
                            DataCell(
                              DropdownButton<int>(
                                value: selected,
                                hint: const Text('Select employee'),
                                items: employees.map((employee) {
                                  return DropdownMenuItem<int>(
                                    value: employee.id,
                                    child: Text(employee.fullName),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    assignments[id] = value;
                                  });
                                },
                              ),
                            ),
                            DataCell(
                              ElevatedButton(
                                onPressed: selected == null
                                    ? null
                                    : () => saveAssignment(id, selected),
                                child: const Text('Save'),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
