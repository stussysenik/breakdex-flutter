import 'package:path_provider/path_provider.dart';

import 'package:breakdex/core/platform/io.dart';

Future<Directory> nativeAppDocumentsDirectory() =>
    getApplicationDocumentsDirectory();
