import 'dart:convert';
import 'dart:io';

class CertificateValidationService {
  Future<Map<String, String>> validateCertificate(String thumbprint) async {
    final safeThumbprint = thumbprint.replaceAll("'", "''");

    final script =
        '''
\$Thumbprint = '$safeThumbprint'

\$stores = @(
  "Cert:\\CurrentUser\\My",
  "Cert:\\LocalMachine\\My"
)

\$result = \$null

foreach (\$store in \$stores) {
  \$cert = Get-ChildItem \$store -ErrorAction SilentlyContinue |
    Where-Object { \$_.Thumbprint -eq \$Thumbprint } |
    Select-Object -First 1

  if (\$cert) {
    \$eku = (\$cert.EnhancedKeyUsageList | ForEach-Object {
      \$_.FriendlyName
    }) -join ", "

    \$result = [PSCustomObject]@{
      exists = "Yes"
      subject = \$cert.Subject
      issuer = \$cert.Issuer
      expiryDate = \$cert.NotAfter.ToString("dd-MM-yyyy")
      hasPrivateKey = \$cert.HasPrivateKey.ToString()
      thumbprint = \$cert.Thumbprint
      store = \$store
      enhancedKeyUsage = \$eku
      validationStatus = "Certificate found and validated"
    }

    break
  }
}

if (-not \$result) {
  \$result = [PSCustomObject]@{
    exists = "No"
    subject = ""
    issuer = ""
    expiryDate = ""
    hasPrivateKey = ""
    thumbprint = \$Thumbprint
    store = ""
    enhancedKeyUsage = ""
    validationStatus = "Certificate not found in Windows certificate stores"
  }
}

\$result | ConvertTo-Json -Depth 5
''';

    final result = await Process.run(
      'powershell.exe',
      ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', script],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );

    if (result.exitCode != 0 || result.stdout.toString().trim().isEmpty) {
      return {
        'exists': 'Unknown',
        'validationStatus': 'Validation failed: ${result.stderr}',
      };
    }

    final decoded = jsonDecode(result.stdout);

    return decoded.map<String, String>(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
  }
}
