// H.8 lint triage — avoid_slow_async_io: async filesystem stat is intentional (avoids blocking the UI isolate); sync alternatives would block.
// ignore_for_file: avoid_slow_async_io

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'app_storage_paths.dart';

class ProvenanceEvent {
  const ProvenanceEvent({
    required this.recordedAt,
    required this.sessionId,
    required this.scope,
    required this.eventType,
    this.status,
    this.entityType,
    this.entityId,
    this.contentHash,
    this.moveId,
    this.connectionType,
    this.localPath,
    this.message,
  });

  final DateTime recordedAt;
  final String sessionId;
  final String scope;
  final String eventType;
  final String? status;
  final String? entityType;
  final String? entityId;
  final String? contentHash;
  final String? moveId;
  final String? connectionType;
  final String? localPath;
  final String? message;
}

class ProvenanceJournalService {
  ProvenanceJournalService({
    final Future<Directory> Function()? documentsDirectory,
    final DateTime Function()? now,
    final String Function()? sessionIdGenerator,
  }) : _documentsDirectory =
           documentsDirectory ?? AppStoragePaths.documentsDirectory,
       _now = now ?? DateTime.now,
       sessionId = (sessionIdGenerator ?? (() => const Uuid().v4()))();

  static const filename = 'breakdex_provenance.log';
  static const maxRetainedEvents = 2000;
  static const maxFileBytes = 1024 * 1024;

  final Future<Directory> Function() _documentsDirectory;
  final DateTime Function() _now;
  final String sessionId;

  Future<void> log({
    required final String scope,
    required final String eventType,
    final String? status,
    final String? entityType,
    final String? entityId,
    final String? contentHash,
    final String? moveId,
    final String? connectionType,
    final String? localPath,
    final String? message,
  }) async {
    final file = await _journalFile();
    final recordedAt = _now().toUtc().toIso8601String();
    final fields = <String>[
      recordedAt,
      sessionId,
      scope,
      eventType,
      _clean(status),
      _clean(entityType),
      _clean(entityId),
      _clean(contentHash),
      _clean(moveId),
      _clean(connectionType),
      _clean(localPath),
      _clean(message),
    ];
    await file.writeAsString('${fields.join('\t')}\n', mode: FileMode.append);
    await _pruneIfNeeded(file);
  }

  Future<List<ProvenanceEvent>> readRecent({final int limit = 100}) async {
    final file = await _journalFile();
    if (!await file.exists()) return const [];

    final lines = await file.readAsLines();
    final recentLines = lines.reversed
        .where((final line) => line.trim().isNotEmpty)
        .take(limit)
        .toList()
        .reversed;
    return recentLines
        .map(_parseLine)
        .whereType<ProvenanceEvent>()
        .toList(growable: false);
  }

  Future<File> journalFile() => _journalFile();

  Future<File> _journalFile() async {
    final directory = await _documentsDirectory();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return File(p.join(directory.path, filename));
  }

  Future<void> _pruneIfNeeded(final File file) async {
    if (!await file.exists()) return;
    final length = await file.length();
    if (length <= maxFileBytes) return;

    final lines = await file.readAsLines();
    final retained = lines.skip(
      lines.length > maxRetainedEvents ? lines.length - maxRetainedEvents : 0,
    );
    await file.writeAsString(
      retained.where((final line) => line.trim().isNotEmpty).join('\n') +
          (retained.isEmpty ? '' : '\n'),
      mode: FileMode.write,
    );
  }

  ProvenanceEvent? _parseLine(final String line) {
    final fields = line.split('\t');
    if (fields.length < 12) return null;
    final recordedAt = DateTime.tryParse(fields[0]);
    if (recordedAt == null) return null;
    return ProvenanceEvent(
      recordedAt: recordedAt,
      sessionId: fields[1],
      scope: fields[2],
      eventType: fields[3],
      status: _nullIfEmpty(fields[4]),
      entityType: _nullIfEmpty(fields[5]),
      entityId: _nullIfEmpty(fields[6]),
      contentHash: _nullIfEmpty(fields[7]),
      moveId: _nullIfEmpty(fields[8]),
      connectionType: _nullIfEmpty(fields[9]),
      localPath: _nullIfEmpty(fields[10]),
      message: _nullIfEmpty(fields[11]),
    );
  }

  String _clean(final String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return '';
    return trimmed.replaceAll(RegExp(r'[\r\n\t]+'), ' ');
  }

  String? _nullIfEmpty(final String value) => value.isEmpty ? null : value;
}
