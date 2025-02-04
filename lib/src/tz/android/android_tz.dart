import 'dart:ffi';

import 'package:dateutil/src/tz/android/bindings.dart';
import 'package:dateutil/src/tz/shared.dart';
import 'package:equatable/equatable.dart';
import 'package:jni/jni.dart';
import 'package:meta/meta.dart';

Set<String> getTimeZonesNames() {
  final jNames = ZoneId.getAvailableZoneIds();
  final names =
      jNames!.toList().map((e) => e!.toDartString(releaseOriginal: true));
  jNames.release();
  return names.toSet();
}

JavaTimezone getTimeZoneByName(String name) {
  final jTz = JString.fromString(name).use((name) => ZoneId.of$1(name));
  if (jTz == null) {
    throw TimezoneNotFoundException(name);
  }
  final id = jTz.getId()!.toDartString(releaseOriginal: true);
  jTz.release();
  return JavaTimezone(id);
}

@Immutable()
class JavaTimezone extends BaseTimezone with EquatableMixin {
  @override
  final String id;
  JavaTimezone(this.id);

  @override
  int offset(int millisecondsSinceEpoch) {
    final instant = Instant.ofEpochMilli(millisecondsSinceEpoch);
    final result = JString.fromString(id)
        .use((name) => ZoneId.of$1(name))!
        .use((p0) => ZonedDateTime.ofInstant(instant, p0))!
        .use((p0) => p0.getOffset()!.use((offset) => offset.getTotalSeconds()));
    instant!.release();
    return result * 1000;
  }

  @override
  List<Object?> get props => [id];
}
