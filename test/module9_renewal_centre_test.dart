import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../lib/models/renewal_task_model.dart';
import '../lib/repositories/renewal_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final temporaryDirectory = Directory.systemTemp.createTempSync(
    'dsc_module9_test_',
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'getApplicationDocumentsDirectory':
            case 'getApplicationSupportDirectory':
            case 'getTemporaryDirectory':
              return temporaryDirectory.path;
            default:
              return temporaryDirectory.path;
          }
        },
      );

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final repository = RenewalRepository();

  group('Module 9 Renewal Centre smoke test', () {
    late String uniqueThumbprint;
    int? createdTaskId;

    setUpAll(() async {
      await repository.ensureRenewalTable();

      uniqueThumbprint =
          'MODULE9_TEST_${DateTime.now().microsecondsSinceEpoch}';
    });

    tearDownAll(() async {
      if (createdTaskId != null) {
        try {
          await repository.deleteTask(createdTaskId!);
        } catch (_) {
          // Cleanup must not hide the functional test result.
        }
      }

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            null,
          );

      await Future<void>.delayed(const Duration(milliseconds: 300));

      if (temporaryDirectory.existsSync()) {
        try {
          temporaryDirectory.deleteSync(recursive: true);
        } catch (_) {
          // Windows may keep the SQLite file locked briefly.
          // This does not indicate a Module 9 functional failure.
        }
      }
    });

    test('1. Renewal table can be initialized', () async {
      await repository.ensureRenewalTable();

      final tasks = await repository.getTasks();

      expect(tasks, isA<List<RenewalTaskModel>>());

      print('PASS: Renewal table initialized.');
    });

    test('2. Create a renewal task', () async {
      final now = DateTime.now();
      final expiryDate = now.add(const Duration(days: 30));
      final dueDate = now.add(const Duration(days: 14));

      final daysRemaining = RenewalRepository.calculateDaysRemaining(
        expiryDate,
      );

      final task = RenewalTaskModel(
        certificateThumbprint: uniqueThumbprint,
        certificateHolder: 'John Smith',
        expiryDate: expiryDate.toIso8601String(),
        daysRemaining: daysRemaining,
        expiryCategory: RenewalRepository.classifyExpiry(daysRemaining),
        status: 'New',
        priority: 'High',
        assignedTo: 'IT Security',
        vendor: 'DigiCert',
        estimatedCost: 250,
        dueDate: dueDate.toIso8601String(),
        notes: 'Automated Module 9 renewal test',
        createdAt: now.toIso8601String(),
        updatedAt: now.toIso8601String(),
      );

      createdTaskId = await repository.createTask(task);

      expect(createdTaskId, greaterThan(0));

      print('PASS: Renewal task created with ID $createdTaskId.');
    });

    test('3. Read task by certificate thumbprint', () async {
      final task = await repository.getTaskByThumbprint(uniqueThumbprint);

      expect(task, isNotNull);
      expect(task!.certificateHolder, 'John Smith');
      expect(task.status, 'New');
      expect(task.priority, 'High');
      expect(task.assignedTo, 'IT Security');
      expect(task.vendor, 'DigiCert');
      expect(task.estimatedCost, 250);

      createdTaskId = task.id;

      print('PASS: Renewal task retrieved by thumbprint.');
    });

    test('4. Search by certificate holder', () async {
      final results = await repository.getTasks(search: 'John Smith');

      final matching = results.where(
        (task) => task.certificateThumbprint == uniqueThumbprint,
      );

      expect(matching, isNotEmpty);

      print('PASS: Search by certificate holder works.');
    });

    test('5. Search by partial thumbprint', () async {
      final searchTerm = uniqueThumbprint.substring(0, 12);

      final results = await repository.getTasks(search: searchTerm);

      final matching = results.where(
        (task) => task.certificateThumbprint == uniqueThumbprint,
      );

      expect(matching, isNotEmpty);

      print('PASS: Search by thumbprint works.');
    });

    test('6. Status filter finds New task', () async {
      final results = await repository.getTasks(status: 'New');

      final matching = results.where(
        (task) => task.certificateThumbprint == uniqueThumbprint,
      );

      expect(matching, isNotEmpty);

      print('PASS: New status filter works.');
    });

    test('7. Edit renewal task', () async {
      final existing = await repository.getTaskByThumbprint(uniqueThumbprint);

      expect(existing, isNotNull);
      expect(existing!.id, isNotNull);

      createdTaskId = existing.id;

      final updated = existing.copyWith(
        status: 'Assigned',
        priority: 'Critical',
        assignedTo: 'Certificate Operations Team',
        vendor: 'DigiCert Australia',
        estimatedCost: 275,
        notes: 'Task updated by automated Module 9 test',
        updatedAt: DateTime.now().toIso8601String(),
      );

      await repository.updateTask(updated);

      final result = await repository.getTaskByThumbprint(uniqueThumbprint);

      expect(result, isNotNull);
      expect(result!.status, 'Assigned');
      expect(result.priority, 'Critical');
      expect(result.assignedTo, 'Certificate Operations Team');
      expect(result.vendor, 'DigiCert Australia');
      expect(result.estimatedCost, 275);

      print('PASS: Renewal task editing works.');
    });

    test('8. Assigned status filter works', () async {
      final results = await repository.getTasks(status: 'Assigned');

      final matching = results.where(
        (task) => task.certificateThumbprint == uniqueThumbprint,
      );

      expect(matching, isNotEmpty);

      print('PASS: Assigned status filter works.');
    });

    test('9. Change task status to Closed', () async {
      final existing = await repository.getTaskByThumbprint(uniqueThumbprint);

      expect(existing, isNotNull);
      expect(existing!.id, isNotNull);

      createdTaskId = existing.id;

      await repository.updateTaskStatus(taskId: existing.id!, status: 'Closed');

      final closedTask = await repository.getTaskByThumbprint(uniqueThumbprint);

      expect(closedTask, isNotNull);
      expect(closedTask!.status, 'Closed');
      expect(closedTask.completedAt, isNotNull);
      expect(closedTask.completedAt, isNotEmpty);

      print('PASS: Task status changed to Closed.');
    });

    test('10. Renewed This Month summary increases', () async {
      final summary = await repository.getSummary();

      expect(summary.containsKey('renewedThisMonth'), isTrue);
      expect(summary['renewedThisMonth'] ?? 0, greaterThanOrEqualTo(1));

      print(
        'PASS: Renewed This Month = '
        '${summary['renewedThisMonth']}.',
      );
    });

    test('11. Closed status filter works', () async {
      final results = await repository.getTasks(status: 'Closed');

      final matching = results.where(
        (task) => task.certificateThumbprint == uniqueThumbprint,
      );

      expect(matching, isNotEmpty);

      print('PASS: Closed status filter works.');
    });

    test('12. Certificate synchronization executes', () async {
      final synchronized = await repository.synchronizeCertificateRenewals();

      expect(synchronized, greaterThanOrEqualTo(0));

      print(
        'PASS: Certificate synchronization executed. '
        'Records processed: $synchronized.',
      );
    });

    test('13. Delete renewal task', () async {
      final existing = await repository.getTaskByThumbprint(uniqueThumbprint);

      expect(existing, isNotNull);
      expect(existing!.id, isNotNull);

      await repository.deleteTask(existing.id!);
      createdTaskId = null;

      final deleted = await repository.getTaskByThumbprint(uniqueThumbprint);

      expect(deleted, isNull);

      print('PASS: Renewal task deleted.');
    });
  });
}
