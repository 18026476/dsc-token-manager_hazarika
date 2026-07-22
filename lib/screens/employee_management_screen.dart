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

  final departmentNameController = TextEditingController();
  final departmentDescriptionController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final managerController = TextEditingController();
  final locationController = TextEditingController();

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

    await repository.ensureAssetTables();

    final deptResult = await repository.getDepartments();
    final employeeResult = await repository.getEmployees();

    setState(() {
      departments = deptResult;
      employees = employeeResult;

      if (departments.isNotEmpty &&
          !departments.any((d) => d.id == selectedDepartmentId)) {
        selectedDepartmentId = departments.first.id;
      }

      loading = false;
    });
  }

  Future<void> addDepartment() async {
    final name = departmentNameController.text.trim();
    final description = departmentDescriptionController.text.trim();

    if (name.isEmpty) {
      setState(() => message = 'Department name is required.');
      return;
    }

    await repository.addDepartment(
      DepartmentModel(
        name: name,
        description: description.isEmpty ? 'No description' : description,
      ),
    );

    departmentNameController.clear();
    departmentDescriptionController.clear();

    setState(() => message = 'Department created successfully.');
    await loadData();
  }

  Future<void> showEditDepartmentDialog(DepartmentModel department) async {
    final editNameController = TextEditingController(text: department.name);
    final editDescriptionController = TextEditingController(
      text: department.description,
    );

    final updated = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Department'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: editNameController,
                  decoration: const InputDecoration(
                    labelText: 'Department Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: editDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );

    if (updated == true) {
      final newName = editNameController.text.trim();
      final newDescription = editDescriptionController.text.trim();

      if (newName.isEmpty) {
        setState(() => message = 'Department name cannot be empty.');
        return;
      }

      await repository.updateDepartment(
        DepartmentModel(
          id: department.id,
          name: newName,
          description: newDescription.isEmpty
              ? 'No description'
              : newDescription,
        ),
      );

      setState(() => message = 'Department updated successfully.');
      await loadData();
    }
  }

  Future<void> confirmDeleteDepartment(DepartmentModel department) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Department'),
          content: Text(
            'Delete "${department.name}"?\n\nEmployees in this department will become Unassigned.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && department.id != null) {
      await repository.deleteDepartment(department.id!);
      setState(() => message = 'Department deleted successfully.');
      await loadData();
    }
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
    final matches = departments.where((d) => d.id == id);
    if (matches.isEmpty) return 'Unassigned';
    return matches.first.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employee & Department Management')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 420,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView(
                    children: [
                      const Text(
                        'Create Department',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: departmentNameController,
                        decoration: const InputDecoration(
                          labelText: 'Department Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: departmentDescriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: loading ? null : addDepartment,
                        child: const Text('Create Department'),
                      ),
                      const Divider(height: 32),
                      const Text(
                        'Add Employee',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
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
                          setState(() => selectedDepartmentId = value);
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
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: ListView(
                          children: [
                            const Text(
                              'Departments',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...departments.map(
                              (department) => Card(
                                child: ListTile(
                                  leading: const Icon(Icons.business),
                                  title: Text(department.name),
                                  subtitle: Text(department.description),
                                  trailing: Wrap(
                                    spacing: 8,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        tooltip: 'Edit department',
                                        onPressed: () =>
                                            showEditDepartmentDialog(
                                              department,
                                            ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        tooltip: 'Delete department',
                                        onPressed: () =>
                                            confirmDeleteDepartment(department),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Employee Directory',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
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
