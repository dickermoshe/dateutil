// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:dateutil/src/tz/windows_timezone.dart';

import 'utils/unique_years.dart';

void main() {
  final runner = PythonRunner();
  final timezones = runner.getWindowsTimezones();

  group("dateutil-transition ", () {
    for (var year in uniqueYears()) {
      group(" year $year ", () {
        final bulkDstTransitions = runner.getBulkDstOffsets(timezones, year);
        for (final entry in bulkDstTransitions.entries) {
          test("for ${entry.key}", () {
            final dartTz = WindowsTimezone.fromName(entry.key);
            final dartTransition = dartTz.transition(year);
            final pythonTransition = entry.value;
            expect(dartTz.stdOffset.inSeconds, pythonTransition.stdOffset);
            if (dartTransition == null) {
              expect(pythonTransition.dstOn, isNull);
              expect(pythonTransition.dstOff, isNull);
            } else {
              expect(dartTransition.dstOn / Duration.millisecondsPerSecond,
                  pythonTransition.dstOn);
              expect(dartTransition.dstOff / Duration.millisecondsPerSecond,
                  pythonTransition.dstOff);
            }
          });
        }
      });
    }
  });
}

/// Dataclass to parse the results from the python scripts
class DstTransition {
  final double? dstOn;
  final double? dstOff;
  final int dstOffset;
  final int stdOffset;
  DstTransition({
    this.dstOn,
    this.dstOff,
    required this.dstOffset,
    required this.stdOffset,
  });

  factory DstTransition.fromMap(Map<String, dynamic> map) {
    return DstTransition(
      dstOn: map['dst_on'] != null ? map['dst_on'] as double : null,
      dstOff: map['dst_off'] != null ? map['dst_off'] as double : null,
      dstOffset: (map['dst_offset'] as double).toInt(),
      stdOffset: (map['std_offset'] as double).toInt(),
    );
  }

  factory DstTransition.fromJson(String source) =>
      DstTransition.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'DstTransition(dstOn: $dstOn, dstOff: $dstOff, dstOffset: $dstOffset, stdOffset: $stdOffset)';
  }
}

/// Utility class to run python scripts
/// to confirm the correctness of the windows timezones
class PythonRunner {
  late final String pythonPath;
  String get windowsTimezonesPath => p.join(pythonPath, 'windows_timezones.py');

  String get windowsBulkDstTransitionPath =>
      p.join(pythonPath, 'windows_bulk_dst_transition.py');
  PythonRunner() {
    final currentPath = p.basename(p.current);
    if (currentPath != "dateutil") {
      print("This script should be run from the root of the package");
      exit(1);
    }
    final uvCheck = Process.runSync('uv', ['version'], runInShell: true);
    if (uvCheck.exitCode != 0) {
      print("uv is not installed. Please install it and try again.");
      exit(1);
    }
    pythonPath = p.join(p.current, 'test', 'utils', 'python');
  }
  List<String> getWindowsTimezones() {
    final result = Process.runSync('uv', ['run', windowsTimezonesPath],
        workingDirectory: pythonPath, runInShell: true);
    if (result.exitCode != 0) {
      print("Failed to get windows timezones");
      print(result.stderr);

      exit(1);
    }

    return (jsonDecode(result.stdout) as List).cast<String>();
  }

  Map<String, DstTransition> getBulkDstOffsets(
      List<String> timezones, int year) {
    final result = Process.runSync(
        'uv',
        [
          'run',
          windowsBulkDstTransitionPath,
          year.toString(),
          ...timezones.map((e) => ["--timezones", e]).expand((e) => e),
        ],
        workingDirectory: pythonPath,
        runInShell: true);
    if (result.exitCode != 0) {
      print(result.stderr);
      print(result.stdout);

      print("Failed to get dst offsets");
    }
    final results = jsonDecode(result.stdout) as List;
    return Map.fromEntries(results.indexed.map((e) {
      final key = timezones[e.$1];
      final value = DstTransition.fromMap(e.$2 as Map<String, dynamic>);
      return MapEntry(key, value);
    }));
  }
}
