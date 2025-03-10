import 'dart:math';

import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:tz/src/tz/shared.dart';
import 'package:tz/src/tz/universal/universal_tz.dart';

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

typedef TestJob = ({String tz, int year});

void testFactory(TimezoneFactory testFactory, {List<int>? years}) {
  final tests = <TestJob>[];
  final universalFactory = UniversalTimezoneFactory();

  final testTimezones = testFactory.listTimezones().toSet().intersection(
        universalFactory.listTimezones().toSet(),
      );

  for (final tz in testTimezones) {
    final universalTz = universalFactory.getTimezone(tz);
    final effectiveYears = (years ?? _defaultYears(universalTz)).shuffled();
    for (final year in effectiveYears) {
      tests.add((tz: tz, year: year));
    }
  }
  tests.shuffle();

  for (final t in tests) {
    test('${t.tz} - ${t.year}', () {
      Timezone.setFactory(universalFactory);
      final uniTz = Timezone(t.tz);
      Timezone.setFactory(testFactory);
      final testTz = testFactory.getTimezone(t.tz);
      expect(uniTz.name, testTz.name);
      var dt = DateTime.utc(t.year);
      while (dt.year < t.year + 1) {
        final universalOffset = uniTz.offset(dt.millisecondsSinceEpoch);
        final testOffset = testTz.offset(dt.millisecondsSinceEpoch);
        expect(
          universalOffset,
          testOffset,
          reason:
              'Date: $dt, UniversalOffset:$universalOffset, TestOffset:$testOffset',
        );
        // Apply the offset to the date
        final localized = dt.add(Duration(milliseconds: universalOffset));
        // Try to convert it back and test it matches
        final testConverted = testTz.convert(
          localized.year,
          localized.month,
          localized.day,
          localized.hour,
          localized.minute,
          localized.second,
          localized.millisecond,
          localized.microsecond,
        );
        final universalConverted = uniTz.convert(
          localized.year,
          localized.month,
          localized.day,
          localized.hour,
          localized.minute,
          localized.second,
          localized.millisecond,
          localized.microsecond,
        );
        expect(
          universalConverted,
          testConverted,
          reason:
              'Date: $dt, UniversalConverted:$universalConverted, TestConverted:$testConverted',
        );
        dt = dt.add(const Duration(minutes: 30));
      }
    });
  }
}
