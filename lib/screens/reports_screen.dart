import 'package:flutter/material.dart';
import '../models/intelligence_model.dart';
import '../models/change_model.dart';
import '../services/change_detection_service.dart';
import '../widgets/risk_indicator.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/scan_summary_card.dart';
import '../widgets/change_tile.dart';
import '../widgets/change_summary_card.dart';

class ReportsScreen extends StatelessWidget {
  final IntelligenceModel intelligence;
  final List<Map<String, dynamic>> recentScans;

  ReportsScreen({
    super.key,
    required this.intelligence,
    required this.recentScans,
  });

  final ChangeDetectionService changeDetectionService =
      ChangeDetectionService();

  String _severityFromText(String text) {
    final lower = text.toLowerCase();

    if (lower.contains('removed') ||
        lower.contains('expired') ||
        lower.contains('missing')) {
      return 'Critical';
    }

    if (lower.contains('changed') ||
        lower.contains('warning') ||
        lower.contains('expiry')) {
      return 'Warning';
    }

    return 'Info';
  }

  ChangeModel _toChangeModel(String text) {
    return ChangeModel(
      title: text,
      description: 'Detected during latest scan comparison.',
      severity: _severityFromText(text),
      detectedAt: DateTime.now(),
    );
  }

  ChangeModel _historyToChangeModel(Map<String, dynamic> row) {
    return ChangeModel(
      title: row['title']?.toString() ?? 'Unknown change',
      description: row['description']?.toString() ?? '',
      severity: row['severity']?.toString() ?? 'Info',
      detectedAt: DateTime.tryParse(row['detected_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: changeDetectionService.compareLatestScans(),
      builder: (context, snapshot) {
        final rawChanges = snapshot.data?['changes'] as List<String>? ?? [];
        final changes = rawChanges.map(_toChangeModel).toList();

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: changeDetectionService.getRecentChangeHistory(),
          builder: (context, historySnapshot) {
            final historyRows = historySnapshot.data ?? [];
            final historyChanges =
                historyRows.map(_historyToChangeModel).toList();

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ListView(
                    children: [
                      const Text(
                        "Intelligence Summary",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
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
                            title: "Signing Devices",
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
                          ChangeSummaryCard(count: changes.length),
                        ],
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        "Recommendations",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ...intelligence.recommendations.map(
                        (item) => RecommendationCard(text: item),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        "Changes Since Last Scan",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Text("Checking latest scan changes..."),

                      if (changes.isEmpty &&
                          snapshot.connectionState != ConnectionState.waiting)
                        const Text("No change detection data available yet."),

                      ...changes.map(
                        (change) => ChangeTile(change: change),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        "Persistent Change History",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (historySnapshot.connectionState ==
                          ConnectionState.waiting)
                        const Text("Loading saved change history..."),

                      if (historyChanges.isEmpty &&
                          historySnapshot.connectionState !=
                              ConnectionState.waiting)
                        const Text("No saved change history yet."),

                      ...historyChanges.map(
                        (change) => ChangeTile(change: change),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        "Recent Scan History",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (recentScans.isEmpty)
                        const Text(
                          "No scan history yet. Click Scan All to save a scan.",
                        ),

                      ...recentScans.map(
                        (scan) => Card(
                          child: ListTile(
                            title: Text("Scan ID: ${scan['id']}"),
                            subtitle: Text(
                              "Time: ${scan['scan_time']}\n"
                              "Certificates: ${scan['certificate_count']} | "
                              "Signing Devices: ${scan['token_count']} | "
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
          },
        );
      },
    );
  }
}
