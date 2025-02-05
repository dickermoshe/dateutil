import 'package:equatable/equatable.dart';
import 'package:jni/jni.dart';
import 'package:meta/meta.dart';

import '../shared.dart';
import 'bindings.dart';

/// A factory that provides access to the Java timezone database.
class JavaTimezoneFactory extends TimezoneFactory<JavaTimezone> {
  @override
  JavaTimezone getTimezone(String id) {
    return JavaTimezone(id);
  }

  @override
  Set<String> listTimezoneIds() {
    final jNames = ZoneId.getAvailableZoneIds();
    final names = jNames!.toList().map(
          (e) => e!.toDartString(releaseOriginal: true),
        );
    jNames.release();
    return names.toSet();
  }

  @override
  String get name => 'java';
}

@Immutable()

/// A timezone that uses the Java timezone database.
class JavaTimezone extends BaseTimezone with EquatableMixin {
  /// Creates a new Java timezone with the given [id].
  const JavaTimezone(super.id);

  @override
  int offset(int millisecondsSinceEpoch) {
    final instant = Instant.ofEpochMilli(millisecondsSinceEpoch);
    final result = JString.fromString(id)
        .use(ZoneId.of$1)!
        .use((p0) => ZonedDateTime.ofInstant(instant, p0))!
        .use((p0) => p0.getOffset()!.use((offset) => offset.getTotalSeconds()));
    instant!.release();
    return result * 1000;
  }

  @override
  List<Object?> get props => [id];
}
