import 'dart:io';

import 'package:dateutil/src/tz/android/android_tz.dart';

import 'package:jni/jni.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import 'utils/test_factory.dart';

void main() {
  group('java', () {
    Jni.spawn(
      dylibDir: join(Directory.current.path, 'build', 'jni_libs'),
    );
    testFactory(JavaTimezoneFactory());
  });
}
