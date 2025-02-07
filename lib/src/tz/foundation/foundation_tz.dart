import 'dart:ffi';
import 'dart:core' as core show Duration;
import 'dart:core' hide Duration;

import 'package:equatable/equatable.dart';
import 'package:ffi/ffi.dart';
import 'package:meta/meta.dart';

import '../shared.dart';
import '../universal/timezone_names.g.dart';
import 'bindings.dart';

/// A factory that provides access to the Foundation timezone database.
@internal
class FoundationTimezoneFactory extends TimezoneFactory<FoundationTimezone> {
  @override
  FoundationTimezone getTimezone(String id) {
    return FoundationTimezone(id);
  }

  @override
  Set<String> listTimezones() {
    return timezoneNames;
  }

  @override
  String get name => 'foundation';
}

/// A timezone that uses the Foundation timezone database.
@Immutable()
@internal
class FoundationTimezone with EquatableMixin implements Timezone {
  /// Creates a new Foundation timezone with the given [id].
  const FoundationTimezone(this.id);

  @override
  final String id;

  @override
  int offset(int millisecondsSinceEpoch) {
    // For some reason which only god
    // knows, the CoreFoundation
    // uses Jan 1st 2001 as the reference date
    // while every other lang uses Jan 1st 1970
    // as the reference date.
    // They also use seconds instead of milliseconds
    final secondsSinceEpoch = (millisecondsSinceEpoch / 1000) - 978307200;
    final tz = TimeZone(DynamicLibrary.open(
        '/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation'));

    return using((a) {
      final cStr = id.toNativeUtf8();
      final encoding = tz.CFStringGetSystemEncoding();
      final tryAbbrev = tz.CFStringCreateWithCString(
        tz.kCFAllocatorDefault,
        cStr.cast<Char>(),
        encoding,
      );
      tz.CFRetain(tryAbbrev.cast());

      try {
        final knownTimeZones = tz.CFTimeZoneCreateWithName(
          tz.kCFAllocatorDefault,
          tryAbbrev,
          0,
        );
        tz.CFRetain(knownTimeZones.cast());
        try {
          final data = tz.CFTimeZoneGetSecondsFromGMT(
            knownTimeZones,
            secondsSinceEpoch,
          );
          final inMilliseconds = data * 1000;
          return inMilliseconds.toInt();
        } finally {
          tz.CFRelease(knownTimeZones.cast());
        }
      } finally {
        tz.CFRelease(tryAbbrev.cast());
      }
    });
  }

  @override
  List<Object?> get props => [id];
  @override
  bool? get stringify => true;
}
