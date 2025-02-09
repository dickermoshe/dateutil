import 'dart:io';

import 'package:dateutil/src/tz/android/android_tz.dart';

import 'package:jni/jni.dart';
import 'package:path/path.dart';

import 'utils/test_factory.dart';

void main() {
  Jni.spawn(
    dylibDir: join(Directory.current.path, 'build', 'jni_libs'),
  );

  /// More rigorous testing is done in the Android test suite
  /// because it is also testing the universal Timezone factory
  /// which has much more code.
  testFactory(JavaTimezoneFactory());
}
