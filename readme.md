# tz

`tz` is a powerful Dart package designed to simplify the calculate time differences, and manage daylight saving time changes.

## Features

- **Timezone Support**: Easily convert between different timezones.
- **Offset Handling**: Manage and apply time offsets to datetime objects.

## Installation

```bash
dart pub add tz
```

## Usage

```dart
import 'package:tz/tz.dart';

void main() {
  final timezone = Timezone('America/New_York');
  final now = DateTime.timestamp();
  final offset = timezone.offset(now);
  final time = now.add(Duration(milliseconds: offset));
  print("It's $time in New York.");
}
```

## Contributing

1. Install Node 20 (for compiling timezone data)
2. Install Java 11 (for tests)
3. Run `dart pub get` to install dependencies
4. Run `dart run ./tool/prepare.dart` to generate the timezone data