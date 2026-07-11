import 'io.dart';

Future<Directory> nativeAppDocumentsDirectory() => throw UnsupportedError(
      'No application-documents directory on web (database lives in OPFS).',
    );
