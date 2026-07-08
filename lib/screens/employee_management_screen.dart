import 'package:flutter/material.dart';
import '../models/department_model.dart';
import '../models/employee_model.dart';
import '../repositories/asset_repository.dart';

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  final AssetRepository repository = AssetRepository();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController managerController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  List<EmployeeModel> employees = [];
  List<DepartmentModel> departments = [];

  int? selectedDepartmentId;
  bool loading = false;
  String message = '';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);

    final deptResult = await repository.getDepartments();
    final employeeResult = await repository.getEmployees();

    setState(() {
      departments = deptResult;
      employees = employeeResult;
      selectedDepartmentId =
          departments.isNotEmpty ? departments.first.id : null;
      loading = false;
    });
  }

  Future<void> addEmployee() async {
    if (nameController.text.trim().isEmpty) {
      setState(() => message = 'Employee name is required.');
      return;
    }

    await repository.addEmployee(
      EmployeeModel(
        fullName: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        departmentId: selectedDepartmentId,
        managerName: managerController.text.trim(),
        location: locationController.text.trim(),
      ),
    );

    nameController.clear();
    emailController.clear();
    phoneController.clear();
    managerController.clear();
    locationController.clear();

    setState(() => message = 'Employee added successfully.');

    await loadData();
  }

  String departmentName(int? id) {
    final matches = departments.where((department) => department.id == id);
    if (matches.isEmpty) return 'Unassigned';
    return matches.first.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 380,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView(
                    children: [
                      const Text(
                        'Add Employee',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: selectedDepartmentId,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          border: OutlineInputBorder(),
                        ),
                        items: departments
                            .map(
                              (department) => DropdownMenuItem<int>(
                                value: department.id,
                                child: Text(department.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedDepartmentId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: managerController,
                        decoration: const InputDecoration(
                          labelText: 'Manager',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: loading ? null : addEmployee,
                        child: const Text('Add Employee'),
                      ),
                      const SizedBox(height: 12),
                      Text(message),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          children: [
                            const Text(
                              'Employee Directory',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...employees.map(
                              (employee) => Card(
                                child: ListTile(
                                  leading: const Icon(Icons.person),
                                  title: Text(employee.fullName),
                                  subtitle: Text(
                                    '${employee.email}\n'
                                    'Phone: ${employee.phone}\n'
                                    'Department: ${departmentName(employee.departmentId)}\n'
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
            ),
          ],
        ),
      ),
    );
  }
}
