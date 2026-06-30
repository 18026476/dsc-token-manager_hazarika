class CertificateModel {
  final String holder;
  final String issuer;
  final String expiryDate;
  final int daysLeft;
  final String status;
  final String possibleDsc;
  final String store;
  final String serialNumber;
  final String thumbprint;
  final String hasPrivateKey;

  CertificateModel({
    required this.holder,
    required this.issuer,
    required this.expiryDate,
    required this.daysLeft,
    required this.status,
    required this.possibleDsc,
    required this.store,
    required this.serialNumber,
    required this.thumbprint,
    required this.hasPrivateKey,
  });
}
