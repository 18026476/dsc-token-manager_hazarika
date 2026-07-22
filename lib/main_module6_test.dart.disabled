import 'package:flutter/material.dart';
import 'models/certificate_model.dart';
import 'models/usb_token_model.dart';
import 'services/intelligence_service.dart';

void main() {
  final intelligenceService = IntelligenceService();

  final certificates = [
    CertificateModel(
      holder: 'CN=ABC Pvt Ltd',
      issuer: 'Test Issuer',
      expiryDate: '01-01-2030',
      daysLeft: 1200,
      status: 'Healthy',
      possibleDsc: 'Yes',
      store: 'Cert:\\CurrentUser\\My',
      serialNumber: 'ABC001',
      thumbprint: 'THUMB001',
      hasPrivateKey: 'True',
    ),
    CertificateModel(
      holder: 'CN=Test Expiring Soon',
      issuer: 'Test Issuer',
      expiryDate: '01-08-2026',
      daysLeft: 25,
      status: 'Critical',
      possibleDsc: 'No',
      store: 'Cert:\\CurrentUser\\My',
      serialNumber: 'ABC002',
      thumbprint: 'THUMB002',
      hasPrivateKey: 'True',
    ),
  ];

  final usbTokens = [
    UsbTokenModel(
      deviceName: 'TEST MODE - SafeNet eToken 5110',
      deviceClass: 'SmartCard',
      status: 'OK',
      instanceId: 'TEST\\SAFENET\\001',
      possibleTokenType: 'SafeNet / Gemalto Token',
    ),
  ];

  final result = intelligenceService.analyzeInventory(
    certificates: certificates,
    usbTokens: usbTokens,
  );

  runApp(Module6TestApp(result: result));
}

class Module6TestApp extends StatelessWidget {
  final Map<String, dynamic> result;

  const Module6TestApp({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final recommendations = result['recommendations'] as List<String>;

    return MaterialApp(
      title: 'Module 6 - Intelligence Engine',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Module 6 - Intelligence Engine Test'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              Text(
                'Risk Level: ${result['riskLevel']}',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text('Total Certificates: ${result['totalCertificates']}'),
              Text('USB Tokens: ${result['totalUsbTokens']}'),
              Text('Possible DSC: ${result['possibleDsc']}'),
              Text('Healthy: ${result['healthy']}'),
              Text('Warning: ${result['warning']}'),
              Text('Critical: ${result['critical']}'),
              Text('Expired: ${result['expired']}'),
              Text('Expiring Soon: ${result['expiringSoon']}'),
              Text('Urgent Renewals: ${result['urgentRenewals']}'),
              const SizedBox(height: 24),
              const Text(
                'Recommendations',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...recommendations.map(
                (item) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber),
                    title: Text(item),
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
