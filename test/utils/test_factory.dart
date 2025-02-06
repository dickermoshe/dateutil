import 'dart:math';

import 'package:dateutil/src/tz/shared.dart';
import 'package:dateutil/src/tz/universal/universal_tz.dart';
import 'package:test/test.dart';

import 'unique_years.dart';

void testFactory(TimezoneFactory factory) {
  final random = Random();

  final universalProvider =
      TimezoneProvider<UniversalTimezone, UniversalTimezoneFactory>(
    UniversalTimezoneFactory(),
  );
  final testProvider = TimezoneProvider(factory);

  for (final tzname in universalProvider.listTimezones()) {
    test(tzname, () {
      final universalTz = universalProvider.getTimezone(tzname);
      final testTz = testProvider.getTimezone(tzname);
      final years = [
        ...uniqueYears(random.nextInt(20)),
        ...uniqueYears(random.nextInt(20) - 100),
        ...uniqueYears(random.nextInt(20) + 1950),
        ...uniqueYears(random.nextInt(20) + 2000),
        ...uniqueYears(random.nextInt(20) + 1900),
        ...uniqueYears(random.nextInt(20) + 2038),
        ...uniqueYears(random.nextInt(20) + 2200),
      ];

      if (universalTz.lastYear case final int endYear) {
        years.add(endYear - 2);
        years.add(endYear - 1);
        years.add(endYear);
        years.add(endYear + 1);
        years.add(endYear + 2);
      }

      if (universalTz.firstYear case final int firstYear) {
        years.add(firstYear - 2);
        years.add(firstYear - 1);
        years.add(firstYear);
        years.add(firstYear + 1);
        years.add(firstYear + 2);
      }
      for (final year in years) {
        expect(universalTz.id, testTz.id);
        var dt = DateTime.utc(year, 6);
        while (dt.year < year + 1) {
          final winOffset = universalTz.offset(dt.millisecondsSinceEpoch);
          final andOffset = testTz.offset(dt.millisecondsSinceEpoch);

          expect(
            winOffset,
            andOffset,
            reason:
                'Date: $dt, UniversalOffset:$winOffset, TestOffset:$andOffset',
          );
          dt = dt.add(const Duration(minutes: 30));
        }
      }
    });
  }
}
