import 'package:flutter/material.dart';
import '../models/intelligence_model.dart';
import '../widgets/risk_indicator.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/scan_summary_card.dart';

class ReportsScreen extends StatelessWidget {
  final IntelligenceModel intelligence;
  final List<Map<String, dynamic>> recentScans;

  const ReportsScreen({
    super.key,
    required this.intelligence,
    required this.recentScans,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              const Text(
                "Intelligence Summary",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              RiskIndicator(riskLevel: intelligence.riskLevel),

              const SizedBox(height: 20),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ScanSummaryCard(
                    title: "Total Certificates",
                    value: intelligence.totalCertificates.toString(),
                  ),
                  ScanSummaryCard(
                    title: "USB Tokens",
                    value: intelligence.totalUsbTokens.toString(),
                  ),
                  ScanSummaryCard(
                    title: "Possible DSC",
                    value: intelligence.possibleDsc.toString(),
                  ),
                  ScanSummaryCard(
                    title: "Healthy",
                    value: intelligence.healthy.toString(),
                  ),
                  ScanSummaryCard(
                    title: "Warning",
                    value: intelligence.warning.toString(),
                  ),
                  ScanSummaryCard(
                    title: "Critical",
                    value: intelligence.critical.toString(),
                  ),
                  ScanSummaryCard(
                    title: "Expired",
                    value: intelligence.expired.toString(),
                  ),
                  ScanSummaryCard(
                    title: "Urgent Renewals",
                    value: intelligence.urgentRenewals.toString(),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                "Recommendations",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              ...intelligence.recommendations.map(
                (item) => RecommendationCard(text: item),
              ),

              const SizedBox(height: 24),

              const Text(
                "Recent Scan History",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (recentScans.isEmpty)
                const Text("No scan history yet. Click Scan All to save a scan."),

              ...recentScans.map(
                (scan) => Card(
                  child: ListTile(
                    title: Text("Scan ID: ${scan['id']}"),
                    subtitle: Text(
                      "Time: ${scan['scan_time']}\n"
                      "Certificates: ${scan['certificate_count']} | "
                      "Tokens: ${scan['token_count']} | "
                      "Possible DSC: ${scan['possible_dsc_count']} | "
                      "Expired: ${scan['expired_count']} | "
                      "Warning: ${scan['warning_count']}",
                    ),
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
