import 'package:flutter/material.dart';
import 'models/department_model.dart';
import 'models/employee_model.dart';
import 'repositories/asset_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repo = AssetRepository();

  final departments = await repo.getDepartments();

  int? financeId;
  if (departments.isNotEmpty) {
    financeId = departments.first.id;
  }

  await repo.addEmployee(
    EmployeeModel(
      fullName: 'Rahul Sharma',
      email: 'rahul.sharma@example.com',
      phone: '+91 90000 00000',
      departmentId: financeId,
      managerName: 'Priya Singh',
      location: 'Mumbai Office',
    ),
  );

  final employees = await repo.getEmployees();
  final updatedDepartments = await repo.getDepartments();

  runApp(
    Module81TestApp(departments: updatedDepartments, employees: employees),
  );
}

class Module81TestApp extends StatelessWidget {
  final List<DepartmentModel> departments;
  final List<EmployeeModel> employees;

  const Module81TestApp({
    super.key,
    required this.departments,
    required this.employees,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Module 8.1 - Asset Management Foundation',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Module 8.1 - Asset Management Foundation'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              const Text(
                'Departments',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              ...departments.map(
                (department) => Card(
                  child: ListTile(
                    title: Text(department.name),
                    subtitle: Text(department.description),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Employees',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              ...employees.map(
                (employee) => Card(
                  child: ListTile(
                    title: Text(employee.fullName),
                    subtitle: Text(
                      '${employee.email}\n'
                      'Manager: ${employee.managerName}\n'
                      'Location: ${employee.location}',
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
