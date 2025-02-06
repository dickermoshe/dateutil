import 'package:meta/meta.dart';

import 'shared.dart';

@internal
class UnimplementedTimezoneFactory implements TimezoneFactory {
  @override
  void noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'This file is a stub and should never be imported.',
    );
  }
}

/// Default factory for the current platform
@internal
final defaultFactory = UnimplementedTimezoneFactory();
