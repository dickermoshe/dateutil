import 'package:equatable/equatable.dart';
import 'package:jni/jni.dart';
import 'package:meta/meta.dart';

import '../shared.dart';
import '../universal/timezone_names.g.dart';
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
    return timezoneNames;
  }

  @override
  String get name => 'java';
}

/// A timezone that uses the Java timezone database.
@Immutable()
@internal
class JavaTimezone with EquatableMixin implements Timezone {
  /// Creates a new Java timezone with the given [id].
  const JavaTimezone(this.id);

  @override
  final String id;

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
  @override
  bool? get stringify => true;
}
