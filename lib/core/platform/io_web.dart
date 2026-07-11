/// Web side of the [io.dart] platform seam.
///
/// The browser has no `dart:io` filesystem. These stubs let the whole app
/// *compile* for web while degrading honestly at runtime:
///
/// * Pure-path members ([FileSystemEntity.path], `.uri`, `.parent`,
///   `.absolute`) work — they touch no filesystem, so widgets can still build
///   paths.
/// * Existence queries ([File.existsSync], [File.exists]) answer `false` — the
///   truthful "there is no local file on web" state, which lets UI render its
///   empty/unavailable affordance (and lets previews render) instead of
///   crashing.
/// * Every real I/O operation (read, write, create, delete, list, stat, …)
///   throws [UnsupportedError] — a visible failure, never a silent no-op that
///   pretends a write happened.
///
/// The UI-level "degrade visibly" contract (hide/label unavailable
/// affordances) lives at the Phase 1.3 platform seams, above this layer.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

Never _unsupported(String op) =>
    throw UnsupportedError('dart:io $op is unavailable on web');

/// Mirrors `dart:io`'s `FileSystemEntityType`.
class FileSystemEntityType {
  const FileSystemEntityType._(this._name);
  final String _name;
  static const file = FileSystemEntityType._('file');
  static const directory = FileSystemEntityType._('directory');
  static const link = FileSystemEntityType._('link');
  static const notFound = FileSystemEntityType._('notFound');
  static const pipe = FileSystemEntityType._('pipe');
  static const unixDomainSock = FileSystemEntityType._('unixDomainSock');
  @override
  String toString() => 'FileSystemEntityType: $_name';
}

/// Mirrors `dart:io`'s `FileMode` (an enum here — the stub only needs distinct
/// values to pass through as arguments).
enum FileMode { read, write, append, writeOnly, writeOnlyAppend }

/// Mirrors `dart:io`'s `FileStat`.
abstract class FileStat {
  DateTime get changed;
  DateTime get modified;
  DateTime get accessed;
  FileSystemEntityType get type;
  int get mode;
  int get size;
}

/// Marker interface, mirrors `dart:io`'s `IOException`.
abstract class IOException implements Exception {}

/// Mirrors `dart:io`'s `OSError`.
class OSError {
  const OSError([this.message = '', this.errorCode = -1]);
  final String message;
  final int errorCode;
  @override
  String toString() => 'OSError: $message (errno $errorCode)';
}

/// Mirrors `dart:io`'s `FileSystemException`.
class FileSystemException implements IOException {
  const FileSystemException([this.message = '', this.path = '', this.osError]);
  final String message;
  final String? path;
  final OSError? osError;
  @override
  String toString() => 'FileSystemException: $message, path = $path';
}

/// Mirrors `dart:io`'s `FileSystemEvent` (only the type constants + fields the
/// app touches when wiring `.watch()`).
abstract class FileSystemEvent {
  static const int create = 1 << 0;
  static const int modify = 1 << 1;
  static const int delete = 1 << 2;
  static const int move = 1 << 3;
  static const int all = create | modify | delete | move;
  int get type;
  String get path;
}

/// Sink returned by [File.openWrite]; every write throws.
abstract class IOSink implements StreamSink<List<int>>, StringSink {
  Encoding get encoding;
  set encoding(Encoding value);
  Future<dynamic> flush();
}

/// Handle returned by [File.open]; every operation throws.
abstract class RandomAccessFile {
  String get path;
  int readIntoSync(List<int> buffer, [int start = 0, int? end]);
  void closeSync();
}

/// Base of [File] and [Directory]; shared pure-path + throwing I/O surface.
abstract class FileSystemEntity {
  FileSystemEntity(this.path);

  final String path;

  Uri get uri => Uri.file(path, windows: false);

  bool get isAbsolute => path.startsWith('/');

  Directory get parent {
    final i = path.lastIndexOf('/');
    return Directory(i <= 0 ? (i == 0 ? '/' : '.') : path.substring(0, i));
  }

  Future<bool> exists() async => false;

  Future<FileSystemEntity> delete({bool recursive = false}) =>
      _unsupported('FileSystemEntity.delete');
  void deleteSync({bool recursive = false}) =>
      _unsupported('FileSystemEntity.deleteSync');

  Future<FileSystemEntity> rename(String newPath) =>
      _unsupported('FileSystemEntity.rename');
  FileSystemEntity renameSync(String newPath) =>
      _unsupported('FileSystemEntity.renameSync');

  Future<FileStat> stat() => _unsupported('FileSystemEntity.stat');
  FileStat statSync() => _unsupported('FileSystemEntity.statSync');

  Stream<FileSystemEvent> watch({
    int events = FileSystemEvent.all,
    bool recursive = false,
  }) =>
      _unsupported('FileSystemEntity.watch');

  Future<String> resolveSymbolicLinks() =>
      _unsupported('FileSystemEntity.resolveSymbolicLinks');
  String resolveSymbolicLinksSync() =>
      _unsupported('FileSystemEntity.resolveSymbolicLinksSync');

  static Future<bool> isDirectory(String path) async => false;
  static bool isDirectorySync(String path) => false;
  static Future<bool> isFile(String path) async => false;
  static bool isFileSync(String path) => false;
  static Future<FileSystemEntityType> type(String path,
          {bool followLinks = true}) async =>
      FileSystemEntityType.notFound;

  @override
  String toString() => "$runtimeType: '$path'";
}

/// Web stub of `dart:io`'s `File`.
class File extends FileSystemEntity {
  File(super.path);
  File.fromUri(Uri uri) : super(uri.toFilePath(windows: false));

  File get absolute => File(path);

  bool existsSync() => false;

  Future<File> create({bool recursive = false, bool exclusive = false}) =>
      _unsupported('File.create');
  void createSync({bool recursive = false, bool exclusive = false}) =>
      _unsupported('File.createSync');

  Future<int> length() => _unsupported('File.length');
  int lengthSync() => _unsupported('File.lengthSync');

  Future<DateTime> lastModified() => _unsupported('File.lastModified');
  DateTime lastModifiedSync() => _unsupported('File.lastModifiedSync');

  Future<File> copy(String newPath) => _unsupported('File.copy');
  File copySync(String newPath) => _unsupported('File.copySync');

  @override
  Future<File> rename(String newPath) => _unsupported('File.rename');
  @override
  File renameSync(String newPath) => _unsupported('File.renameSync');

  Future<Uint8List> readAsBytes() => _unsupported('File.readAsBytes');
  Uint8List readAsBytesSync() => _unsupported('File.readAsBytesSync');

  Future<String> readAsString({Encoding encoding = utf8}) =>
      _unsupported('File.readAsString');
  String readAsStringSync({Encoding encoding = utf8}) =>
      _unsupported('File.readAsStringSync');

  Future<List<String>> readAsLines({Encoding encoding = utf8}) =>
      _unsupported('File.readAsLines');
  List<String> readAsLinesSync({Encoding encoding = utf8}) =>
      _unsupported('File.readAsLinesSync');

  Future<File> writeAsBytes(List<int> bytes,
          {FileMode mode = FileMode.write, bool flush = false}) =>
      _unsupported('File.writeAsBytes');
  void writeAsBytesSync(List<int> bytes,
          {FileMode mode = FileMode.write, bool flush = false}) =>
      _unsupported('File.writeAsBytesSync');

  Future<File> writeAsString(String contents,
          {FileMode mode = FileMode.write,
          Encoding encoding = utf8,
          bool flush = false}) =>
      _unsupported('File.writeAsString');
  void writeAsStringSync(String contents,
          {FileMode mode = FileMode.write,
          Encoding encoding = utf8,
          bool flush = false}) =>
      _unsupported('File.writeAsStringSync');

  Stream<List<int>> openRead([int? start, int? end]) =>
      _unsupported('File.openRead');
  IOSink openWrite({FileMode mode = FileMode.write, Encoding encoding = utf8}) =>
      _unsupported('File.openWrite');
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) =>
      _unsupported('File.open');
  RandomAccessFile openSync({FileMode mode = FileMode.read}) =>
      _unsupported('File.openSync');
}

/// Web stub of `dart:io`'s `Directory`.
class Directory extends FileSystemEntity {
  Directory(super.path);
  Directory.fromUri(Uri uri) : super(uri.toFilePath(windows: false));

  static Directory get systemTemp => Directory('/tmp');
  static Directory get current => Directory('.');
  static set current(dynamic path) => _unsupported('Directory.current=');

  Directory get absolute => Directory(path);

  bool existsSync() => false;

  Future<Directory> create({bool recursive = false}) =>
      _unsupported('Directory.create');
  void createSync({bool recursive = false}) =>
      _unsupported('Directory.createSync');

  Future<Directory> createTemp([String? prefix]) =>
      _unsupported('Directory.createTemp');
  Directory createTempSync([String? prefix]) =>
      _unsupported('Directory.createTempSync');

  @override
  Future<Directory> rename(String newPath) => _unsupported('Directory.rename');
  @override
  Directory renameSync(String newPath) => _unsupported('Directory.renameSync');

  Stream<FileSystemEntity> list(
          {bool recursive = false, bool followLinks = true}) =>
      _unsupported('Directory.list');
  List<FileSystemEntity> listSync(
          {bool recursive = false, bool followLinks = true}) =>
      _unsupported('Directory.listSync');
}

/// Web stub of `dart:io`'s `Platform`. Answers with web-honest values instead
/// of throwing, so platform-branching code takes the non-native path cleanly.
abstract final class Platform {
  static const bool isIOS = false;
  static const bool isAndroid = false;
  static const bool isMacOS = false;
  static const bool isWindows = false;
  static const bool isLinux = false;
  static const bool isFuchsia = false;
  static const String operatingSystem = 'web';
  static const String operatingSystemVersion = '';
  static const String pathSeparator = '/';
  static const int numberOfProcessors = 1;
  static const String localHostname = 'localhost';
  static const Map<String, String> environment = <String, String>{};
  static String get executable => '';
  static String get resolvedExecutable => '';
  static Uri get script => Uri.base;
  static String get localeName => 'en_US';
  static String get version => '';
}

/// Mirrors `dart:io`'s `ProcessResult`.
class ProcessResult {
  const ProcessResult(this.pid, this.exitCode, this.stdout, this.stderr);
  final int pid;
  final int exitCode;
  final dynamic stdout;
  final dynamic stderr;
}

/// Mirrors `dart:io`'s `ProcessException`.
class ProcessException implements IOException {
  const ProcessException(this.executable, this.arguments,
      [this.message = '', this.errorCode = 0]);
  final String executable;
  final List<String> arguments;
  final String message;
  final int errorCode;
  @override
  String toString() => 'ProcessException: $message';
}

/// Web stub of `dart:io`'s `Process`; the browser cannot spawn processes.
abstract final class Process {
  static Future<ProcessResult> run(String executable, List<String> arguments,
          {String? workingDirectory,
          Map<String, String>? environment,
          bool runInShell = false}) =>
      _unsupported('Process.run');
  static ProcessResult runSync(String executable, List<String> arguments,
          {String? workingDirectory,
          Map<String, String>? environment,
          bool runInShell = false}) =>
      _unsupported('Process.runSync');
}
