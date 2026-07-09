import 'package:sqflite_common/sqlite_api.dart';
import '../models/department_model.dart';
import '../models/employee_model.dart';
import '../services/database_service.dart';

class AssetRepository {
  final DatabaseService databaseService = DatabaseService();

  Future<void> ensureAssetTables() async {
    final db = await databaseService.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS certificate_assignments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        thumbprint TEXT UNIQUE,
        employee_id INTEGER,
        assigned_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS token_assignments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        instance_id TEXT UNIQUE,
        employee_id INTEGER,
        assigned_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS assignment_audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        asset_type TEXT,
        asset_identifier TEXT,
        employee_id INTEGER,
        employee_name TEXT,
        action TEXT,
        created_at TEXT
      )
    ''');
  }

  Future<int> addDepartment(DepartmentModel department) async {
    final db = await databaseService.database;
    return db.insert('departments', department.toMap());
  }

  Future<void> updateDepartment(DepartmentModel department) async {
    if (department.id == null) return;

    final db = await databaseService.database;

    await db.update(
      'departments',
      {
        'name': department.name,
        'description': department.description,
      },
      where: 'id = ?',
      whereArgs: [department.id],
    );
  }

  Future<void> deleteDepartment(int departmentId) async {
    final db = await databaseService.database;

    await db.update(
      'employees',
      {'department_id': null},
      where: 'department_id = ?',
      whereArgs: [departmentId],
    );

    await db.delete(
      'departments',
      where: 'id = ?',
      whereArgs: [departmentId],
    );
  }

  Future<List<DepartmentModel>> getDepartments() async {
    final db = await databaseService.database;
    final rows = await db.query('departments', orderBy: 'name ASC');
    return rows.map(DepartmentModel.fromMap).toList();
  }

  Future<int> addEmployee(EmployeeModel employee) async {
    final db = await databaseService.database;
    return db.insert('employees', employee.toMap());
  }

  Future<List<EmployeeModel>> getEmployees() async {
    final db = await databaseService.database;
    final rows = await db.query('employees', orderBy: 'full_name ASC');
    return rows.map(EmployeeModel.fromMap).toList();
  }

  Future<void> seedDemoEmployeesIfEmpty() async {
    final db = await databaseService.database;
    final result = await db.rawQuery('SELECT COUNT(*) AS count FROM employees');
    final count = result.first['count'] as int;

    if (count > 0) return;

    final departments = await getDepartments();
    final financeId = departments.isNotEmpty ? departments.first.id : null;

    await addEmployee(EmployeeModel(
      fullName: 'Rahul Sharma',
      email: 'rahul.sharma@example.com',
      phone: '+91 90000 00000',
      departmentId: financeId,
      managerName: 'Priya Singh',
      location: 'Mumbai Office',
    ));
  }

  Future<String> _employeeName(int employeeId) async {
    final db = await databaseService.database;
    final rows = await db.query(
      'employees',
      where: 'id = ?',
      whereArgs: [employeeId],
      limit: 1,
    );

    if (rows.isEmpty) return 'Unknown Employee';
    return rows.first['full_name']?.toString() ?? 'Unknown Employee';
  }

  Future<void> _addAssignmentAuditLog({
    required String assetType,
    required String assetIdentifier,
    required int employeeId,
    required String action,
  }) async {
    final db = await databaseService.database;
    await ensureAssetTables();

    final name = await _employeeName(employeeId);

    await db.insert('assignment_audit_logs', {
      'asset_type': assetType,
      'asset_identifier': assetIdentifier,
      'employee_id': employeeId,
      'employee_name': name,
      'action': action,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> assignCertificateToEmployee({
    required String thumbprint,
    required int employeeId,
  }) async {
    final db = await databaseService.database;
    await ensureAssetTables();

    await db.insert(
      'certificate_assignments',
      {
        'thumbprint': thumbprint,
        'employee_id': employeeId,
        'assigned_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await _addAssignmentAuditLog(
      assetType: 'Certificate',
      assetIdentifier: thumbprint,
      employeeId: employeeId,
      action: 'Certificate assigned to employee',
    );
  }

  Future<void> assignTokenToEmployee({
    required String instanceId,
    required int employeeId,
  }) async {
    final db = await databaseService.database;
    await ensureAssetTables();

    await db.insert(
      'token_assignments',
      {
        'instance_id': instanceId,
        'employee_id': employeeId,
        'assigned_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await _addAssignmentAuditLog(
      assetType: 'Signing Device',
      assetIdentifier: instanceId,
      employeeId: employeeId,
      action: 'Signing device assigned to employee',
    );
  }

  Future<List<Map<String, dynamic>>> getCertificateOwnership() async {
    final db = await databaseService.database;
    await ensureAssetTables();

    return db.rawQuery('''
      SELECT
        cs.holder,
        cs.thumbprint,
        cs.status,
        cs.expiry_date,
        e.full_name AS employee_name,
        e.location AS location,
        e.manager_name AS manager_name
      FROM certificate_snapshots cs
      LEFT JOIN certificate_assignments ca ON cs.thumbprint = ca.thumbprint
      LEFT JOIN employees e ON ca.employee_id = e.id
      GROUP BY cs.thumbprint
      ORDER BY cs.expiry_date ASC
    ''');
  }

  Future<List<Map<String, dynamic>>> getTokenOwnership() async {
    final db = await databaseService.database;
    await ensureAssetTables();

    return db.rawQuery('''
      SELECT
        uts.device_name,
        uts.possible_token_type AS token_brand,
        uts.instance_id,
        uts.status,
        e.full_name AS employee_name,
        e.location AS location,
        e.manager_name AS manager_name
      FROM usb_token_snapshots uts
      LEFT JOIN token_assignments ta ON uts.instance_id = ta.instance_id
      LEFT JOIN employees e ON ta.employee_id = e.id
      GROUP BY uts.instance_id
      ORDER BY uts.device_name ASC
    ''');
  }

  Future<List<Map<String, dynamic>>> getAssignmentAuditLogs() async {
    final db = await databaseService.database;
    await ensureAssetTables();

    return db.query(
      'assignment_audit_logs',
      orderBy: 'id DESC',
      limit: 50,
    );
  }
}
