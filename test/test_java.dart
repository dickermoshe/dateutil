import 'dart:io';
import 'dart:math';

import 'package:dateutil/src/tz/android/android_tz.dart' as and;
import 'package:dateutil/src/tz/universal/universal_tz.dart' as win;

import 'package:jni/jni.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import 'utils/unique_years.dart';

void main() {
  final random = Random();
  group("java", () {
    Jni.spawn(
      dylibDir: join(Directory.current.path, "build", "jni_libs"),
    );
    final windowsTimeZones = win.getTimeZonesNames().toList();
    final androidTimeZones = and.getTimeZonesNames().toList();
    final sharedTimezones =
        androidTimeZones.toSet().intersection(windowsTimeZones.toSet());

    sharedTimezones.removeWhere((element) => !element.startsWith('SystemV/'));

    for (var timezone in sharedTimezones) {
      group("timezone $timezone", () {
        final winTz = win.getTimeZoneByName(timezone);
        final andTz = and.getTimeZoneByName(timezone);

        // We test all the possible years:
        // 1. BC Years
        // 2. AC Years before years we have timezone data for
        // 3. Years we have timezone data for
        // 4. Years we have timezone data for after 2038
        // 5. Years we dont have timezone data for after 2200
        final years = [
          ...uniqueYears(random.nextInt(20)),
          ...uniqueYears(random.nextInt(20) - 100),
          ...uniqueYears(random.nextInt(20) + 1950),
          ...uniqueYears(random.nextInt(20) + 2000),
          ...uniqueYears(random.nextInt(20) + 1900),
          ...uniqueYears(random.nextInt(20) + 2038),
          ...uniqueYears(random.nextInt(20) + 2200),
        ];

        /// We also want to test the years when we run out of trasition deltas
        /// and are using dstrules to calculate the offset
        if (winTz.lastYear case int endYear) {
          years.add(endYear - 2);
          years.add(endYear - 1);
          years.add(endYear);
          years.add(endYear + 1);
          years.add(endYear + 2);
          years.add(endYear + 3);
        }

        for (var year in years) {
          test(year, () {
            expect(winTz.id, andTz.id);
            var dt = DateTime.utc(year, 6, 1);
            while (dt.year < year + 1) {
              final winOffset = winTz.offset(dt.millisecondsSinceEpoch);
              final andOffset = andTz.offset(dt.millisecondsSinceEpoch);

              expect(
                winOffset,
                andOffset,
                reason: "Date: $dt, WinOffset:$winOffset, AndOffset:$andOffset",
              );
              dt = dt.add(Duration(minutes: 30));
            }
          });
        }
      });
    }
  });
}
