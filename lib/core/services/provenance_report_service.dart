import '../models/provenance_report.dart';
import 'provenance_journal_service.dart';

class ProvenanceReportService {
  const ProvenanceReportService(this._journal);

  final ProvenanceJournalService _journal;

  Future<ProvenanceReport> loadReport({int limit = 200}) async {
    final events = await _journal.readRecent(limit: limit);
    final criticalEvents = events
        .where(
          (event) =>
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
            (event) =>
                event.status == 'failed' || event.eventType.contains('failed'),
          )
          .length,
      crashCount: events.where((event) => event.scope == 'crash').length,
      retrievalFailureCount: events
          .where(
            (event) =>
                event.scope == 'video_retrieval' &&
                (event.status == 'failed' ||
                    event.eventType.contains('failed')),
          )
          .length,
      databaseRecoveryCount: events
          .where((event) => event.scope == 'database_recovery')
          .length,
      recentCriticalEvents: criticalEvents.reversed
          .take(3)
          .toList()
          .reversed
          .toList(growable: false),
    );
  }
}
