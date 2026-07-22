import 'package:flutter/material.dart';

import '../models/employee_model.dart';
import '../repositories/asset_repository.dart';
import '../services/database_service.dart';

class CertificateAssignmentScreen extends StatefulWidget {
  const CertificateAssignmentScreen({super.key});

  @override
  State<CertificateAssignmentScreen> createState() =>
      _CertificateAssignmentScreenState();
}

class _CertificateAssignmentScreenState
    extends State<CertificateAssignmentScreen> {
  final AssetRepository repository = AssetRepository();
  final DatabaseService databaseService = DatabaseService();

  List<EmployeeModel> employees = [];
  List<Map<String, dynamic>> certificates = [];
  Map<String, int?> assignments = {};

  bool loading = true;
  String message = '';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);

    await repository.ensureAssetTables();
    await repository.seedDemoEmployeesIfEmpty();

    final employeeResult = await repository.getEmployees();
    final db = await databaseService.database;

    final certRows = await db.query(
      'certificate_snapshots',
      orderBy: 'id DESC',
    );

    final unique = <String, Map<String, dynamic>>{};

    for (final cert in certRows) {
      final thumbprint = cert['thumbprint']?.toString() ?? '';
      if (thumbprint.isNotEmpty && !unique.containsKey(thumbprint)) {
        unique[thumbprint] = cert;
      }
    }

    setState(() {
      employees = employeeResult;
      certificates = unique.values.toList();
      loading = false;
    });
  }

  Future<void> saveAssignment(String thumbprint, int employeeId) async {
    await repository.assignCertificateToEmployee(
      thumbprint: thumbprint,
      employeeId: employeeId,
    );

    setState(() {
      assignments[thumbprint] = employeeId;
      message = 'Certificate assigned successfully.';
    });
  }

  String employeeName(int? id) {
    if (id == null) return 'Unassigned';
    final match = employees.where((employee) => employee.id == id);
    if (match.isEmpty) return 'Unassigned';
    return match.first.fullName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Certificate Assignment')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    message,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Card(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Certificate Holder')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Expiry')),
                              DataColumn(label: Text('Current Owner')),
                              DataColumn(label: Text('Assign To')),
                              DataColumn(label: Text('Action')),
                            ],
                            rows: certificates.map((cert) {
                              final thumbprint =
                                  cert['thumbprint']?.toString() ?? '';
                              final selectedEmployeeId =
                                  assignments[thumbprint];

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(cert['holder']?.toString() ?? ''),
                                  ),
                                  DataCell(
                                    Text(cert['status']?.toString() ?? ''),
                                  ),
                                  DataCell(
                                    Text(cert['expiry_date']?.toString() ?? ''),
                                  ),
                                  DataCell(
                                    Text(employeeName(selectedEmployeeId)),
                                  ),
                                  DataCell(
                                    DropdownButton<int>(
                                      value: selectedEmployeeId,
                                      hint: const Text('Select employee'),
                                      items: employees.map((employee) {
                                        return DropdownMenuItem<int>(
                                          value: employee.id,
                                          child: Text(employee.fullName),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          assignments[thumbprint] = value;
                                        });
                                      },
                                    ),
                                  ),
                                  DataCell(
                                    ElevatedButton(
                                      onPressed: selectedEmployeeId == null
                                          ? null
                                          : () => saveAssignment(
                                              thumbprint,
                                              selectedEmployeeId,
                                            ),
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
