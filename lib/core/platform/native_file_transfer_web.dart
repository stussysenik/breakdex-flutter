import 'package:firebase_storage/firebase_storage.dart';

Never nativePutFileTask(final Reference ref, final String localPath) =>
    throw UnsupportedError(
      'Firebase local-file upload is unavailable on web (native-only sync).',
    );

Never nativeWriteToFileTask(final Reference ref, final String localPath) =>
    throw UnsupportedError(
      'Firebase local-file download is unavailable on web (native-only sync).',
    );
