// ignore: library_annotations
@TestOn('mac-os||ios')

import 'package:dateutil/src/tz/foundation/foundation_tz.dart';
import 'package:test/test.dart';

import 'utils/test_factory.dart';

void main() {
  final factory = FoundationTimezoneFactory();
  testFactory(factory, years: [-100, 0, 100, 1950, 2000, 2038, 2200]);
}
