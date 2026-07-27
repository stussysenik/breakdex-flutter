import 'package:breakdex/core/models/provenance_report.dart';
import 'package:breakdex/core/services/provenance_journal_service.dart';

class ProvenanceReportService {
  const ProvenanceReportService(this._journal);

  final ProvenanceJournalService _journal;

  Future<ProvenanceReport> loadReport({final int limit = 200}) async {
    final events = await _journal.readRecent(limit: limit);
    final criticalEvents = events
        .where(
          (final event) =>
              event.scope == 'crash' ||
              event.status == 'failed' ||
              event.eventType.contains('failed'),
        )
        .toList(growable: false);

    return ProvenanceReport(
      generatedAt: DateTime.now(),
      totalEvents: events.length,
      failureCount: events
          .where(
            (final event) =>
                event.status == 'failed' || event.eventType.contains('failed'),
          )
          .length,
      crashCount: events.where((final event) => event.scope == 'crash').length,
      retrievalFailureCount: events
          .where(
            (final event) =>
                event.scope == 'video_retrieval' &&
                (event.status == 'failed' ||
                    event.eventType.contains('failed')),
          )
          .length,
      databaseRecoveryCount: events
          .where((final event) => event.scope == 'database_recovery')
          .length,
      recentCriticalEvents: criticalEvents.reversed
          .take(3)
          .toList()
          .reversed
          .toList(growable: false),
    );
  }
}
