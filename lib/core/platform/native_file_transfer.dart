import 'package:firebase_storage/firebase_storage.dart';

import 'package:breakdex/core/platform/native_file_transfer_native.dart'
    if (dart.library.js_interop) 'native_file_transfer_web.dart';

/// Firebase Storage's `putFile`/`writeToFile` take a `dart:io.File` and only
/// work on native. The returned [UploadTask]/[DownloadTask] types exist on both
/// platforms, so callers keep their `snapshotEvents`/`await` logic; only the
/// local-file bridge is platform-split. On web these throw (legacy Firebase
/// video sync is native-only — web sync goes through Appwrite), a visible
/// failure rather than a silent skip.
UploadTask putFileTask(final Reference ref, final String localPath) =>
    nativePutFileTask(ref, localPath);

DownloadTask writeToFileTask(final Reference ref, final String localPath) =>
    nativeWriteToFileTask(ref, localPath);
