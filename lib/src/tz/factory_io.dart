import 'dart:io';

import 'package:meta/meta.dart';

import 'android/android_tz.dart';
import 'shared.dart';
import 'universal/universal_tz.dart';

@internal
// ignore: public_member_api_docs
final TimezoneFactory defaultFactory =
    Platform.isAndroid ? JavaTimezoneFactory() : UniversalTimezoneFactory();
