import 'package:dateutil/src/tz/web/web_tz.dart';

import 'utils/test_factory.dart';

void main() {
  final factory = WebTimezoneFactory();
  testFactory(factory, years: [DateTime.now().year]);
}
