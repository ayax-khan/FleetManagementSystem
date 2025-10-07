// lib/migrations/migration_002_split_expense_type.dart
import 'package:fleet_management/core/logger.dart';
import 'package:fleet_management/models/allowance.dart';
import 'package:hive/hive.dart';

import '../../core/constants.dart';

Future<void> migration002SplitExpenseType() async {
  final box = Hive.box<Allowance>(Constants.allowanceBox);
  for (var key in box.keys) {
    Allowance? allowance = box.get(key);
    if (allowance != null && allowance.type == 'old_type') {
      // Assume old
      allowance.type = 'other'; // Map to new
      await box.put(key, allowance);
      Logger.debug('Updated expense type for allowance $key');
    }
  }
}
