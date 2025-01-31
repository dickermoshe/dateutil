// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:io';

import 'package:b/b.dart';
import 'package:dateutil/src/tz/shared.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:dateutil/src/tz/windows_timezone.dart';

import 'utils/unique_years.dart';
import 'utils/windows_tz_mappings.g.dart';

void main() {
  final runner = IanaRunner();

  group("aina-transition ", () {
    for (var year in uniqueYears(2030)) {
      group(" year $year ", () {
        for (final MapEntry(:key, :value)
            in runner.availableTimeZones.entries) {
          group(" iana $key", () {
            final ainaTz = value;
            final windownTzNames = ianaToWindows[key];
            for (var windowsTzName in windownTzNames!) {
              test(" to windows $windowsTzName", () {
                final dartTz = WindowsTimezone.fromName(windowsTzName);
                expect(dartTz.stdOffset, ainaTz.currentStdUtcOffset,
                    reason:
                        "dartTz: $dartTz, ainaTz: ${ainaTz.currentStdUtcOffset}");
              });
            }
          });
        }
      });
    }
  });
}

class IanaRunner {
  late final Map<String, AinaTimezone> availableTimeZones;

  /// These keys are not timezone names
  static final ignoredKeys = [
    RegExp("^years"),
    RegExp("^version"),
    RegExp("^leapSeconds"),
    RegExp("^deltaTs"),
    RegExp(r"^_")
  ];

  IanaRunner() {
    final currentPath = p.basename(p.current);
    if (currentPath != "dateutil") {
      print("This script should be run from the root of the package");
      exit(1);
    }
    final timzeonePath = p.join("test", "utils", "timezone.json");
    assert(File(timzeonePath).existsSync());
    final timezones = jsonDecode(File(timzeonePath).readAsStringSync())
        as Map<String, dynamic>;

    availableTimeZones = Map.fromEntries(timezones.keys
        .map((e) {
          // Some keys aren't timezone names, we ignore them
          if (ignoredKeys.any((k) => k.hasMatch(e))) {
            return null;
          }
          // We are only testing against windows timezones
          // if we can't find a mapping, we ignore it
          final windowsTimezones = ianaToWindows[e];
          if (windowsTimezones == null) {
            return null;
          }
          // If the timezone info is a string that starts with a plus or minus
          // it's a timezone, otherwise it's just an alias
          if (timezones[e] case String v
              when v.startsWith("+") || v.startsWith("-")) {
            return e;
          } else {
            return null;
          }
        })
        .nonNulls
        .map((e) {
          final tz = timezones[e] as String;
          return MapEntry(e, AinaTimezone.fromTabular(tz));
        }));
  }
}

class AinaTimezone {
  // The offset before timzeons were established
  final Duration initialUtcOffset;
  // The current standard offset - 5 hours for EST
  final Duration currentStdUtcOffset;
  // The additional offset for DST - 1 hour for EDT
  final Duration currentDstOffset;

  /// The indexes of the transitions
  /// Each number corresponds to the index of the localTimeTypes
  final List<int>? transitionIndexes;

  /// The time zone types
  final List<LocalTimeType>? localTimeTypes;

  final List<Duration>? transitionDeltas;
  AinaTimezone._({
    required this.initialUtcOffset,
    required this.currentDstOffset,
    required this.currentStdUtcOffset,
    required this.localTimeTypes,
    required this.transitionIndexes,
    required this.transitionDeltas,
  });

  factory AinaTimezone.fromTabular(String tz) {
    final parts = tz.split(';');
    final offsetParts = parts[0].split(' ');
    final rawTimes = parts[1].split(" ");
    assert(rawTimes.isNotEmpty);
    final localTimeTypes = <LocalTimeType>[];
    for (var rawTime in rawTimes) {
      final parts = rawTime.split("/");
      final String? abbreviation;
      if (parts.length == 3) {
        abbreviation = parts[2];
      } else {
        abbreviation = null;
      }
      final utcOffset60 = parseBase60Duration(parts[0]);
      final dstOffset60 = parseBase60Duration(parts[1]);
      localTimeTypes.add(LocalTimeType(
          abbreviation: abbreviation,
          dstOffset60: dstOffset60,
          utcOffset60: utcOffset60));
    }

    final transitionIndexes = parts
        .elementAtOrNull(2)
        ?.split("")
        .map((e) => _base60ToInt(e))
        .toList();

    final transitionDeltas = parts
        .elementAtOrNull(3)
        ?.split(" ")
        .map((e) {
          if (e.isEmpty) {
            return null;
          }
          return parseBase60Duration(e);
        })
        .nonNulls
        .toList();

    return AinaTimezone._(
        transitionDeltas: transitionDeltas,
        transitionIndexes: transitionIndexes,
        localTimeTypes: localTimeTypes,
        currentDstOffset: Duration(minutes: int.parse(offsetParts[2])),
        initialUtcOffset: parseHHMMorHHMMSS(offsetParts[0]),
        currentStdUtcOffset: parseHHMMorHHMMSS(offsetParts[1]));
  }

  @override
  ({int dstOff, int dstOn})? transition(int year) {
    // TODO: implement transition
    throw UnimplementedError();
  }
}

class LocalTimeType {
  final Duration utcOffset60;
  final Duration dstOffset60;
  final String? abbreviation;
  LocalTimeType({
    required this.utcOffset60,
    required this.dstOffset60,
    required this.abbreviation,
  });

  @override
  String toString() =>
      'LocalTimeType(utcOffset60: $utcOffset60, dstOffset60: $dstOffset60, abbreviation: $abbreviation)';
}

Duration parseHHMMorHHMMSS(String input) {
  final isNegative = input.startsWith("-");
  if (isNegative) {
    input = input.substring(1);
  }
  if (input.startsWith("+")) {
    input = input.substring(1);
  }
  final Duration result;
  if (input.length == 4) {
    result = Duration(
        hours: int.parse(input.substring(0, 2)),
        minutes: int.parse(input.substring(2)));
  } else if (input.length == 6) {
    result = Duration(
        hours: int.parse(input.substring(0, 2)),
        minutes: int.parse(input.substring(2, 4)),
        seconds: int.parse(input.substring(4)));
  } else {
    throw ArgumentError("Invalid input, $input");
  }
  return isNegative ? -result : result;
}

int _base60ToInt(String input) => int.parse(BaseConversion(
      from: '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWX',
      to: '0123456789',
    )(input));

Duration parseBase60Duration(String input) {
  final isNegative = input.startsWith("-");
  if (isNegative) {
    input = input.substring(1);
  }
  if (input.startsWith("+")) {
    input = input.substring(1);
  }
  final int minutes;
  final int seconds;
  if (input.contains(".")) {
    final parts = input.split(".");
    minutes = _base60ToInt(parts[0]);
    seconds = _base60ToInt(parts[1]);
  } else {
    minutes = _base60ToInt(input);
    seconds = 0;
  }
  final result = Duration(minutes: minutes, seconds: seconds);
  return isNegative ? -result : result;
}
