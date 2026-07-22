import '../services/database_service.dart';

class ChangeDetectionService {
  final DatabaseService databaseService = DatabaseService();

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

  String _changeTypeFromText(String text) {
    final lower = text.toLowerCase();

    if (lower.contains('new certificate')) return 'NEW_CERTIFICATE';
    if (lower.contains('certificate removed')) return 'REMOVED_CERTIFICATE';
    if (lower.contains('expiry changed')) return 'EXPIRY_CHANGED';
    if (lower.contains('status changed')) return 'STATUS_CHANGED';
    if (lower.contains('new token')) return 'NEW_TOKEN';
    if (lower.contains('token/device removed')) return 'REMOVED_TOKEN';

    return 'GENERAL_CHANGE';
  }

  Future<void> ensureChangeHistoryTable() async {
    final db = await databaseService.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS change_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        scan_id INTEGER,
        change_type TEXT,
        severity TEXT,
        title TEXT,
        description TEXT,
        detected_at TEXT
      )
    ''');
  }

  Future<void> _saveChange({
    required int scanId,
    required String changeText,
  }) async {
    final db = await databaseService.database;

    await ensureChangeHistoryTable();

    final existing = await db.query(
      'change_history',
      where: 'scan_id = ? AND title = ?',
      whereArgs: [scanId, changeText],
      limit: 1,
    );

    if (existing.isNotEmpty) return;

    final severity = _severityFromText(changeText);
    final changeType = _changeTypeFromText(changeText);

    await db.insert('change_history', {
      'scan_id': scanId,
      'change_type': changeType,
      'severity': severity,
      'title': changeText,
      'description': 'Detected during latest scan comparison.',
      'detected_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>> compareLatestScans() async {
    final db = await databaseService.database;

    await ensureChangeHistoryTable();

    final scans = await db.query('scan_history', orderBy: 'id DESC', limit: 2);

    if (scans.length < 2) {
      return {
        'ready': false,
        'message': 'At least two scans are required for change detection.',
        'changes': <String>[],
      };
    }

    final currentScan = scans[0];
    final previousScan = scans[1];

    final currentScanId = currentScan['id'] as int;
    final previousScanId = previousScan['id'] as int;

    final currentCerts = await db.query(
      'certificate_snapshots',
      where: 'scan_id = ?',
      whereArgs: [currentScanId],
    );

    final previousCerts = await db.query(
      'certificate_snapshots',
      where: 'scan_id = ?',
      whereArgs: [previousScanId],
    );

    final currentTokens = await db.query(
      'usb_token_snapshots',
      where: 'scan_id = ?',
      whereArgs: [currentScanId],
    );

    final previousTokens = await db.query(
      'usb_token_snapshots',
      where: 'scan_id = ?',
      whereArgs: [previousScanId],
    );

    final changes = <String>[];

    final previousCertMap = {
      for (final cert in previousCerts) cert['thumbprint'].toString(): cert,
    };

    final currentCertMap = {
      for (final cert in currentCerts) cert['thumbprint'].toString(): cert,
    };

    for (final thumbprint in currentCertMap.keys) {
      if (!previousCertMap.containsKey(thumbprint)) {
        changes.add(
          'New certificate detected: ${currentCertMap[thumbprint]?['holder']}',
        );
      }
    }

    for (final thumbprint in previousCertMap.keys) {
      if (!currentCertMap.containsKey(thumbprint)) {
        changes.add(
          'Certificate removed: ${previousCertMap[thumbprint]?['holder']}',
        );
      }
    }

    for (final thumbprint in currentCertMap.keys) {
      if (previousCertMap.containsKey(thumbprint)) {
        final current = currentCertMap[thumbprint]!;
        final previous = previousCertMap[thumbprint]!;

        if (current['expiry_date'] != previous['expiry_date']) {
          changes.add(
            'Expiry changed for ${current['holder']}: ${previous['expiry_date']} -> ${current['expiry_date']}',
          );
        }

        if (current['status'] != previous['status']) {
          changes.add(
            'Status changed for ${current['holder']}: ${previous['status']} -> ${current['status']}',
          );
        }

        if (current['possible_dsc'] != previous['possible_dsc']) {
          changes.add(
            'Possible DSC status changed for ${current['holder']}: ${previous['possible_dsc']} -> ${current['possible_dsc']}',
          );
        }
      }
    }

    final previousTokenMap = {
      for (final token in previousTokens)
        token['instance_id'].toString(): token,
    };

    final currentTokenMap = {
      for (final token in currentTokens) token['instance_id'].toString(): token,
    };

    for (final id in currentTokenMap.keys) {
      if (!previousTokenMap.containsKey(id)) {
        changes.add(
          'New token/device detected: ${currentTokenMap[id]?['device_name']}',
        );
      }
    }

    for (final id in previousTokenMap.keys) {
      if (!currentTokenMap.containsKey(id)) {
        changes.add(
          'Token/device removed: ${previousTokenMap[id]?['device_name']}',
        );
      }
    }

    if (changes.isEmpty) {
      changes.add(
        'No meaningful changes detected between the latest two scans.',
      );
    }

    for (final change in changes) {
      await _saveChange(scanId: currentScanId, changeText: change);
    }

    return {
      'ready': true,
      'previousScanId': previousScanId,
      'currentScanId': currentScanId,
      'changes': changes,
    };
  }

  Future<List<Map<String, dynamic>>> getRecentChangeHistory() async {
    final db = await databaseService.database;

    await ensureChangeHistoryTable();

    return db.query('change_history', orderBy: 'id DESC', limit: 20);
  }
}
