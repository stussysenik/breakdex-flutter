import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

UploadTask nativePutFileTask(final Reference ref, final String localPath) =>
    ref.putFile(File(localPath));

DownloadTask nativeWriteToFileTask(final Reference ref, final String localPath) =>
    ref.writeToFile(File(localPath));
