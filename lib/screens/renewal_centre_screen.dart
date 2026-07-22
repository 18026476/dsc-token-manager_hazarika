import 'package:flutter/material.dart';

import '../models/renewal_task_model.dart';
import '../repositories/renewal_repository.dart';

class RenewalCentreScreen extends StatefulWidget {
  const RenewalCentreScreen({super.key});

  @override
  State<RenewalCentreScreen> createState() => _RenewalCentreScreenState();
}

class _RenewalCentreScreenState extends State<RenewalCentreScreen> {
  final RenewalRepository repository = RenewalRepository();
  final TextEditingController searchController = TextEditingController();

  List<RenewalTaskModel> tasks = [];
  Map<String, int> summary = {};

  bool loading = false;
  String selectedStatus = 'All';
  String selectedCategory = 'All';
  String message = '';

  final List<String> categories = const [
    'All',
    'Expired',
    'Critical',
    'Warning',
    'Healthy',
  ];

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    await repository.ensureRenewalTable();
    await loadData();
  }

  Future<void> loadData() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      message = '';
    });

    try {
      final taskResult = await repository.getTasks(
        search: searchController.text,
        status: selectedStatus,
        category: selectedCategory,
      );

      final summaryResult = await repository.getSummary();

      if (!mounted) return;

      setState(() {
        tasks = taskResult;
        summary = summaryResult;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loading = false;
        message = 'Unable to load Renewal Centre: $error';
      });
    }
  }

  Future<void> synchronizeCertificates() async {
    setState(() {
      loading = true;
      message = 'Scanning certificate inventory...';
    });

    try {
      final count = await repository.synchronizeCertificateRenewals();

      if (!mounted) return;

      setState(() {
        message = '$count certificate renewal record(s) synchronized.';
      });

      await loadData();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loading = false;
        message = 'Certificate synchronization failed: $error';
      });
    }
  }

  Future<void> openTaskDialog({RenewalTaskModel? existingTask}) async {
    final holderController = TextEditingController(
      text: existingTask?.certificateHolder ?? '',
    );

    final thumbprintController = TextEditingController(
      text: existingTask?.certificateThumbprint ?? '',
    );

    final assignedController = TextEditingController(
      text: existingTask?.assignedTo ?? '',
    );

    final vendorController = TextEditingController(
      text: existingTask?.vendor ?? '',
    );

    final costController = TextEditingController(
      text: existingTask == null || existingTask.estimatedCost == 0
          ? ''
          : existingTask.estimatedCost.toStringAsFixed(2),
    );

    final notesController = TextEditingController(
      text: existingTask?.notes ?? '',
    );

    DateTime expiryDate =
        DateTime.tryParse(existingTask?.expiryDate ?? '') ??
        DateTime.now().add(const Duration(days: 60));

    DateTime dueDate =
        DateTime.tryParse(existingTask?.dueDate ?? '') ??
        RenewalRepository.recommendedDueDate(expiryDate);

    String selectedTaskStatus = existingTask?.status ?? 'New';
    String selectedPriority = existingTask?.priority ?? 'Medium';

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> chooseExpiryDate() async {
              final selected = await showDatePicker(
                context: context,
                initialDate: expiryDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );

              if (selected != null) {
                setDialogState(() {
                  expiryDate = selected;

                  if (existingTask == null) {
                    dueDate = RenewalRepository.recommendedDueDate(selected);
                  }
                });
              }
            }

            Future<void> chooseDueDate() async {
              final selected = await showDatePicker(
                context: context,
                initialDate: dueDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );

              if (selected != null) {
                setDialogState(() {
                  dueDate = selected;
                });
              }
            }

            return AlertDialog(
              title: Text(
                existingTask == null
                    ? 'Create Renewal Task'
                    : 'Edit Renewal Task',
              ),
              content: SizedBox(
                width: 620,
                height: 620,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: holderController,
                        decoration: const InputDecoration(
                          labelText: 'Certificate Holder',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: thumbprintController,
                        enabled: existingTask == null,
                        decoration: const InputDecoration(
                          labelText: 'Certificate Thumbprint',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.fingerprint),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: chooseExpiryDate,
                              icon: const Icon(Icons.event),
                              label: Text('Expiry: ${formatDate(expiryDate)}'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: chooseDueDate,
                              icon: const Icon(Icons.event_available),
                              label: Text('Due: ${formatDate(dueDate)}'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedTaskStatus,
                        decoration: const InputDecoration(
                          labelText: 'Renewal Status',
                          border: OutlineInputBorder(),
                        ),
                        items: RenewalRepository.workflowStatuses
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            selectedTaskStatus = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedPriority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(),
                        ),
                        items: RenewalRepository.priorities
                            .map(
                              (priority) => DropdownMenuItem(
                                value: priority,
                                child: Text(priority),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            selectedPriority = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: assignedController,
                        decoration: const InputDecoration(
                          labelText: 'Assigned Employee or Team',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: vendorController,
                        decoration: const InputDecoration(
                          labelText: 'Vendor or Certificate Authority',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: costController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Estimated Cost',
                          border: OutlineInputBorder(),
                          prefixText: '\$ ',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesController,
                        minLines: 3,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Renewal Notes',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    if (holderController.text.trim().isEmpty ||
                        thumbprintController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Certificate holder and thumbprint are required.',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext, true);
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save Task'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;

    final daysRemaining = RenewalRepository.calculateDaysRemaining(expiryDate);

    final category = RenewalRepository.classifyExpiry(daysRemaining);

    final now = DateTime.now().toIso8601String();

    final completedAt = selectedTaskStatus == 'Closed'
        ? existingTask?.completedAt ?? now
        : null;

    final task = RenewalTaskModel(
      id: existingTask?.id,
      certificateThumbprint: thumbprintController.text.trim(),
      certificateHolder: holderController.text.trim(),
      expiryDate: expiryDate.toIso8601String(),
      daysRemaining: daysRemaining,
      expiryCategory: category,
      status: selectedTaskStatus,
      priority: selectedPriority,
      assignedTo: assignedController.text.trim(),
      vendor: vendorController.text.trim(),
      estimatedCost: double.tryParse(costController.text.trim()) ?? 0,
      dueDate: dueDate.toIso8601String(),
      notes: notesController.text.trim(),
      createdAt: existingTask?.createdAt ?? now,
      updatedAt: now,
      completedAt: completedAt,
    );

    try {
      if (existingTask == null) {
        await repository.createTask(task);
        message = 'Renewal task created successfully.';
      } else {
        await repository.updateTask(task);
        message = 'Renewal task updated successfully.';
      }

      await loadData();
    } catch (error) {
      setState(() {
        message = 'Unable to save renewal task: $error';
      });
    }
  }

  Future<void> confirmDeleteTask(RenewalTaskModel task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Renewal Task'),
          content: Text(
            'Delete the renewal task for '
            '"${task.certificateHolder}"?\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || task.id == null) return;

    await repository.deleteTask(task.id!);

    setState(() {
      message = 'Renewal task deleted.';
    });

    await loadData();
  }

  Future<void> quickUpdateStatus(RenewalTaskModel task, String status) async {
    if (task.id == null) return;

    await repository.updateTaskStatus(taskId: task.id!, status: status);

    await loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Renewal Centre'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loading ? null : loadData,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: loading ? null : synchronizeCertificates,
              icon: const Icon(Icons.sync),
              label: const Text('Synchronize Certificates'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: loading ? null : () => openTaskDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Renewal Task'),
      ),
      body: Column(
        children: [
          _buildSummarySection(),
          _buildToolbar(),
          if (message.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(message),
            ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : tasks.isEmpty
                ? _buildEmptyState()
                : _buildTaskTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _summaryCard(
            title: 'Total Tasks',
            value: summary['total'] ?? 0,
            icon: Icons.assignment_outlined,
          ),
          _summaryCard(
            title: 'Expired',
            value: summary['expired'] ?? 0,
            icon: Icons.error_outline,
          ),
          _summaryCard(
            title: 'Critical',
            value: summary['critical'] ?? 0,
            icon: Icons.warning_amber,
          ),
          _summaryCard(
            title: 'Warning',
            value: summary['warning'] ?? 0,
            icon: Icons.schedule,
          ),
          _summaryCard(
            title: 'Open Tasks',
            value: summary['open'] ?? 0,
            icon: Icons.pending_actions,
          ),
          _summaryCard(
            title: 'Renewed This Month',
            value: summary['renewedThisMonth'] ?? 0,
            icon: Icons.verified_outlined,
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required int value,
    required IconData icon,
  }) {
    return SizedBox(
      width: 190,
      height: 105,
      child: Card(
        margin: const EdgeInsets.only(right: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(child: Icon(icon)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value.toString(),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 330,
            child: TextField(
              controller: searchController,
              onSubmitted: (_) => loadData(),
              decoration: InputDecoration(
                labelText: 'Search renewal tasks',
                hintText: 'Holder, thumbprint, owner or vendor',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Search',
                  onPressed: loadData,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 210,
            child: DropdownButtonFormField<String>(
              initialValue: selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Workflow Status',
                border: OutlineInputBorder(),
              ),
              items: ['All', ...RenewalRepository.workflowStatuses]
                  .map(
                    (status) =>
                        DropdownMenuItem(value: status, child: Text(status)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                selectedStatus = value;
                loadData();
              },
            ),
          ),
          SizedBox(
            width: 190,
            child: DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Expiry Category',
                border: OutlineInputBorder(),
              ),
              items: categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                selectedCategory = value;
                loadData();
              },
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              searchController.clear();
              selectedStatus = 'All';
              selectedCategory = 'All';
              loadData();
            },
            icon: const Icon(Icons.filter_alt_off),
            label: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTable() {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowHeight: 56,
              dataRowMinHeight: 64,
              dataRowMaxHeight: 82,
              columns: const [
                DataColumn(label: Text('Certificate')),
                DataColumn(label: Text('Expiry')),
                DataColumn(label: Text('Days')),
                DataColumn(label: Text('Category')),
                DataColumn(label: Text('Priority')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Assigned To')),
                DataColumn(label: Text('Vendor')),
                DataColumn(label: Text('Due Date')),
                DataColumn(label: Text('Cost')),
                DataColumn(label: Text('Actions')),
              ],
              rows: tasks.map(_buildTaskRow).toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildTaskRow(RenewalTaskModel task) {
    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 250,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.certificateHolder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Tooltip(
                  message: task.certificateThumbprint,
                  child: Text(
                    shortenThumbprint(task.certificateThumbprint),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(Text(formatStoredDate(task.expiryDate))),
        DataCell(Text(task.daysRemaining.toString())),
        DataCell(_labelChip(task.expiryCategory)),
        DataCell(_labelChip(task.priority)),
        DataCell(
          SizedBox(
            width: 180,
            child: DropdownButton<String>(
              value: RenewalRepository.workflowStatuses.contains(task.status)
                  ? task.status
                  : 'New',
              isExpanded: true,
              items: RenewalRepository.workflowStatuses
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(status, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  quickUpdateStatus(task, value);
                }
              },
            ),
          ),
        ),
        DataCell(
          Text(task.assignedTo.isEmpty ? 'Unassigned' : task.assignedTo),
        ),
        DataCell(Text(task.vendor.isEmpty ? 'Not selected' : task.vendor)),
        DataCell(Text(formatStoredDate(task.dueDate))),
        DataCell(
          Text(
            task.estimatedCost == 0
                ? '-'
                : '\$${task.estimatedCost.toStringAsFixed(2)}',
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Edit renewal task',
                onPressed: () => openTaskDialog(existingTask: task),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Delete renewal task',
                onPressed: () => confirmDeleteTask(task),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _labelChip(String label) {
    return Chip(label: Text(label), visualDensity: VisualDensity.compact);
  }

  Widget _buildEmptyState() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.autorenew, size: 60),
                const SizedBox(height: 16),
                const Text(
                  'No renewal tasks found',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Synchronize the certificate inventory to '
                  'automatically create tasks for certificates '
                  'expiring within 90 days, or create a task manually.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: synchronizeCertificates,
                      icon: const Icon(Icons.sync),
                      label: const Text('Synchronize Certificates'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => openTaskDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Task'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  static String formatStoredDate(String value) {
    if (value.trim().isEmpty) return '-';

    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    return formatDate(date);
  }

  static String shortenThumbprint(String value) {
    if (value.length <= 24) return value;

    return '${value.substring(0, 12)}...'
        '${value.substring(value.length - 8)}';
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
