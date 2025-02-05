import 'dart:js_interop';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../shared.dart';

@JS('BigInt')
external JSBigInt _bigInt(String s);

@JS('ZonedDateTime')
extension type _ZonedDateTime._(JSObject _) implements JSObject {
  external _ZonedDateTime(JSBigInt epochNanoseconds, String timezoneName);
  external int offsetNanoseconds;
}

/// A factory that provides access to the Java timezone database.
class WebTimezoneFactory extends TimezoneFactory<WebTimezone> {
  @override
  String get name => 'web';
  @override
  WebTimezone getTimezone(String id) {
    final tz = WebTimezone(id);
    // Check that it actually exists
    try {
      tz.offset(0);
    } catch (e) {
      throw TimezoneNotFoundException(id);
    }
    return tz;
  }

  // @override
  // Set<String> listTimezoneIds() {
  //   final jNames = ZoneId.getAvailableZoneIds();
  //   final names = jNames!.toList().map(
  //         (e) => e!.toDartString(releaseOriginal: true),
  //       );
  //   jNames.release();
  //   return names.toSet();
  // }
}

@Immutable()

/// A timezone that uses the Java timezone database.
class WebTimezone extends BaseTimezone with EquatableMixin {
  /// Creates a new Java timezone with the given [id].
  const WebTimezone(super.id);

  @override
  int offset(int millisecondsSinceEpoch) {
    return (_ZonedDateTime(
              _bigInt(millisecondsSinceEpoch.toString()),
              id,
            ).offsetNanoseconds /
            1000000)
        .toInt();
  }

  @override
  List<Object?> get props => [id];
}
