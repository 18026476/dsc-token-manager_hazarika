import 'package:flutter/material.dart';
import '../models/certificate_model.dart';
import '../models/usb_token_model.dart';
import '../services/certificate_service.dart';
import '../services/usb_token_service.dart';
import '../services/report_service.dart';
import '../services/database_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final CertificateService certificateService = CertificateService();
  final UsbTokenService usbTokenService = UsbTokenService();
  final ReportService reportService = ReportService();
  final DatabaseService databaseService = DatabaseService();

  List<CertificateModel> certificates = [];
  List<UsbTokenModel> usbTokens = [];
  List<Map<String, dynamic>> recentScans = [];

  bool loading = false;
  String message = "";

  String searchQuery = "";
  String statusFilter = "All";
  bool possibleDscOnly = false;

  List<CertificateModel> get filteredCertificates {
    return certificates.where((cert) {
      final query = searchQuery.toLowerCase();

      final matchesSearch =
          cert.holder.toLowerCase().contains(query) ||
          cert.issuer.toLowerCase().contains(query) ||
          cert.serialNumber.toLowerCase().contains(query) ||
          cert.thumbprint.toLowerCase().contains(query) ||
          cert.store.toLowerCase().contains(query);

      final matchesStatus =
          statusFilter == "All" || cert.status == statusFilter;

      final matchesDsc =
          !possibleDscOnly || cert.possibleDsc == "Yes";

      return matchesSearch && matchesStatus && matchesDsc;
    }).toList();
  }

  Future<void> scanAll() async {
    setState(() {
      loading = true;
      message = "Scanning certificates and USB tokens...";
    });

    try {
      final certResult = await certificateService.scanCertificates();
      final usbResult = await usbTokenService.scanUsbTokens();

      final scanId = await databaseService.saveScanResults(
        certificates: certResult,
        usbTokens: usbResult,
      );

      final scans = await databaseService.getRecentScans();

      setState(() {
        certificates = certResult;
        usbTokens = usbResult;
        recentScans = scans;
        loading = false;
        message =
            "Scan completed and saved. Scan ID: $scanId. ${certResult.length} certificates and ${usbResult.length} USB/token devices found.";
      });
    } catch (e) {
      setState(() {
        loading = false;
        message = "Scan failed: $e";
      });
    }
  }

  Future<void> loadRecentScans() async {
    final scans = await databaseService.getRecentScans();
    setState(() {
      recentScans = scans;
    });
  }

  Future<void> exportCertificateCsv() async {
    if (certificates.isEmpty) {
      setState(() => message = "No certificates to export.");
      return;
    }

    final path = await certificateService.exportCsv(certificates);
    await databaseService.addAuditLog(
      eventType: 'EXPORT_CERTIFICATE_CSV',
      entityType: 'REPORT',
      description: 'Certificate CSV exported to $path',
    );

    setState(() => message = "Certificate CSV exported to: $path");
  }

  Future<void> exportUsbCsv() async {
    if (usbTokens.isEmpty) {
      setState(() => message = "No USB/token devices to export.");
      return;
    }

    final path = await usbTokenService.exportUsbCsv(usbTokens);
    await databaseService.addAuditLog(
      eventType: 'EXPORT_USB_CSV',
      entityType: 'REPORT',
      description: 'USB token CSV exported to $path',
    );

    setState(() => message = "USB CSV exported to: $path");
  }

  Future<void> exportCombinedReport() async {
    if (certificates.isEmpty && usbTokens.isEmpty) {
      setState(() => message = "No inventory data to export.");
      return;
    }

    final path = await reportService.exportCombinedReport(
      certificates,
      usbTokens,
    );

    await databaseService.addAuditLog(
      eventType: 'EXPORT_COMBINED_REPORT',
      entityType: 'REPORT',
      description: 'Combined inventory report exported to $path',
    );

    setState(() => message = "Combined report exported to: $path");
  }

  Color getStatusColor(String status) {
    if (status == "Expired") return Colors.red;
    if (status == "Critical") return Colors.deepOrange;
    if (status == "Warning") return Colors.amber;
    return Colors.green;
  }

  @override
  void initState() {
    super.initState();
    loadRecentScans();
    scanAll();
  }

  @override
  Widget build(BuildContext context) {
    final possibleDscCount =
        certificates.where((cert) => cert.possibleDsc == "Yes").length;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("DSC Token Manager v0.8"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Certificates"),
              Tab(text: "USB Tokens"),
              Tab(text: "Reports"),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _summaryCard("Certificates", certificates.length.toString()),
                  _summaryCard("Filtered", filteredCertificates.length.toString()),
                  _summaryCard("Possible DSC", possibleDscCount.toString()),
                  _summaryCard("USB / Tokens", usbTokens.length.toString()),
                  _summaryCard(
                    "Warning / Critical",
                    certificates
                        .where((c) =>
                            c.status == "Warning" || c.status == "Critical")
                        .length
                        .toString(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton(
                    onPressed: loading ? null : scanAll,
                    child: Text(loading ? "Scanning..." : "Scan All"),
                  ),
                  ElevatedButton(
                    onPressed: loading ? null : exportCertificateCsv,
                    child: const Text("Export Certificate CSV"),
                  ),
                  ElevatedButton(
                    onPressed: loading ? null : exportUsbCsv,
                    child: const Text("Export USB CSV"),
                  ),
                  ElevatedButton(
                    onPressed: loading ? null : exportCombinedReport,
                    child: const Text("Export Combined Report"),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(message),
              const SizedBox(height: 20),
              Expanded(
                child: TabBarView(
                  children: [
                    _certificateTable(),
                    _usbTokenTable(),
                    _reportsView(),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text("DSC Token Manager v0.8 Beta — Click any certificate row to view details"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _certificateTable() {
    final filtered = filteredCertificates;

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 360,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: "Search certificates",
                      hintText: "Holder, issuer, serial, thumbprint, store",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    value: statusFilter,
                    decoration: const InputDecoration(
                      labelText: "Status",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: "All", child: Text("All")),
                      DropdownMenuItem(value: "Healthy", child: Text("Healthy")),
                      DropdownMenuItem(value: "Warning", child: Text("Warning")),
                      DropdownMenuItem(value: "Critical", child: Text("Critical")),
                      DropdownMenuItem(value: "Expired", child: Text("Expired")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        statusFilter = value ?? "All";
                      });
                    },
                  ),
                ),
                FilterChip(
                  label: const Text("Possible DSC only"),
                  selected: possibleDscOnly,
                  onSelected: (value) {
                    setState(() {
                      possibleDscOnly = value;
                    });
                  },
                ),
                Text("Showing ${filtered.length} of ${certificates.length}"),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text("Holder")),
                    DataColumn(label: Text("Expiry")),
                    DataColumn(label: Text("Days Left")),
                    DataColumn(label: Text("Status")),
                    DataColumn(label: Text("Possible DSC")),
                    DataColumn(label: Text("Private Key")),
                    DataColumn(label: Text("Store")),
                  ],
                  rows: filtered.map((cert) {
                    return DataRow(
                      onSelectChanged: (_) => showCertificateDetails(cert),
                      cells: [
                        DataCell(Text(cert.holder)),
                        DataCell(Text(cert.expiryDate)),
                        DataCell(Text(cert.daysLeft.toString())),
                        DataCell(
                          Text(
                            cert.status,
                            style: TextStyle(
                              color: getStatusColor(cert.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DataCell(Text(cert.possibleDsc)),
                        DataCell(Text(cert.hasPrivateKey)),
                        DataCell(Text(cert.store)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _usbTokenTable() {
    if (usbTokens.isEmpty) {
      return const Center(
        child: Text("No USB token or smart card devices detected."),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text("Device Name")),
              DataColumn(label: Text("Class")),
              DataColumn(label: Text("Status")),
              DataColumn(label: Text("Possible Type")),
              DataColumn(label: Text("Instance ID")),
            ],
            rows: usbTokens.map((token) {
              return DataRow(
                      onSelectChanged: (_) => showCertificateDetails(cert),
                      cells: [
                  DataCell(Text(token.deviceName)),
                  DataCell(Text(token.deviceClass)),
                  DataCell(Text(token.status)),
                  DataCell(Text(token.possibleTokenType)),
                  DataCell(Text(token.instanceId)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _reportsView() {
    final expired =
        certificates.where((cert) => cert.status == "Expired").length;
    final warning = certificates
        .where((cert) => cert.status == "Warning" || cert.status == "Critical")
        .length;
    final healthy =
        certificates.where((cert) => cert.status == "Healthy").length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text(
              "Inventory Summary",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text("Total Certificates: ${certificates.length}"),
            Text("Filtered Certificates: ${filteredCertificates.length}"),
            Text("Possible DSC Certificates: ${certificates.where((c) => c.possibleDsc == "Yes").length}"),
            Text("USB / Token Devices Detected: ${usbTokens.length}"),
            Text("Healthy Certificates: $healthy"),
            Text("Warning / Critical Certificates: $warning"),
            Text("Expired Certificates: $expired"),
            const SizedBox(height: 24),
            const Text(
              "Recent Scan History",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (recentScans.isEmpty)
              const Text("No scan history yet. Click Scan All to save a scan."),
            ...recentScans.map(
              (scan) => Card(
                child: ListTile(
                  title: Text("Scan ID: ${scan['id']}"),
                  subtitle: Text(
                    "Time: ${scan['scan_time']}\n"
                    "Certificates: ${scan['certificate_count']} | "
                    "Tokens: ${scan['token_count']} | "
                    "Possible DSC: ${scan['possible_dsc_count']} | "
                    "Expired: ${scan['expired_count']} | "
                    "Warning: ${scan['warning_count']}",
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  void showCertificateDetails(CertificateModel cert) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Certificate Details"),
          content: SizedBox(
            width: 700,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow("Holder", cert.holder),
                  _detailRow("Issuer", cert.issuer),
                  _detailRow("Serial Number", cert.serialNumber),
                  _detailRow("Thumbprint", cert.thumbprint),
                  _detailRow("Expiry Date", cert.expiryDate),
                  _detailRow("Days Left", cert.daysLeft.toString()),
                  _detailRow("Status", cert.status),
                  _detailRow("Possible DSC", cert.possibleDsc),
                  _detailRow("Private Key", cert.hasPrivateKey),
                  _detailRow("Store Location", cert.store),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SelectableText.rich(
        TextSpan(
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  void showCertificateDetails(CertificateModel cert) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Certificate Details"),
          content: SizedBox(
            width: 700,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow("Holder", cert.holder),
                  _detailRow("Issuer", cert.issuer),
                  _detailRow("Serial Number", cert.serialNumber),
                  _detailRow("Thumbprint", cert.thumbprint),
                  _detailRow("Expiry Date", cert.expiryDate),
                  _detailRow("Days Left", cert.daysLeft.toString()),
                  _detailRow("Status", cert.status),
                  _detailRow("Possible DSC", cert.possibleDsc),
                  _detailRow("Private Key", cert.hasPrivateKey),
                  _detailRow("Store Location", cert.store),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SelectableText.rich(
        TextSpan(
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
  Widget _summaryCard(String title, String value) {
    return SizedBox(
      width: 190,
      height: 105,
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
                style: const TextStyle(fontSize: 13),
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
}


