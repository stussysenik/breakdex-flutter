// H.8 lint triage — discarded_futures: intentional fire-and-forget (UI/provider side effects); the rule still guards new sync/codec files.
// ignore_for_file: discarded_futures

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:breakdex/core/database/daos/combo_plans_dao.dart';
import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/design/spacing.dart';
import 'package:breakdex/core/design/typography.dart';
import 'package:breakdex/core/providers.dart';
import 'package:breakdex/shared/widgets/app_loader.dart';
import 'package:breakdex/features/combo_detail/widgets/status_tag.dart';

final allCombosProvider = StreamProvider<List<Combo>>((final ref) {
  return ref.watch(combosDaoProvider).watchAll();
});

/// Shared plan-a-combo flow: pick a combo from the sheet (skipped when
/// [comboId] is given), then a date (skipped when [presetDate] is given),
/// then persist the plan.
///
/// The sheet only *returns* the chosen combo id — all writes happen here,
/// on the caller's live `ref`, never on the popped sheet's disposed one.
Future<void> planComboFlow(
  final BuildContext context,
  final WidgetRef ref, {
  final String? comboId,
  final DateTime? presetDate,
}) async {
  String? pickedComboId = comboId;
  pickedComboId ??= await showModalBottomSheet<String>(
    context: context,
    builder: (_) => const _PlanPickerSheet(),
  );
  if (pickedComboId == null || !context.mounted) return;

  DateTime? picked = presetDate;
  if (picked == null) {
    final now = DateTime.now();
    picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );
  }
  if (picked == null || !context.mounted) return;

  final dao = ref.read(comboPlansDaoProvider);
  final position = await dao.nextPositionForDate(picked);
  await dao.insertPlan(
    ComboPlansCompanion.insert(
      id: const Uuid().v4(),
      comboId: pickedComboId,
      planDate: ComboPlansDao.dateOnly(picked),
      position: Value(position),
    ),
  );
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Planned for ${DateFormat('MMM d').format(picked)}')),
    );
  }
}

class _PlanPickerSheet extends ConsumerWidget {
  const _PlanPickerSheet();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final combosAsync = ref.watch(allCombosProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenEdge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plan a combo',
              style: AppTypography.titleSmall.copyWith(color: colorScheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.md),
            combosAsync.when(
              loading: () => const Center(child: AppLoader()),
              error: (final e, _) => Text('Error: $e'),
              data: (final combos) {
                if (combos.isEmpty) {
                  return Text(
                    'No combos yet — create one first.',
                    style: AppTypography.bodySmall.copyWith(color: colorScheme.secondary),
                  );
                }
                return Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: combos.length + 1,
                    itemBuilder: (final context, final index) {
                      if (index == 0) {
                        return ListTile(
                          leading: const Icon(Icons.add),
                          title: const Text('New combo…'),
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/create-combo');
                          },
                        );
                      }
                      final combo = combos[index - 1];
                      final style = statusStyle(combo.status);
                      return ListTile(
                        leading: Container(
                          width: 3,
                          height: 32,
                          decoration: BoxDecoration(
                            color: style.dashed
                                ? colorScheme.outline
                                : style.color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        title: Text(combo.name),
                        subtitle: Text(
                          combo.status.toUpperCase(),
                          style: AppTypography.labelSmall.copyWith(
                            color: colorScheme.secondary,
                          ),
                        ),
                        onTap: () => Navigator.pop(context, combo.id),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
