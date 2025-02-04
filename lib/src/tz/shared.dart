// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

abstract class TimezoneFactory<TZ extends BaseTimezone> {
  Set<String>? cachedTimezoneNames;
  final Map<String, TZ> cachedTimezones = {};
  Set<String> listTimezoneIds();
  TZ getTimezone(String id);
}

/// Base class for all timezones providers.
@immutable
class TimezoneProvider<TZ extends BaseTimezone> {
  final TimezoneFactory<TZ> _factory;
  const TimezoneProvider(this._factory);
  Set<String> listTimezoneIds() {
    /// If the timezone names are already cached, return them.
    if (_factory.cachedTimezoneNames != null) {
      return _factory.cachedTimezoneNames!;
    }

    /// Otherwise, fetch the timezone names and cache them.
    final names = _factory.listTimezoneIds();

    // We ignore SystemV timezones as they are not
    // supported by the tubular_time_tzdb project
    names.removeWhere((element) => element.startsWith('SystemV/'));

    _factory.cachedTimezoneNames = names;
    return names;
  }

  TZ getTimezone(String id) {
    /// If the timezone is already cached, return it.
    if (listTimezoneIds().contains(id)) {
      return _factory.cachedTimezones[id]!;
    }

    /// If the timezone is not found, throw an exception.
    if (!listTimezoneIds().contains(id)) {
      throw TimezoneNotFoundException(id);
    }

    /// Otherwise, fetch the timezone and cache it.
    final result = _factory.getTimezone(id);
    _factory.cachedTimezones[id] = result;
    return result;
  }

  @override
  String toString() {
    return 'TimezoneProvider($_factory)';
  }
}

@immutable
abstract class BaseTimezone with EquatableMixin {
  const BaseTimezone(this.id);

  /// A unique identifier for this timezone.
  final String id;

  /// Returns the offset in milliseconds for the timezone at the given
  /// [millisecondsSinceEpoch].
  int offset(int millisecondsSinceEpoch);

  @override
  bool? get stringify => true;
  @override
  List<Object?> get props => [id];
}

class TimezoneNotFoundException implements Exception {
  final String timezoneName;

  TimezoneNotFoundException(this.timezoneName);

  @override
  String toString() =>
      'TimezoneNotFoundException: Timezone "$timezoneName" not found';
}
