// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';

class TimezoneSpan extends Equatable {
  /// Microseconds since the epoch this span starts at.
  final BigInt start;

  /// Microseconds since the epoch this span ends at.
  final BigInt end;

  /// The timezone abbreviation for this span.
  /// e.g. "EST", "EDT", "PST", "PDT"
  final String abbreviation;

  /// The offset from UTC in seconds.
  final BigInt offset;

  /// Whether this span is in daylight saving time.
  final bool isDst;
  TimezoneSpan({
    required this.start,
    required this.end,
    required this.abbreviation,
    required this.offset,
    required this.isDst,
  });

  @override
  List<Object?> get props => [start, end, abbreviation, offset, isDst];
  @override
  bool? get stringify => true;
}

class TimezoneNotFoundException implements Exception {
  final String timezoneName;

  TimezoneNotFoundException(this.timezoneName);

  @override
  String toString() =>
      'TimezoneNotFoundException: Timezone "$timezoneName" not found';
}

class Offset extends Equatable {
  /// The offset that this timezone is currently at.
  /// For instance the offset for New York is -5 hours
  /// during standard time. However during daylight saving time,
  /// the offset will be -4 hours.
  ///
  /// The returned value is in milliseconds.
  final int offset;

  /// If this is currently in daylight saving time, this will be the offset
  /// from the standard offset.
  /// For instance, when New York is in daylight saving time, the offset will be -1 hour.
  /// However during standard time, the offset will be null
  ///
  /// The returned value is in milliseconds.
  final int? dstDelta;
  const Offset._({
    required this.offset,
    required this.dstDelta,
  });

  factory Offset({required int offset, required int? dstDelta}) {
    return Offset._(offset: offset, dstDelta: dstDelta == 0 ? null : dstDelta);
  }

  @override
  List<Object?> get props => [offset, dstDelta];

  @override
  bool? get stringify => true;
}

abstract class BaseTimezone {
  const BaseTimezone();

  /// A unique identifier for this timezone.
  String get id;

  /// Returns an [Offset] object representing the time zone offset at the given
  /// [millisecondsSinceEpoch].
  ///
  /// The [millisecondsSinceEpoch] parameter is the number of milliseconds
  /// since the Unix epoch (January 1, 1970, 00:00:00 UTC).
  ///
  /// This method calculates the offset based on the provided timestamp and
  /// returns it as an [Offset] object.
  int offset(int millisecondsSinceEpoch);
}
