import '../models/department_model.dart';
import '../models/employee_model.dart';
import 'package:sqflite_common/sqlite_api.dart';
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
  }

  Future<int> addDepartment(DepartmentModel department) async {
    final db = await databaseService.database;
    return db.insert('departments', department.toMap());
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

    final employeeCount = await db.rawQuery('SELECT COUNT(*) AS count FROM employees');
    final count = employeeCount.first['count'] as int;

    if (count > 0) return;

    final departments = await getDepartments();
    int? financeId = departments.isNotEmpty ? departments.first.id : null;

    await addEmployee(EmployeeModel(
      fullName: 'Rahul Sharma',
      email: 'rahul.sharma@example.com',
      phone: '+91 90000 00000',
      departmentId: financeId,
      managerName: 'Priya Singh',
      location: 'Mumbai Office',
    ));

    await addEmployee(EmployeeModel(
      fullName: 'Amit Verma',
      email: 'amit.verma@example.com',
      phone: '+91 91111 11111',
      departmentId: financeId,
      managerName: 'Neha Singh',
      location: 'Delhi Office',
    ));
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
      LEFT JOIN certificate_assignments ca
        ON cs.thumbprint = ca.thumbprint
      LEFT JOIN employees e
        ON ca.employee_id = e.id
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
      LEFT JOIN token_assignments ta
        ON uts.instance_id = ta.instance_id
      LEFT JOIN employees e
        ON ta.employee_id = e.id
      GROUP BY uts.instance_id
      ORDER BY uts.device_name ASC
    ''');
  }
}
