import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Firebase is the legacy backend — superseded by Appwrite (CLAUDE.md → Canonical
/// stack, 2026-07-05). No file under lib/ SHALL import package:firebase_* or
/// package:cloud_firestore, and pubspec.yaml SHALL declare none. The 26 Firebase
/// pods in ios/Podfile.lock (abseil, gRPC-C++, gRPC-Core, BoringSSL-GRPC,
/// leveldb-library, nanopb) dominate the 990s cold release build; this test is
/// the gate that proves they are gone.

void main() {
  group('firebase conformance — no Firebase imports or dependencies', () {
    test('no file under lib/ imports package:firebase_* or package:cloud_firestore', () {
      final banned = [
        RegExp(r'package:firebase_core'),
        RegExp(r'package:firebase_auth'),
        RegExp(r'package:firebase_storage'),
        RegExp(r'package:cloud_firestore'),
      ];

      final offending = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = entity.readAsStringSync();
        if (banned.any((re) => re.hasMatch(source))) {
          offending.add(entity.path);
        }
      }

      expect(offending, isEmpty,
          reason:
              '${offending.length} file(s) still import a banned Firebase package:\n'
              '${offending.join('\n')}\n'
              'These drag in 26 pods (abseil, gRPC-C++, gRPC-Core, BoringSSL-GRPC, '
              'leveldb-library, nanopb) that dominate the 990s cold release build. '
              'Migrate to Appwrite/CloudProvider before shipping.');
    });

    test('pubspec.yaml declares no firebase dependencies', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final banned = [
        RegExp(r'^\s*firebase_core:', multiLine: true),
        RegExp(r'^\s*cloud_firestore:', multiLine: true),
        RegExp(r'^\s*firebase_storage:', multiLine: true),
        RegExp(r'^\s*firebase_auth:', multiLine: true),
      ];

      final declared = <String>[];
      for (final re in banned) {
        final match = re.firstMatch(pubspec);
        if (match != null) {
          declared.add(match.group(0)!);
        }
      }

      expect(declared, isEmpty,
          reason:
              'pubspec.yaml still declares ${declared.length} Firebase dep(s):\n'
              '${declared.join('\n')}\n'
              'Remove all four (firebase_core, cloud_firestore, firebase_storage, '
              'firebase_auth) to drop the 26-pod C++ tree from ios/Podfile.lock.');
    });
  });
}
