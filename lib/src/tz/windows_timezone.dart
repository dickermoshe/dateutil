import 'dart:ffi';
import 'package:dateutil/src/tz/shared.dart';
import 'package:win32/win32.dart' as win;
import 'package:win32_registry/win32_registry.dart';

/// Path to the time zones key on Modern Windows
// ignore: constant_identifier_names
const _TZKEYNAMENT = r'SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones';

/// Path to the time zones key on Windows 9x
// ignore: constant_identifier_names
const _TZKEYNAME9X = r'SOFTWARE\Microsoft\Windows\CurrentVersion\Time Zones';

/// A struct representing the REG_TZI_FORMAT struct in Windows which contains
/// time zone information. The timezone information is stored in the registry
/// under the `TZI` key as a binary value of this struct.
final class _TZI extends Struct {
  @Long()
  external final int wBias;
  @Long()
  external final int wStandardBias;
  @Long()
  external final int wDaylightBias;
  external final _SYSTEMTIME wStandardDate;
  external final _SYSTEMTIME wDaylightDate;
}

/// Represents a binding for the `SYSTEMTIME` structure in the Win32 API.
///
/// See [SYSTEMTIME](https://learn.microsoft.com/en-us/windows/win32/api/minwinbase/ns-minwinbase-systemtime) for more information.
///
/// Derived from https://github.com/timsneath/win32/blob/ffb2f5526b38266e2791fec34a22a51348a5d367/lib/src/structs.g.dart#L8483
final class _SYSTEMTIME extends Struct {
  @Uint16()
  external final int wYear;

  @Uint16()
  external final int wMonth;

  @Uint16()
  external final int wDayOfWeek;

  @Uint16()
  external final int wDay;

  @Uint16()
  external final int wHour;

  @Uint16()
  external final int wMinute;

  @Uint16()
  external final int wSecond;

  @Uint16()
  external final int wMilliseconds;
}

/// Opens the Windows registry key for time zone information.
///
/// This function accesses the Windows registry to retrieve time zone
/// information. It opens the registry key where time zone data is stored.
///
/// Returns:
///   A record containing the registry key and the path to the key.
({RegistryKey key, String name}) _openTimeZoneRegistry() {
  /// Attempt to open the time zones key using the Modern Windows path, falling
  /// back to the Windows 9x path if that fails.
  RegistryKey? key;
  String? keyName;
  try {
    key = Registry.openPath(RegistryHive.localMachine, path: _TZKEYNAMENT);
    keyName = _TZKEYNAMENT;
  } on win.WindowsException {
    try {
      key = Registry.openPath(RegistryHive.localMachine, path: _TZKEYNAME9X);
      keyName = _TZKEYNAME9X;
    } on win.WindowsException {
      //
    }
  }
  if (key == null || keyName == null) {
    throw Exception('Unable to read the timezones from '
        'the registry using $_TZKEYNAMENT or $_TZKEYNAME9X');
  }

  return (key: key, name: keyName);
}

/// Retrieves the registry key for a specific time zone.
///
/// This function accesses the Windows registry to retrieve the registry key
/// for a specific time zone.
///
/// Parameters:
///   [timeZoneId] - The ID of the time zone to retrieve.
///
/// Returns:
///   A [RegistryKey] object representing the registry key for
///   the specified time zone.
RegistryKey _getTimeZoneKey(String timeZoneId) => Registry.openPath(
      RegistryHive.localMachine,
      path: '${timeZoneKey.name}\\$timeZoneId',
    );

final ({RegistryKey key, String name}) timeZoneKey = _openTimeZoneRegistry();

class WindowsTimezone extends BaseTimezone {
  /// A collection of available time zones retrieved from the Windows registry.
  ///
  /// Note that the names from Windows differ from the IANA names.
  /// For example, the Windows time zone "Pacific Standard Time" corresponds to
  /// the IANA time zone "America/Los_Angeles".
  static Iterable<String> list() => timeZoneKey.key.subkeyNames;

  /// The offset from UTC during daylight saving time.
  final Duration _dstOffset;

  /// The 1st instance when DST ends. We will calculate when other DST
  /// transitions occur based on this.
  final _SYSTEMTIME _std;

  /// The 1st instance when DST starts. We will calculate when other DST
  /// transitions occur based on this.
  final _SYSTEMTIME _dst;

  /// A cache of time zones to avoid repeated lookups.
  static final Map<String, WindowsTimezone> _cachedTimeZones = {};

  WindowsTimezone._(
    super.name, {
    required String stdName,
    required String dstName,
    required super.stdOffset,
    required Duration dstOffset,
    required _SYSTEMTIME std,
    required _SYSTEMTIME dst,
  })  : _dst = dst,
        _std = std,
        _dstOffset = dstOffset;

  /// Creates a [WindowsTimezone] object from a time zone name.
  /// Note that the names from Windows differ from the IANA names.
  factory WindowsTimezone.fromName(String name) {
    if (_cachedTimeZones.containsKey(name)) {
      return _cachedTimeZones[name]!;
    }
    final tz = _getTimeZoneKey(name);
    // This struct is backed by dart memory, so it's safe to use it directly
    // and not worry about freeing it.
    final tziStruct = Struct.create<_TZI>(tz.getBinaryValue('TZI')!);
    final stdOffsetMinutes = -tziStruct.wBias - tziStruct.wStandardBias;
    return WindowsTimezone._(tz.getStringValue('Display')!,
        stdName: tz.getStringValue('Std')!,
        dstName: tz.getStringValue('Dlt')!,
        stdOffset: Duration(minutes: stdOffsetMinutes),
        dstOffset: Duration(
          minutes: stdOffsetMinutes - tziStruct.wDaylightBias,
        ),
        std: tziStruct.wStandardDate,
        dst: tziStruct.wDaylightDate);
  }

  late final bool _hasDst = _dst.wMonth != 0;
  late final Duration _baseDstOffset = _dstOffset - stdOffset;

  @override
  ({int dstOn, int dstOff})? transition(int year) {
    if (!_hasDst) {
      return null;
    }
    final dstOn = _picknthweekday(year, _dst.wMonth, _dst.wDayOfWeek,
        _dst.wHour, _dst.wMinute, _dst.wDay);
    var dstOff = _picknthweekday(year, _std.wMonth, _std.wDayOfWeek, _std.wHour,
        _std.wMinute, _std.wDay);
    dstOff = dstOff.subtract(_baseDstOffset);

    return (
      dstOn: dstOn.millisecondsSinceEpoch -
          stdOffset.inMilliseconds -
          _baseDstOffset.inMilliseconds,
      dstOff: dstOff.millisecondsSinceEpoch - _dstOffset.inMilliseconds,
    );
  }

  @override
  String toString() {
    return 'WindowsTimezone(name: $name, stdOffset: $stdOffset, dstOffset: $_dstOffset)';
  }
}

class WindowsTimezoneSpan {
  /// The offset from UTC in seconds.
  final int offset;

  /// The abbreviation for the timezone.
  final String abbreviation;

  /// The start of the span.
  /// This is the number of seconds since the epoch.
  final int start;

  /// The end of the span.
  /// This is the number of seconds since the epoch.
  final int end;

  /// Whether the span is in daylight saving time.
  /// If `false`, the span is in standard time.
  /// If `true`, the span is in daylight saving time.
  final bool dst;

  /// Creates a [WindowsTimezoneSpan].
  WindowsTimezoneSpan(this.offset, this.abbreviation, this.start, this.end,
      {required this.dst});
}

/// Picks the nth weekday of a given month and year.
///
/// This function calculates the date of the nth occurrence of a specific
/// weekday within a given month and year. For example, it can be used to
/// find the date of the third Monday in March 2023.
///
/// - Parameters:
///   - year: The year in which to find the nth weekday.
///   - month: The month (1-12) in which to find the nth weekday.
///   - dayofweek: The day of the week. This works with the ISO weekday
///     or Windows weekday format, where 0 is Sunday and 6 is Saturday.
///   - hour: The hour (0-23) to set for the resulting date.
///   - minute: The minute (0-59) to set for the resulting date.
///   - whichweek: The occurrence of the weekday to find
///     (e.g., 1 for the first occurrence, 2 for the second).
///
/// - Returns: The DateTime object representing the nth occurrence of the
///   specified weekday in the given month and year.
///
/// This code has been adapted from the original implementation in the
/// `dateutil` Python library.
DateTime _picknthweekday(
    int year, int month, int dayofweek, int hour, int minute, int whichweek) {
  final first = DateTime.utc(year, month, 1, hour, minute);
  final weekdayone = first.copyWith(day: ((dayofweek - first.weekday) % 7) + 1);
  var wd = weekdayone.add(const Duration(days: 7) * (whichweek - 1));
  if (wd.month != month) {
    wd = wd.subtract(const Duration(days: 7));
  }

  return wd;
}
