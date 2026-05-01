import 'package:intl/intl.dart';

import '../services/provenance_journal_service.dart';

class ProvenanceReport {
  const ProvenanceReport({
    required this.generatedAt,
    required this.totalEvents,
    required this.failureCount,
    required this.crashCount,
    required this.retrievalFailureCount,
    required this.databaseRecoveryCount,
    required this.recentCriticalEvents,
  });

  final DateTime generatedAt;
  final int totalEvents;
  final int failureCount;
  final int crashCount;
  final int retrievalFailureCount;
  final int databaseRecoveryCount;
  final List<ProvenanceEvent> recentCriticalEvents;

  bool get hasCriticalSignal => failureCount > 0 || crashCount > 0;

  String get headline {
    if (crashCount > 0) {
      return '$crashCount crash ${crashCount == 1 ? 'signal' : 'signals'} recorded recently';
    }
    if (failureCount > 0) {
      return '$failureCount recent ${failureCount == 1 ? 'failure' : 'failures'} recorded';
    }
    return 'No recent crash or failure signals';
  }

  String describeEvent(ProvenanceEvent event) {
    final timestamp = DateFormat(
      'MMM d, HH:mm',
    ).format(event.recordedAt.toLocal());
    final status = event.status == null || event.status!.isEmpty
        ? event.eventType
        : '${event.eventType} · ${event.status}';
    final entity = event.contentHash ?? event.entityId ?? event.scope;
    return '$timestamp · $status · $entity';
  }
}
