import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/certificate_model.dart';
import '../models/usb_token_model.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = join(dir.path, 'dsc_token_manager.db');

    _database = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _createDatabase,
      ),
    );

    return _database!;
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE departments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE employees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        department_id INTEGER,
        manager_name TEXT,
        location TEXT,
        created_at TEXT,
        FOREIGN KEY (department_id) REFERENCES departments(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE tokens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        token_brand TEXT,
        token_model TEXT,
        serial_number TEXT,
        device_name TEXT,
        instance_id TEXT,
        assigned_employee_id INTEGER,
        purchase_date TEXT,
        warranty_expiry TEXT,
        vendor TEXT,
        status TEXT,
        notes TEXT,
        created_at TEXT,
        FOREIGN KEY (assigned_employee_id) REFERENCES employees(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE certificates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        holder TEXT,
        issuer TEXT,
        serial_number TEXT,
        thumbprint TEXT,
        expiry_date TEXT,
        days_left INTEGER,
        status TEXT,
        possible_dsc TEXT,
        has_private_key TEXT,
        store_location TEXT,
        assigned_employee_id INTEGER,
        token_id INTEGER,
        renewal_vendor TEXT,
        notes TEXT,
        created_at TEXT,
        FOREIGN KEY (assigned_employee_id) REFERENCES employees(id),
        FOREIGN KEY (token_id) REFERENCES tokens(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE scan_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        scan_time TEXT,
        certificate_count INTEGER,
        token_count INTEGER,
        possible_dsc_count INTEGER,
        expired_count INTEGER,
        warning_count INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE renewals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        certificate_id INTEGER,
        renewal_status TEXT,
        due_date TEXT,
        assigned_to TEXT,
        vendor TEXT,
        notes TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (certificate_id) REFERENCES certificates(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_time TEXT,
        event_type TEXT,
        entity_type TEXT,
        entity_id INTEGER,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE certificate_snapshots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        scan_id INTEGER,
        holder TEXT,
        issuer TEXT,
        expiry_date TEXT,
        days_left INTEGER,
        status TEXT,
        possible_dsc TEXT,
        has_private_key TEXT,
        store_location TEXT,
        serial_number TEXT,
        thumbprint TEXT,
        FOREIGN KEY (scan_id) REFERENCES scan_history(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE usb_token_snapshots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        scan_id INTEGER,
        device_name TEXT,
        device_class TEXT,
        status TEXT,
        instance_id TEXT,
        possible_token_type TEXT,
        FOREIGN KEY (scan_id) REFERENCES scan_history(id)
      )
    ''');

    await db.insert('departments', {
      'name': 'Finance',
      'description': 'Default finance department',
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('departments', {
      'name': 'IT',
      'description': 'Default IT department',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<String> getDatabasePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return join(dir.path, 'dsc_token_manager.db');
  }

  Future<List<Map<String, dynamic>>> getDepartments() async {
    final db = await database;
    return db.query('departments', orderBy: 'name ASC');
  }

  Future<int> saveScanResults({
    required List<CertificateModel> certificates,
    required List<UsbTokenModel> usbTokens,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final possibleDscCount =
        certificates.where((c) => c.possibleDsc == 'Yes').length;

    final expiredCount =
        certificates.where((c) => c.status == 'Expired').length;

    final warningCount = certificates
        .where((c) => c.status == 'Warning' || c.status == 'Critical')
        .length;

    final scanId = await db.insert('scan_history', {
      'scan_time': now,
      'certificate_count': certificates.length,
      'token_count': usbTokens.length,
      'possible_dsc_count': possibleDscCount,
      'expired_count': expiredCount,
      'warning_count': warningCount,
    });

    for (final cert in certificates) {
      await db.insert('certificate_snapshots', {
        'scan_id': scanId,
        'holder': cert.holder,
        'issuer': cert.issuer,
        'expiry_date': cert.expiryDate,
        'days_left': cert.daysLeft,
        'status': cert.status,
        'possible_dsc': cert.possibleDsc,
        'has_private_key': cert.hasPrivateKey,
        'store_location': cert.store,
        'serial_number': cert.serialNumber,
        'thumbprint': cert.thumbprint,
      });
    }

    for (final token in usbTokens) {
      await db.insert('usb_token_snapshots', {
        'scan_id': scanId,
        'device_name': token.deviceName,
        'device_class': token.deviceClass,
        'status': token.status,
        'instance_id': token.instanceId,
        'possible_token_type': token.possibleTokenType,
      });
    }

    await addAuditLog(
      eventType: 'SCAN_SAVED',
      entityType: 'SCAN',
      entityId: scanId,
      description:
          'Saved scan with ${certificates.length} certificates and ${usbTokens.length} USB/token devices.',
    );

    return scanId;
  }

  Future<List<Map<String, dynamic>>> getRecentScans() async {
    final db = await database;

    return db.query(
      'scan_history',
      orderBy: 'id DESC',
      limit: 10,
    );
  }

  Future<void> addAuditLog({
    required String eventType,
    required String entityType,
    int? entityId,
    required String description,
  }) async {
    final db = await database;

    await db.insert('audit_logs', {
      'event_time': DateTime.now().toIso8601String(),
      'event_type': eventType,
      'entity_type': entityType,
      'entity_id': entityId,
      'description': description,
    });
  }
}
