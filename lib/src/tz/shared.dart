import 'package:meta/meta.dart';
import 'factory_stub.dart'
    if (dart.library.html) 'factory_web.dart'
    if (dart.library.io) 'factory_io.dart';

@immutable
@internal
abstract class TimezoneFactory<TZ extends Timezone> {
  /// The name of this factory.
  String get name;

  /// Returns a list of all available timezone identifiers.
  Set<String> listTimezones();

  /// Gets the timezone with the given [id].
  TZ getTimezone(String id);
}

@immutable

/// Represents a timezone with a unique identifier and provides methods to
/// retrieve timezone information such as the offset from UTC at a given time.
abstract class Timezone {
  /// Creates a new timezone with the given [id].
  /// Calling this contructor with an invalid id will throw a [TimezoneNotFoundException].
  factory Timezone(String id) {
    if (_cachedTimezones.containsKey(id)) {
      return _cachedTimezones[id]!;
    }

    if (!_factory.listTimezones().contains(id)) {
      throw TimezoneNotFoundException(id);
    }

    final result = _factory.getTimezone(id);
    _cachedTimezones[id] = result;
    return result;
  }

  static TimezoneFactory _factory = defaultFactory;
  static final Map<String, Timezone> _cachedTimezones = {};

  @visibleForTesting
  // ignore: public_member_api_docs
  static TimezoneFactory get factory => _factory;

  @visibleForTesting
  // ignore: public_member_api_docs
  static set factory(TimezoneFactory factory) {
    _factory = factory;
    _cachedTimezones.clear();
  }

  /// Returns a list of all available timezone identifiers.
  static Set<String> listTimezones() => _factory.listTimezones();

  /// A unique identifier for this timezone.
  String get id;

  /// Returns the offset in milliseconds for the timezone at the given
  /// [millisecondsSinceEpoch].
  int offset(int millisecondsSinceEpoch);
}

/// Thrown when a timezone with the given name is not found.
class TimezoneNotFoundException implements Exception {
  /// Creates a new TimezoneNotFoundException with the given [timezoneName].
  TimezoneNotFoundException(this.timezoneName);

  /// The name of the timezone that was not found.
  final String timezoneName;

  @override
  String toString() =>
      'TimezoneNotFoundException: Timezone "$timezoneName" not found';
}
