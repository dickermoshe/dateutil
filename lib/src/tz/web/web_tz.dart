import 'dart:js_interop';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../shared.dart';
import '../universal/timezone_names.g.dart';

@JS('BigInt')
external JSBigInt _bigInt(String s);

@JS('ZonedDateTime')
extension type _ZonedDateTime._(JSObject _) implements JSObject {
  external _ZonedDateTime(JSBigInt epochNanoseconds, String timezoneName);
  external int offsetNanoseconds;
}

/// A factory that provides access to the Java timezone database.
@internal
class WebTimezoneFactory extends TimezoneFactory<WebTimezone> {
  @override
  String get name => 'web';
  @override
  WebTimezone getTimezone(String id) =>WebTimezone(id);
  

  @override
  Set<String> listTimezones() =>timezoneNames;
}


@Immutable()
@internal
/// A timezone that uses the Java timezone database.
class WebTimezone with EquatableMixin implements Timezone {
  /// Creates a new Java timezone with the given [id].
  WebTimezone(this.id);
  
  @override
  final String id;

  @override
  int offset(int millisecondsSinceEpoch) {
    final epochNanoseconds = _bigInt((millisecondsSinceEpoch * 1_000_000).toString());
    final dt = _ZonedDateTime(epochNanoseconds,id);
    return (dt.offsetNanoseconds / 1_000_000).toInt();
  }

  @override
  List<Object?> get props => [id];
  @override
  bool? get stringify => true;
}
