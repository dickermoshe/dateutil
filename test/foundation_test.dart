@TestOn('mac-os||ios')
library;

import 'package:dateutil/src/tz/foundation/foundation_tz.dart';
import 'package:test/test.dart';

import 'utils/test_factory.dart';

void main() {
  final factory = FoundationTimezoneFactory();
  testFactory(factory, years: [DateTime.now().year]);
}
