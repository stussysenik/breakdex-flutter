/// Native side of the [io.dart] platform seam: the real `dart:io`.
///
/// Re-exporting verbatim guarantees the native build is byte-identical to
/// importing `dart:io` directly. The `_native.dart` suffix is intentional —
/// it is the one filename the Phase 1.0.1 done-criterion grep
/// (`grep -rl "import 'dart:io'" lib/ | grep -v _native.dart`) excludes.
library;

export 'dart:io';
