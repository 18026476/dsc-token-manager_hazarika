import 'package:flutter/material.dart';
import 'models/certificate_model.dart';
import 'models/usb_token_model.dart';
import 'services/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbService = DatabaseService();

  final testCertificates = [
    CertificateModel(
      holder: 'TEST CERT - ABC Pvt Ltd',
      issuer: 'Test Issuer',
      expiryDate: '01-01-2030',
      daysLeft: 1200,
      status: 'Healthy',
      possibleDsc: 'Yes',
      store: 'Cert:\\CurrentUser\\My',
      serialNumber: 'TESTCERT001',
      thumbprint: 'TESTTHUMBPRINT001',
      hasPrivateKey: 'True',
    ),
  ];

  final testUsbTokens = [
    UsbTokenModel(
      deviceName: 'TEST MODE - SafeNet eToken 5110',
      deviceClass: 'SmartCard',
      status: 'OK',
      instanceId: 'TEST\\SAFENET\\001',
      possibleTokenType: 'SafeNet / Gemalto Token',
    ),
  ];

  final scanId = await dbService.saveScanResults(
    certificates: testCertificates,
    usbTokens: testUsbTokens,
  );

  final recentScans = await dbService.getRecentScans();

  runApp(Module2TestApp(
    scanId: scanId,
    recentScans: recentScans,
  ));
}

class Module2TestApp extends StatelessWidget {
  final int scanId;
  final List<Map<String, dynamic>> recentScans;

  const Module2TestApp({
    super.key,
    required this.scanId,
    required this.recentScans,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DSC Token Manager - Module 2 Test',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Module 2 - Save Scan Results Test'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              Text(
                'Scan Saved Successfully. Scan ID: $scanId',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Recent Scan History:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ...recentScans.map(
                (scan) => Card(
                  child: ListTile(
                    title: Text('Scan ID: ${scan['id']}'),
                    subtitle: Text(
                      'Time: ${scan['scan_time']}\n'
                      'Certificates: ${scan['certificate_count']} | '
                      'Tokens: ${scan['token_count']} | '
                      'Possible DSC: ${scan['possible_dsc_count']} | '
                      'Expired: ${scan['expired_count']} | '
                      'Warning: ${scan['warning_count']}',
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
