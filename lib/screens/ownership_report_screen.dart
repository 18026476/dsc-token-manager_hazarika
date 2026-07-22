import 'package:flutter/material.dart';
import '../repositories/asset_repository.dart';

class OwnershipReportScreen extends StatefulWidget {
  const OwnershipReportScreen({super.key});

  @override
  State<OwnershipReportScreen> createState() => _OwnershipReportScreenState();
}

class _OwnershipReportScreenState extends State<OwnershipReportScreen> {
  final AssetRepository repository = AssetRepository();

  List<Map<String, dynamic>> certificateOwnership = [];
  List<Map<String, dynamic>> tokenOwnership = [];
  List<Map<String, dynamic>> auditLogs = [];

  bool loading = false;

  @override
  void initState() {
    super.initState();
    loadOwnership();
  }

  Future<void> loadOwnership() async {
    setState(() => loading = true);

    final certs = await repository.getCertificateOwnership();
    final tokens = await repository.getTokenOwnership();
    final logs = await repository.getAssignmentAuditLogs();

    setState(() {
      certificateOwnership = certs;
      tokenOwnership = tokens;
      auditLogs = logs;
      loading = false;
    });
  }

  String ownerName(Map<String, dynamic> row) {
    final value = row['employee_name'];
    if (value == null || value.toString().trim().isEmpty) return 'Unassigned';
    return value.toString();
  }

  int assignedCount(List<Map<String, dynamic>> rows) {
    return rows.where((row) => ownerName(row) != 'Unassigned').length;
  }

  int unassignedCount(List<Map<String, dynamic>> rows) {
    return rows.where((row) => ownerName(row) == 'Unassigned').length;
  }

  @override
  Widget build(BuildContext context) {
    final assignedCertificates = assignedCount(certificateOwnership);
    final unassignedCertificates = unassignedCount(certificateOwnership);
    final assignedTokens = assignedCount(tokenOwnership);
    final unassignedTokens = unassignedCount(tokenOwnership);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ownership Dashboard'),
          actions: [
            IconButton(
              onPressed: loadOwnership,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh ownership report',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Certificates'),
              Tab(text: 'Signing Devices'),
              Tab(text: 'Audit Logs'),
            ],
          ),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _summaryCard(
                          'Assigned Certificates',
                          assignedCertificates.toString(),
                        ),
                        _summaryCard(
                          'Unassigned Certificates',
                          unassignedCertificates.toString(),
                        ),
                        _summaryCard(
                          'Assigned Signing Devices',
                          assignedTokens.toString(),
                        ),
                        _summaryCard(
                          'Unassigned Signing Devices',
                          unassignedTokens.toString(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _certificateOwnershipView(),
                        _tokenOwnershipView(),
                        _auditLogView(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _summaryCard(String title, String value) {
    return SizedBox(
      width: 220,
      height: 100,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _certificateOwnershipView() {
    if (certificateOwnership.isEmpty) {
      return const Center(
        child: Text('No certificate ownership records found.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Certificate Holder')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Expiry')),
                DataColumn(label: Text('Owner')),
                DataColumn(label: Text('Manager')),
                DataColumn(label: Text('Location')),
                DataColumn(label: Text('Thumbprint')),
              ],
              rows: certificateOwnership.map((row) {
                return DataRow(
                  cells: [
                    DataCell(Text(row['holder']?.toString() ?? '')),
                    DataCell(Text(row['status']?.toString() ?? '')),
                    DataCell(Text(row['expiry_date']?.toString() ?? '')),
                    DataCell(Text(ownerName(row))),
                    DataCell(Text(row['manager_name']?.toString() ?? '')),
                    DataCell(Text(row['location']?.toString() ?? '')),
                    DataCell(Text(row['thumbprint']?.toString() ?? '')),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tokenOwnershipView() {
    if (tokenOwnership.isEmpty) {
      return const Center(
        child: Text('No signing device ownership records found.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Signing Device')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Owner')),
                DataColumn(label: Text('Manager')),
                DataColumn(label: Text('Location')),
                DataColumn(label: Text('Instance ID')),
              ],
              rows: tokenOwnership.map((row) {
                return DataRow(
                  cells: [
                    DataCell(Text(row['device_name']?.toString() ?? '')),
                    DataCell(Text(row['token_brand']?.toString() ?? '')),
                    DataCell(Text(row['status']?.toString() ?? '')),
                    DataCell(Text(ownerName(row))),
                    DataCell(Text(row['manager_name']?.toString() ?? '')),
                    DataCell(Text(row['location']?.toString() ?? '')),
                    DataCell(Text(row['instance_id']?.toString() ?? '')),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _auditLogView() {
    if (auditLogs.isEmpty) {
      return const Center(child: Text('No assignment audit logs found yet.'));
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: ListView(
        children: auditLogs.map((log) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.history),
              title: Text(log['action']?.toString() ?? ''),
              subtitle: Text(
                'Asset Type: ${log['asset_type']}\n'
                'Employee: ${log['employee_name']}\n'
                'Asset ID: ${log['asset_identifier']}\n'
                'Time: ${log['created_at']}',
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
