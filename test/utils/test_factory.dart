import 'dart:math';

import 'package:collection/collection.dart';
import 'package:dateutil/src/tz/shared.dart';
import 'package:dateutil/src/tz/universal/universal_tz.dart';
import 'package:test/test.dart';

import 'unique_years.dart';

List<int> _defaultYears(UniversalTimezone tz) {
  final random = Random();

  final years = [
    ...uniqueYears(random.nextInt(20)),
    ...uniqueYears(random.nextInt(20) - 100),
    ...uniqueYears(random.nextInt(20) + 1950),
    ...uniqueYears(random.nextInt(20) + 2000),
    ...uniqueYears(random.nextInt(20) + 1900),
    ...uniqueYears(random.nextInt(20) + 2038),
    ...uniqueYears(random.nextInt(20) + 2200),
  ];

  if (tz.lastYear case final int endYear) {
    years.add(endYear - 2);
    years.add(endYear - 1);
    years.add(endYear);
    years.add(endYear + 1);
    years.add(endYear + 2);
  }

  if (tz.firstYear case final int firstYear) {
    years.add(firstYear - 2);
    years.add(firstYear - 1);
    years.add(firstYear);
    years.add(firstYear + 1);
    years.add(firstYear + 2);
  }
  return years;
}

void testFactory(TimezoneFactory factory, {List<int>? years}) {
  group(factory.name, () {
    final universalProvider =
        TimezoneProvider<UniversalTimezone, UniversalTimezoneFactory>(
      UniversalTimezoneFactory(),
    );
    final testProvider = TimezoneProvider(factory);

    final testDate = universalProvider.listTimezones().map((e) {
      final uniTz = universalProvider.getTimezone(e);
      final testTz = testProvider.getTimezone(e);
      final effectiveYears = (years ?? _defaultYears(uniTz)).shuffled();
      return (
        testTz: testTz,
        universalTz: uniTz,
        years: effectiveYears,
      );
    }).shuffled();

    for (final t in testDate) {
      test(t.testTz.id, () {
        for (final year in t.years) {
          expect(t.universalTz.id, t.testTz.id);
          var dt = DateTime.utc(year);
          while (dt.year < year + 1) {
            final universalOffset =
                t.universalTz.offset(dt.millisecondsSinceEpoch);
            final testOffset = t.testTz.offset(dt.millisecondsSinceEpoch);

            expect(
              universalOffset,
              testOffset,
              reason:
                  'Date: $dt, UniversalOffset:$universalOffset, TestOffset:$testOffset',
            );
            dt = dt.add(const Duration(minutes: 30));
          }
        }
      });
    }
  });
}
