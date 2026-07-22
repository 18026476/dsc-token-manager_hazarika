import 'package:flutter/material.dart';

class RiskIndicator extends StatelessWidget {
  final String riskLevel;

  const RiskIndicator({super.key, required this.riskLevel});

  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.verified;
    String message = "Inventory appears healthy.";

    if (riskLevel == "High") {
      icon = Icons.dangerous;
      message = "Immediate attention required.";
    } else if (riskLevel == "Medium") {
      icon = Icons.warning_amber;
      message = "Review expiring certificates.";
    }

    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          "Risk Level: $riskLevel",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(message),
      ),
    );
  }
}
