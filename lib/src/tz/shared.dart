// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
abstract class TimezoneFactory<TZ extends BaseTimezone> {
  String get name;
  final Map<String, TZ> cachedTimezones = {};
  Set<String> listTimezones();
  TZ getTimezone(String id);
}

/// Base class for all timezones providers.
@immutable
class TimezoneProvider<TZ extends BaseTimezone,
    TzFactory extends TimezoneFactory<TZ>> {
  final TzFactory $factory;
  const TimezoneProvider(this.$factory);

  TZ getTimezone(String id) {
    /// If the timezone is already cached, return it.
    if ($factory.cachedTimezones.containsKey(id)) {
      return $factory.cachedTimezones[id]!;
    }

    /// Otherwise, fetch the timezone and cache it.
    final result = $factory.getTimezone(id);
    $factory.cachedTimezones[id] = result;
    return result;
  }

  Set<String> listTimezones() => $factory.listTimezones();

  @override
  String toString() {
    return 'TimezoneProvider(${this.$factory})';
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
