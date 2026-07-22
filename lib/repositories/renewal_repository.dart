import 'package:sqflite_common/sqlite_api.dart';

import '../models/renewal_task_model.dart';
import '../services/database_service.dart';

class RenewalRepository {
  final DatabaseService databaseService = DatabaseService();

  static const List<String> workflowStatuses = [
    'New',
    'Assigned',
    'Waiting for Vendor',
    'CSR Generated',
    'Certificate Issued',
    'Installed',
    'Verified',
    'Closed',
  ];

  static const List<String> priorities = ['Critical', 'High', 'Medium', 'Low'];

  Future<void> ensureRenewalTable() async {
    final db = await databaseService.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS renewal_tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        certificate_thumbprint TEXT NOT NULL UNIQUE,
        certificate_holder TEXT NOT NULL DEFAULT '',
        expiry_date TEXT NOT NULL DEFAULT '',
        days_remaining INTEGER NOT NULL DEFAULT 0,
        expiry_category TEXT NOT NULL DEFAULT 'Unknown',
        status TEXT NOT NULL DEFAULT 'New',
        priority TEXT NOT NULL DEFAULT 'Medium',
        assigned_to TEXT NOT NULL DEFAULT '',
        vendor TEXT NOT NULL DEFAULT '',
        estimated_cost REAL NOT NULL DEFAULT 0,
        due_date TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        completed_at TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_renewal_status
      ON renewal_tasks(status)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_renewal_priority
      ON renewal_tasks(priority)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_renewal_expiry
      ON renewal_tasks(expiry_date)
    ''');
  }

  Future<List<RenewalTaskModel>> getTasks({
    String search = '',
    String status = 'All',
    String category = 'All',
  }) async {
    final db = await databaseService.database;
    await ensureRenewalTable();

    final whereParts = <String>[];
    final whereArgs = <Object?>[];

    if (search.trim().isNotEmpty) {
      whereParts.add('''
        (
          certificate_holder LIKE ?
          OR certificate_thumbprint LIKE ?
          OR assigned_to LIKE ?
          OR vendor LIKE ?
          OR notes LIKE ?
        )
      ''');

      final term = '%${search.trim()}%';
      whereArgs.addAll([term, term, term, term, term]);
    }

    if (status != 'All') {
      whereParts.add('status = ?');
      whereArgs.add(status);
    }

    if (category != 'All') {
      whereParts.add('expiry_category = ?');
      whereArgs.add(category);
    }

    final rows = await db.query(
      'renewal_tasks',
      where: whereParts.isEmpty ? null : whereParts.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: '''
        CASE priority
          WHEN 'Critical' THEN 1
          WHEN 'High' THEN 2
          WHEN 'Medium' THEN 3
          WHEN 'Low' THEN 4
          ELSE 5
        END,
        days_remaining ASC,
        id DESC
      ''',
    );

    return rows.map(RenewalTaskModel.fromMap).toList();
  }

  Future<RenewalTaskModel?> getTaskByThumbprint(String thumbprint) async {
    final db = await databaseService.database;
    await ensureRenewalTable();

    final rows = await db.query(
      'renewal_tasks',
      where: 'certificate_thumbprint = ?',
      whereArgs: [thumbprint],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return RenewalTaskModel.fromMap(rows.first);
  }

  Future<int> createTask(RenewalTaskModel task) async {
    final db = await databaseService.database;
    await ensureRenewalTable();

    return db.insert(
      'renewal_tasks',
      task.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> upsertTask(RenewalTaskModel task) async {
    final db = await databaseService.database;
    await ensureRenewalTable();

    final existing = await getTaskByThumbprint(task.certificateThumbprint);

    if (existing == null) {
      await db.insert(
        'renewal_tasks',
        task.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      return;
    }

    await db.update(
      'renewal_tasks',
      {
        'certificate_holder': task.certificateHolder,
        'expiry_date': task.expiryDate,
        'days_remaining': task.daysRemaining,
        'expiry_category': task.expiryCategory,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'certificate_thumbprint = ?',
      whereArgs: [task.certificateThumbprint],
    );
  }

  Future<void> updateTask(RenewalTaskModel task) async {
    if (task.id == null) {
      throw ArgumentError('A task ID is required for update.');
    }

    final db = await databaseService.database;
    await ensureRenewalTable();

    final updatedTask = task.copyWith(
      updatedAt: DateTime.now().toIso8601String(),
    );

    await db.update(
      'renewal_tasks',
      updatedTask.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> updateTaskStatus({
    required int taskId,
    required String status,
  }) async {
    final db = await databaseService.database;
    await ensureRenewalTable();

    final isCompleted = status == 'Closed';

    await db.update(
      'renewal_tasks',
      {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
        'completed_at': isCompleted ? DateTime.now().toIso8601String() : null,
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> deleteTask(int taskId) async {
    final db = await databaseService.database;
    await ensureRenewalTable();

    await db.delete('renewal_tasks', where: 'id = ?', whereArgs: [taskId]);
  }

  Future<int> synchronizeCertificateRenewals({
    int renewalWindowDays = 90,
  }) async {
    final db = await databaseService.database;
    await ensureRenewalTable();

    final tableExists = await db.rawQuery('''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
      AND name = 'certificate_snapshots'
      LIMIT 1
    ''');

    if (tableExists.isEmpty) return 0;

    final columns = await db.rawQuery(
      'PRAGMA table_info(certificate_snapshots)',
    );

    final columnNames = columns
        .map((row) => row['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toSet();

    if (!columnNames.contains('thumbprint') ||
        !columnNames.contains('expiry_date')) {
      return 0;
    }

    final holderColumn = columnNames.contains('holder')
        ? 'holder'
        : columnNames.contains('subject')
        ? 'subject'
        : null;

    final selectedHolder = holderColumn == null
        ? "'' AS certificate_holder"
        : '$holderColumn AS certificate_holder';

    final certificateRows = await db.rawQuery('''
      SELECT
        thumbprint,
        $selectedHolder,
        expiry_date
      FROM certificate_snapshots
      WHERE thumbprint IS NOT NULL
      AND TRIM(thumbprint) != ''
      GROUP BY thumbprint
    ''');

    var synchronizedCount = 0;

    for (final row in certificateRows) {
      final thumbprint = row['thumbprint']?.toString().trim() ?? '';
      final holder = row['certificate_holder']?.toString().trim() ?? '';
      final expiryText = row['expiry_date']?.toString().trim() ?? '';

      if (thumbprint.isEmpty || expiryText.isEmpty) continue;

      final expiryDate = parseCertificateDate(expiryText);
      if (expiryDate == null) continue;

      final daysRemaining = calculateDaysRemaining(expiryDate);

      if (daysRemaining > renewalWindowDays) {
        continue;
      }

      final category = classifyExpiry(daysRemaining);
      final priority = priorityForDays(daysRemaining);
      final now = DateTime.now().toIso8601String();

      final task = RenewalTaskModel(
        certificateThumbprint: thumbprint,
        certificateHolder: holder.isEmpty
            ? 'Unknown Certificate Holder'
            : holder,
        expiryDate: expiryDate.toIso8601String(),
        daysRemaining: daysRemaining,
        expiryCategory: category,
        status: 'New',
        priority: priority,
        assignedTo: '',
        vendor: '',
        estimatedCost: 0,
        dueDate: recommendedDueDate(expiryDate).toIso8601String(),
        notes: 'Automatically created from certificate inventory.',
        createdAt: now,
        updatedAt: now,
      );

      await upsertTask(task);
      synchronizedCount++;
    }

    return synchronizedCount;
  }

  Future<Map<String, int>> getSummary() async {
    final tasks = await getTasks();

    int expired = 0;
    int critical = 0;
    int warning = 0;
    int healthy = 0;
    int open = 0;
    int closed = 0;
    int renewedThisMonth = 0;

    final now = DateTime.now();

    for (final task in tasks) {
      switch (task.expiryCategory) {
        case 'Expired':
          expired++;
          break;
        case 'Critical':
          critical++;
          break;
        case 'Warning':
          warning++;
          break;
        default:
          healthy++;
      }

      if (task.status == 'Closed') {
        closed++;

        final completed = DateTime.tryParse(task.completedAt ?? '');
        if (completed != null &&
            completed.year == now.year &&
            completed.month == now.month) {
          renewedThisMonth++;
        }
      } else {
        open++;
      }
    }

    return {
      'total': tasks.length,
      'expired': expired,
      'critical': critical,
      'warning': warning,
      'healthy': healthy,
      'open': open,
      'closed': closed,
      'renewedThisMonth': renewedThisMonth,
    };
  }

  static int calculateDaysRemaining(DateTime expiryDate) {
    final today = DateTime.now();
    final currentDate = DateTime(today.year, today.month, today.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);

    return expiry.difference(currentDate).inDays;
  }

  static String classifyExpiry(int daysRemaining) {
    if (daysRemaining < 0) return 'Expired';
    if (daysRemaining <= 30) return 'Critical';
    if (daysRemaining <= 90) return 'Warning';
    return 'Healthy';
  }

  static String priorityForDays(int daysRemaining) {
    if (daysRemaining < 0) return 'Critical';
    if (daysRemaining <= 14) return 'Critical';
    if (daysRemaining <= 30) return 'High';
    if (daysRemaining <= 60) return 'Medium';
    return 'Low';
  }

  static DateTime recommendedDueDate(DateTime expiryDate) {
    final proposed = expiryDate.subtract(const Duration(days: 14));
    final now = DateTime.now();

    if (proposed.isBefore(now)) {
      return now;
    }

    return proposed;
  }

  static DateTime? parseCertificateDate(String value) {
    final direct = DateTime.tryParse(value);
    if (direct != null) return direct;

    final normalized = value.trim();

    final dayMonthYear = RegExp(
      r'^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})',
    ).firstMatch(normalized);

    if (dayMonthYear != null) {
      final day = int.tryParse(dayMonthYear.group(1)!);
      final month = int.tryParse(dayMonthYear.group(2)!);
      final year = int.tryParse(dayMonthYear.group(3)!);

      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    final yearMonthDay = RegExp(
      r'^(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})',
    ).firstMatch(normalized);

    if (yearMonthDay != null) {
      final year = int.tryParse(yearMonthDay.group(1)!);
      final month = int.tryParse(yearMonthDay.group(2)!);
      final day = int.tryParse(yearMonthDay.group(3)!);

      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }
}
