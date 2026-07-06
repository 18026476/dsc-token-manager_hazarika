import '../models/certificate_model.dart';
import '../models/usb_token_model.dart';

class IntelligenceService {
  Map<String, dynamic> analyzeInventory({
    required List<CertificateModel> certificates,
    required List<UsbTokenModel> usbTokens,
  }) {
    final expired = certificates.where((c) => c.status == 'Expired').length;
    final critical = certificates.where((c) => c.status == 'Critical').length;
    final warning = certificates.where((c) => c.status == 'Warning').length;
    final healthy = certificates.where((c) => c.status == 'Healthy').length;
    final possibleDsc = certificates.where((c) => c.possibleDsc == 'Yes').length;

    final expiringSoon = certificates.where((c) => c.daysLeft <= 90).length;
    final urgentRenewals = certificates.where((c) => c.daysLeft <= 30).length;

    String riskLevel = 'Low';

    if (expired > 0 || critical > 0) {
      riskLevel = 'High';
    } else if (warning > 0 || expiringSoon > 0) {
      riskLevel = 'Medium';
    }

    final recommendations = <String>[];

    if (expired > 0) {
      recommendations.add('Immediate action required: $expired certificate(s) have expired.');
    }

    if (critical > 0) {
      recommendations.add('$critical certificate(s) are critical and should be renewed within 30 days.');
    }

    if (warning > 0) {
      recommendations.add('$warning certificate(s) should be reviewed before expiry.');
    }

    if (possibleDsc == 0) {
      recommendations.add('No possible DSC certificates detected. Verify token/certificate availability.');
    }

    if (usbTokens.isEmpty) {
      recommendations.add('No USB/token devices detected. Ask user to connect DSC token.');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Certificate and token inventory appears healthy.');
    }

    return {
      'totalCertificates': certificates.length,
      'totalUsbTokens': usbTokens.length,
      'possibleDsc': possibleDsc,
      'healthy': healthy,
      'warning': warning,
      'critical': critical,
      'expired': expired,
      'expiringSoon': expiringSoon,
      'urgentRenewals': urgentRenewals,
      'riskLevel': riskLevel,
      'recommendations': recommendations,
    };
  }
}
