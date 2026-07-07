class IntelligenceModel {
  final int totalCertificates;
  final int totalUsbTokens;
  final int possibleDsc;
  final int healthy;
  final int warning;
  final int critical;
  final int expired;
  final int expiringSoon;
  final int urgentRenewals;
  final String riskLevel;
  final List<String> recommendations;

  IntelligenceModel({
    required this.totalCertificates,
    required this.totalUsbTokens,
    required this.possibleDsc,
    required this.healthy,
    required this.warning,
    required this.critical,
    required this.expired,
    required this.expiringSoon,
    required this.urgentRenewals,
    required this.riskLevel,
    required this.recommendations,
  });

  dynamic operator [](String key) {
    switch (key) {
      case 'totalCertificates':
        return totalCertificates;
      case 'totalUsbTokens':
        return totalUsbTokens;
      case 'possibleDsc':
        return possibleDsc;
      case 'healthy':
        return healthy;
      case 'warning':
        return warning;
      case 'critical':
        return critical;
      case 'expired':
        return expired;
      case 'expiringSoon':
        return expiringSoon;
      case 'urgentRenewals':
        return urgentRenewals;
      case 'riskLevel':
        return riskLevel;
      case 'recommendations':
        return recommendations;
      default:
        return null;
    }
  }
}
