import 'package:flutter/material.dart';
import 'repositories/asset_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repo = AssetRepository();

  await repo.ensureAssetTables();
  await repo.seedDemoEmployeesIfEmpty();

  final employees = await repo.getEmployees();

  debugPrint('================================');
  debugPrint('EMPLOYEE DATABASE TEST');
  debugPrint('================================');
  debugPrint('Employee count: ${employees.length}');

  for (final employee in employees) {
    debugPrint('${employee.id} | ${employee.fullName} | ${employee.email}');
  }

  debugPrint('================================');
}
