import 'package:drift/drift.dart';

import 'package:breakdex/core/database/database.dart';
import 'package:breakdex/core/database/tables/combo_plans.dart';
import 'package:breakdex/core/database/tables/combos.dart';
import 'package:breakdex/core/database/tables/combo_note_entries.dart';

part 'combo_plans_dao.g.dart';

/// A plan joined with its combo for queue/calendar rendering.
class PlanWithCombo {
  final ComboPlan plan;
  final Combo combo;

  PlanWithCombo({required this.plan, required this.combo});
}

@DriftAccessor(tables: [ComboPlans, Combos, ComboNoteEntries])
class ComboPlansDao extends DatabaseAccessor<AppDatabase>
    with _$ComboPlansDaoMixin {
  ComboPlansDao(super.db);

  /// Truncates to date-only semantics (local midnight).
  static DateTime dateOnly(final DateTime d) =>
      DateTime(d.year, d.month, d.day);

  Future<void> insertPlan(final ComboPlansCompanion entry) =>
      into(comboPlans).insert(entry);

  Future<ComboPlan> getById(final String id) =>
      (select(comboPlans)..where((final t) => t.id.equals(id))).getSingle();

  Future<List<ComboPlan>> getAll() => select(comboPlans).get();

  Future<void> deletePlan(final String id) =>
      (delete(comboPlans)..where((final t) => t.id.equals(id))).go();

  Future<void> deletePlansForCombo(final String comboId) =>
      (delete(comboPlans)..where((final t) => t.comboId.equals(comboId))).go();

  Future<void> updatePosition(final String id, final int position) =>
      (update(comboPlans)..where((final t) => t.id.equals(id)))
          .write(ComboPlansCompanion(position: Value(position)));

  /// Next free position at the end of [date]'s queue (append semantics).
  Future<int> nextPositionForDate(final DateTime date) async {
    final dayStart = dateOnly(date);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final maxPos = comboPlans.position.max();
    final query = selectOnly(comboPlans)
      ..addColumns([maxPos])
      ..where(comboPlans.planDate.isBiggerOrEqualValue(dayStart) &
          comboPlans.planDate.isSmallerThanValue(dayEnd));
    final row = await query.getSingle();
    final current = row.read(maxPos);
    return current == null ? 0 : current + 1;
  }

  Future<void> updatePlanDate(final String id, final DateTime planDate) =>
      (update(comboPlans)..where((final t) => t.id.equals(id))).write(
        ComboPlansCompanion(planDate: Value(dateOnly(planDate))),
      );

  /// All incomplete plans, ordered as the dancer's queue:
  /// earliest day first, then position within the day.
  Stream<List<PlanWithCombo>> watchPlansQueue() {
    final query = select(comboPlans).join([
      innerJoin(combos, combos.id.equalsExp(comboPlans.comboId)),
    ])
      ..where(comboPlans.completedAt.isNull())
      ..orderBy([
        OrderingTerm.asc(comboPlans.planDate),
        OrderingTerm.asc(comboPlans.position),
      ]);

    return query.watch().map((final rows) => rows
        .map((final row) => PlanWithCombo(
              plan: row.readTable(comboPlans),
              combo: row.readTable(combos),
            ))
        .toList());
  }

  /// Plans (complete or not) for a single day.
  Stream<List<PlanWithCombo>> watchPlansForDate(final DateTime date) {
    final dayStart = dateOnly(date);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final query = select(comboPlans).join([
      innerJoin(combos, combos.id.equalsExp(comboPlans.comboId)),
    ])
      ..where(comboPlans.planDate.isBiggerOrEqualValue(dayStart) &
          comboPlans.planDate.isSmallerThanValue(dayEnd))
      ..orderBy([OrderingTerm.asc(comboPlans.position)]);

    return query.watch().map((final rows) => rows
        .map((final row) => PlanWithCombo(
              plan: row.readTable(comboPlans),
              combo: row.readTable(combos),
            ))
        .toList());
  }

  /// All plans, for the calendar's future dashed rings / plan dots.
  Stream<List<ComboPlan>> watchAllPlans() => select(comboPlans).watch();

  /// Evidence-based completion: stamps `completedAt` on any incomplete plan
  /// whose combo has a journal jot created on the plan's day. A rollup
  /// query, not a trigger — safe to call after any jot write.
  ///
  /// `plan_date` is persisted as the unix epoch of *local midnight* at the time
  /// the plan was created. Re-applying `'localtime'` to that epoch shifts it by
  /// the device's *current* offset, so a DST/timezone change between planning
  /// and jotting could push the plan's day ±1h across a midnight boundary and
  /// silently miss the match. Anchoring at local noon (`'+12 hours'`) before
  /// taking `date(...)` makes the comparison immune to any offset change under
  /// 12 hours. Read-path only — no stored row is rewritten.
  Future<int> stampCompletionsFromEvidence() {
    return customUpdate(
      '''
      UPDATE combo_plans
      SET completed_at = (
        SELECT MIN(e.created_at) FROM combo_note_entries e
        WHERE e.combo_id = combo_plans.combo_id
          AND e.kind = 'jot'
          AND date(e.created_at, 'unixepoch', 'localtime')
            = date(combo_plans.plan_date, 'unixepoch', 'localtime', '+12 hours')
      )
      WHERE completed_at IS NULL
        AND EXISTS (
          SELECT 1 FROM combo_note_entries e
          WHERE e.combo_id = combo_plans.combo_id
            AND e.kind = 'jot'
            AND date(e.created_at, 'unixepoch', 'localtime')
              = date(combo_plans.plan_date, 'unixepoch', 'localtime', '+12 hours')
        )
      ''',
      updates: {comboPlans},
      updateKind: UpdateKind.update,
    );
  }
}
