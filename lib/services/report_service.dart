import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/certificate_model.dart';
import '../models/usb_token_model.dart';

class ReportService {
  String _csvEscape(dynamic value) {
    final text = value.toString().replaceAll('"', '""');
    return '"$text"';
  }

  Future<String> exportCombinedReport(
    List<CertificateModel> certificates,
    List<UsbTokenModel> usbTokens,
  ) async {
    final rows = <List<dynamic>>[
      ['Type', 'Name', 'Status', 'Details'],
      ...certificates.map((cert) => [
            'Certificate',
            cert.holder,
            cert.status,
            'Expires ${cert.expiryDate}; Days Left ${cert.daysLeft}; Possible DSC ${cert.possibleDsc}',
          ]),
      ...usbTokens.map((token) => [
            'USB Token',
            token.deviceName,
            token.status,
            '${token.possibleTokenType}; ${token.deviceClass}',
          ])
    ];

    final csvData =
        rows.map((row) => row.map(_csvEscape).join(',')).join('\r\n');

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}\\combined_inventory_report.csv');

    await file.writeAsString(csvData);
    return file.path;
  }
}
