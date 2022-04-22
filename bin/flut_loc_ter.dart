import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';

import '../src/get_strings_parse.dart';

import '../src/service/db/sqllite_db.dart';
import '../src/util/banner.dart';
import '../src/util/logger.dart';

Future<void> main(List<String> arguments) async {
  final log = Logger('MainClass');
  var stopWatch = Stopwatch()
    ..reset()
    ..start();

  const config = "config-file";
  const srcDir = "source-dir";
  const help = "help";
  const exportSql = "export-sql";

  initLogger();

  var parser = ArgParser();

  String? fileConfig;
  String? srcDirectoryPath;
  bool? isHelpCmd;
  bool exportToSql = true;

  parser.addOption(config,
      abbr: 'c',
      callback: (value) => fileConfig = value,
      help: 'Specify the config file path');

  parser.addOption(srcDir,
      abbr: 's',
      callback: (value) => srcDirectoryPath = value,
      help: 'Specify the src directory');

  parser.addFlag(exportSql,
      abbr: 'i',
      callback: (value) => exportToSql = false,
      help: 'Ignore sqllite export');

  parser.addFlag(help,
      abbr: 'h',
      callback: (value) => isHelpCmd = value,
      help: 'Print help for this command');

  parser.parse(arguments);

  if ((arguments.isEmpty) || (isHelpCmd ?? false)) {
    print(banner);
    print('Usage:');
    print(parser.usage);
    exit(0);
  }

  final getStringsParse = GetStringsParse();
  await getStringsParse.processExcludeConfig(fileConfig);
  final srcDirectory = getStringsParse.processSrcDirectory(srcDirectoryPath);
  if (srcDirectory != null) {
    final extractedStrings = getStringsParse.run(srcDirectory);

    if (extractedStrings?.isEmpty ?? true) {
      log.fine('Strings not found!!!');
    } else {
      log.info(extractedStrings
          ?.map((e) => '${e.string} -> ${e.sourceFile}  [${e.lineNumber}]')
          .toList()
          .join('\n'));
      log.fine(extractedStrings?.length);
    }

    stopWatch.stop();
    log.info('Elapsed time: ${stopWatch.elapsed}');

    if (exportToSql) {
      final db = SQLiteDB()..init();
      db.populateData(extractedStrings);
    }
  }
}
