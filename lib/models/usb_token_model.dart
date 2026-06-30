class UsbTokenModel {
  final String deviceName;
  final String deviceClass;
  final String status;
  final String instanceId;
  final String possibleTokenType;

  UsbTokenModel({
    required this.deviceName,
    required this.deviceClass,
    required this.status,
    required this.instanceId,
    required this.possibleTokenType,
  });
}
