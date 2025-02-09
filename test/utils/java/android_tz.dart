import 'package:equatable/equatable.dart';
import 'package:jni/jni.dart';
import 'package:meta/meta.dart';
import 'package:tz/src/tz/shared.dart';

import 'bindings.dart';

/// A factory that provides access to the Java timezone database.
@internal
class JavaTimezoneFactory extends TimezoneFactory<JavaTimezone> {
  @override
  JavaTimezone getTimezone(String id) {
    return JavaTimezone(id);
  }

  @override
  Set<String> listTimezones() {
    return ZoneId.getAvailableZoneIds()!.use((ids) {
      return ids
          .map((element) => element?.toDartString(releaseOriginal: true))
          .nonNulls
          .toSet();
    });
  }

  @override
  String get name => 'java';
}

/// A timezone that uses the Java timezone database.
@Immutable()
@internal
class JavaTimezone with EquatableMixin implements Timezone {
  /// Creates a new Java timezone with the given [id].
  const JavaTimezone(this.name);

  @override
  final String name;

  @override
  int offset(int millisecondsSinceEpoch) {
    final instant = Instant.ofEpochMilli(millisecondsSinceEpoch);
    final result = _zoneId()
        .use((p0) => ZonedDateTime.ofInstant(instant, p0))!
        .use((p0) => p0.getOffset()!.use((offset) => offset.getTotalSeconds()));
    instant!.release();
    return result * 1000;
  }

  ZoneId _zoneId() {
    return JString.fromString(name).use(ZoneId.of$1)!;
  }

  @override
  List<Object?> get props => [name];
  @override
  bool? get stringify => true;

  @override
  int convert(
    int year, [
    int month = 1,
    int day = 1,
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
    int microsecond = 0,
  ]) {
    final nanoSeconds = (microsecond * 1000) + (millisecond * 1000000);
    return _zoneId().use(
      (zone) => ZonedDateTime.of$2(
        year,
        month,
        day,
        hour,
        minute,
        second,
        nanoSeconds,
        zone,
      )!
          .use(
        (zonedDateTime) => Instant.from(zonedDateTime)!
            .use((instant) => instant.getEpochSecond() * 1000),
      ),
    );
  }
}
