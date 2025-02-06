import 'package:dateutil/src/tz/web/web_tz.dart';
import 'package:test/test.dart';

void main() {
  group('js', () {
    final factory = WebTimezoneFactory();
    for (final tz in factory.listTimezones()) {
      test(tz, () {
        factory.getTimezone(tz);
      });
    }
  });
}
