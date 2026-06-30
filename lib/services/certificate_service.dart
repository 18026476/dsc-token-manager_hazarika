import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/certificate_model.dart';

class CertificateService {
  Future<List<CertificateModel>> scanCertificates() async {
    final script = r'''
$Stores = @(
    "Cert:\CurrentUser\My",
    "Cert:\LocalMachine\My"
)

$AllCertificates = @()

foreach ($Store in $Stores) {
    try {
        $Certificates = Get-ChildItem $Store -ErrorAction Stop | ForEach-Object {
            $DaysLeft = ($_.NotAfter - (Get-Date)).Days

            if ($DaysLeft -lt 0) { $Status = "Expired" }
            elseif ($DaysLeft -le 30) { $Status = "Critical" }
            elseif ($DaysLeft -le 90) { $Status = "Warning" }
            else { $Status = "Healthy" }

            $EnhancedKeyUsage = ($_.EnhancedKeyUsageList | ForEach-Object {
                $_.FriendlyName
            }) -join ", "

            $PossibleDSC = "No"

            if (
                $_.HasPrivateKey -eq $true -and
                (
                    $EnhancedKeyUsage -match "Document Signing" -or
                    $EnhancedKeyUsage -match "Code Signing" -or
                    $EnhancedKeyUsage -match "Client Authentication" -or
                    $_.Subject -match "DSC" -or
                    $_.Issuer -match "eMudhra|Sify|VSign|Capricorn|NSDL|IDSign|MS-Organization-Access"
                )
            ) {
                $PossibleDSC = "Yes"
            }

            [PSCustomObject]@{
                holder = $_.Subject
                issuer = $_.Issuer
                expiryDate = $_.NotAfter.ToString("dd-MM-yyyy")
                daysLeft = $DaysLeft
                status = $Status
                possibleDsc = $PossibleDSC
                store = $Store
                serialNumber = $_.SerialNumber
                thumbprint = $_.Thumbprint
                hasPrivateKey = $_.HasPrivateKey.ToString()
            }
        }

        $AllCertificates += $Certificates
    }
    catch {}
}

$AllCertificates | ConvertTo-Json -Depth 5
''';

    final result = await Process.run(
      'powershell.exe',
      ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', script],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );

    if (result.exitCode != 0 || result.stdout.toString().trim().isEmpty) {
      return [];
    }

    final decoded = jsonDecode(result.stdout);
    final List<dynamic> items = decoded is List ? decoded : [decoded];

    return items.map((item) {
      return CertificateModel(
        holder: item['holder']?.toString() ?? '',
        issuer: item['issuer']?.toString() ?? '',
        expiryDate: item['expiryDate']?.toString() ?? '',
        daysLeft: int.tryParse(item['daysLeft'].toString()) ?? 0,
        status: item['status']?.toString() ?? '',
        possibleDsc: item['possibleDsc']?.toString() ?? 'No',
        store: item['store']?.toString() ?? '',
        serialNumber: item['serialNumber']?.toString() ?? '',
        thumbprint: item['thumbprint']?.toString() ?? '',
        hasPrivateKey: item['hasPrivateKey']?.toString() ?? '',
      );
    }).toList();
  }

  String _csvEscape(dynamic value) {
    final text = value.toString().replaceAll('"', '""');
    return '"$text"';
  }

  Future<String> exportCsv(List<CertificateModel> certificates) async {
    final rows = <List<dynamic>>[
      [
        'Holder',
        'Issuer',
        'Expiry Date',
        'Days Left',
        'Status',
        'Possible DSC',
        'Store',
        'Serial Number',
        'Thumbprint',
        'Has Private Key'
      ],
      ...certificates.map((cert) => [
            cert.holder,
            cert.issuer,
            cert.expiryDate,
            cert.daysLeft,
            cert.status,
            cert.possibleDsc,
            cert.store,
            cert.serialNumber,
            cert.thumbprint,
            cert.hasPrivateKey,
          ])
    ];

    final csvData = rows.map((row) => row.map(_csvEscape).join(',')).join('\r\n');

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}\\dsc_certificate_inventory.csv');

    await file.writeAsString(csvData);
    return file.path;
  }
}
