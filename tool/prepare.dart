// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:dateutil/src/tz/universal/universal_tz.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) async {
  final javaHome = Platform.environment['JAVA_HOME'];
  if (javaHome == null) {
    print('JAVA_HOME is not set');
    exit(1);
  }

  if (Platform.isWindows) {
    final result = Process.runSync('which', ['jvm.dll'], runInShell: true);
    if (result.exitCode != 0) {
      print(r'Make sure that $JAVA_HOME\bin\server\jvm.dll is in your PATH');
      exit(1);
    }
  }

  final javaDir = Directory(javaHome);
  if (!javaDir.existsSync()) {
    print('$javaHome is not am existing directory');
    exit(1);
  }
  if (p.basename(Directory.current.path) != 'dateutil') {
    print('This script should be run from the root of the dateutil project');
    exit(1);
  }
  final javaSrcOutputDir = p.join(javaDir.path, 'lib', 'src');
  if (!args.contains('--skip-java-bindings')) {
    final javaArchive = p.join(javaDir.path, 'lib', 'src.zip');
    if (!File(javaArchive).existsSync()) {
      print('Java archive not found at $javaArchive');
      exit(1);
    }
    if (!Directory(javaSrcOutputDir).existsSync()) {
      print('Extracting Java archive to $javaSrcOutputDir');
      await extractFileToDisk(javaArchive, javaSrcOutputDir);
    }
    final generateBindings = Process.runSync('dart', [
      'run',
      'jnigen',
      '--config',
      'jnigen.yaml',
      '-Dsource_path=${p.canonicalize(p.join(javaSrcOutputDir, 'java.base'))}',
    ]);

    if (generateBindings.exitCode != 0) {
      print('Failed to generate JNI bindings');
      print(generateBindings.stdout);
      print(generateBindings.stderr);
      exit(1);
    }
  }

  final nodeCheckResult = Process.runSync('node', ['-v'], runInShell: true);
  if (nodeCheckResult.exitCode != 0) {
    print('Node.js is not installed');
    print(nodeCheckResult.stdout);
    print(nodeCheckResult.stderr);
    exit(1);
  }
  final npmCheckResult = Process.runSync('npm', ['-v'], runInShell: true);
  if (npmCheckResult.exitCode != 0) {
    print('npm is not installed');
    print(npmCheckResult.stdout);
    print(npmCheckResult.stderr);
    exit(1);
  }
  final installTubular = Process.runSync(
    'npm',
    ['install', '-g', '@tubular/time-tzdb@1'],
    runInShell: true,
  );
  if (installTubular.exitCode != 0) {
    print('Failed to install @tubular/time-tzdb');
    print(installTubular.stdout);
    print(installTubular.stderr);
    exit(1);
  }
  final timezoneDatabaseLocation = p.join(
    Directory.current.path,
    'lib',
    'src',
    'tz',
    'universal',
    'timezone.json',
  );
  final generateTubular = Process.runSync(
    'npx',
    ['tzc', '--large', timezoneDatabaseLocation, '-o'],
    runInShell: true,
  );
  if (generateTubular.exitCode != 0) {
    print('Failed to generate Tubular timezone database');
    print(generateTubular.stdout);
    print(generateTubular.stderr);
    exit(1);
  }

  final tzDb = jsonDecode(File(timezoneDatabaseLocation).readAsStringSync())
      as Map<String, dynamic>;
  if (tzDb['version'] != '2025a') {
    print('The timezone database is not up to date');
    exit(1);
  }
  final timeZoneNames =
      // ignore: invalid_use_of_visible_for_testing_member
      tzDb.keys.where((element) => !isIgnoredKey(element));
  File(
    p.join(
      Directory.current.path,
      'lib',
      'src',
      'tz',
      'universal',
      'timezone_names.g.dart',
    ),
  ).writeAsStringSync(
    """
import 'package:meta/meta.dart';
///A list of all the valid timezones that dateutil can parse across all platforms
@internal
const timezoneNames = ${timeZoneNames.map((e) => "'$e'").toSet()};""",
  );

  final pubGetResult =
      Process.runSync('dart', ['pub', 'get'], runInShell: true);
  if (pubGetResult.exitCode != 0) {
    print('Failed to run `dart pub get`');
    print(pubGetResult.stdout);
    print(pubGetResult.stderr);
    exit(1);
  }
  final buildResult = Process.runSync(
    'dart',
    ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
    runInShell: true,
  );
  if (buildResult.exitCode != 0) {
    print(
      'Failed to run `dart run build_runner build --delete-conflicting-outputs`',
    );
    print(buildResult.stdout);
    print(buildResult.stderr);
    exit(1);
  }
  final setupJni = Process.runSync(
    'dart',
    ['run', 'jni:setup'],
    runInShell: true,
  );
  if (setupJni.exitCode != 0) {
    print('Failed to run `dart run jni:setup`');
    print(setupJni.stdout);
    print(setupJni.stderr);
    exit(1);
  }

  final updateTzdb = Process.runSync(
    'java',
    ['-jar', 'tool/tzupdater.jar', '-f'],
    runInShell: true,
  );
  if (updateTzdb.exitCode != 0) {
    print('Failed to update the timezone database');
    print(updateTzdb.stdout);
    print(updateTzdb.stderr);
    exit(1);
  }

  print('Success');
}
