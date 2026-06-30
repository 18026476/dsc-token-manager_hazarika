import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/usb_token_model.dart';

class UsbTokenService {
  Future<List<UsbTokenModel>> scanUsbTokens() async {
    final script = r'''
$devices = Get-PnpDevice | Where-Object {
    $_.Status -eq "OK" -and
    (
        $_.FriendlyName -match "SafeNet|Gemalto|ProxKey|WatchData|ePass|Smart Card|SmartCard|Token|DSC|Cryptographic|CCID|USB Smart Card" -or
        $_.Class -match "SmartCard"
    )
}

$results = foreach ($device in $devices) {
    $possibleTokenType = "Possible Token / Reader"

    if ($device.FriendlyName -match "SafeNet|Gemalto") {
        $possibleTokenType = "SafeNet / Gemalto Token"
    }
    elseif ($device.FriendlyName -match "ProxKey") {
        $possibleTokenType = "ProxKey Token"
    }
    elseif ($device.FriendlyName -match "WatchData") {
        $possibleTokenType = "WatchData Token"
    }
    elseif ($device.FriendlyName -match "ePass") {
        $possibleTokenType = "ePass Token"
    }
    elseif ($device.FriendlyName -match "CCID|Smart Card|SmartCard|USB Smart Card") {
        $possibleTokenType = "Smart Card Reader"
    }
    elseif ($device.FriendlyName -match "Cryptographic|DSC|Token") {
        $possibleTokenType = "Cryptographic Token"
    }

    [PSCustomObject]@{
        deviceName = $device.FriendlyName
        deviceClass = $device.Class
        status = $device.Status
        instanceId = $device.InstanceId
        possibleTokenType = $possibleTokenType
    }
}

$results | Sort-Object deviceName | ConvertTo-Json -Depth 5
''';

    final result = await Process.run(
      'powershell.exe',
      ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', script],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );

    final List<UsbTokenModel> tokens = [];

    if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
      final decoded = jsonDecode(result.stdout);
      final List<dynamic> items = decoded is List ? decoded : [decoded];

      tokens.addAll(items.map((item) {
        return UsbTokenModel(
          deviceName: item['deviceName']?.toString() ?? '',
          deviceClass: item['deviceClass']?.toString() ?? '',
          status: item['status']?.toString() ?? '',
          instanceId: item['instanceId']?.toString() ?? '',
          possibleTokenType: item['possibleTokenType']?.toString() ?? '',
        );
      }));
    }

    tokens.add(
      UsbTokenModel(
        deviceName: 'TEST MODE - SafeNet eToken 5110',
        deviceClass: 'SmartCard',
        status: 'OK',
        instanceId: 'TEST\\SAFENET_ETOKEN_5110\\001',
        possibleTokenType: 'SafeNet / Gemalto Token',
      ),
    );

    tokens.add(
      UsbTokenModel(
        deviceName: 'TEST MODE - ProxKey USB Token',
        deviceClass: 'SmartCard',
        status: 'OK',
        instanceId: 'TEST\\PROXKEY_USB_TOKEN\\001',
        possibleTokenType: 'ProxKey Token',
      ),
    );

    return tokens;
  }

  String _csvEscape(dynamic value) {
    final text = value.toString().replaceAll('"', '""');
    return '"$text"';
  }

  Future<String> exportUsbCsv(List<UsbTokenModel> tokens) async {
    final rows = <List<dynamic>>[
      ['Device Name', 'Class', 'Status', 'Possible Type', 'Instance ID'],
      ...tokens.map((token) => [
            token.deviceName,
            token.deviceClass,
            token.status,
            token.possibleTokenType,
            token.instanceId,
          ])
    ];

    final csvData =
        rows.map((row) => row.map(_csvEscape).join(',')).join('\r\n');

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}\\usb_token_inventory.csv');

    await file.writeAsString(csvData);
    return file.path;
  }
}
