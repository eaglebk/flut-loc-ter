import 'package:args/args.dart';
import 'package:logging/logging.dart';

import '../src/get_strings_parse.dart';

import '../src/util/logger.dart';

Future<void> main(List<String> arguments) async {
  final log = Logger('MainClass');

  const excludeConfig = "output-file";
  const srcDir = "source-dir";

  initLogger();

  var parser = ArgParser();

  String? excludeFileConfig;
  String? srcDirectoryPath;

  parser.addOption(excludeConfig,
      abbr: 'e',
      callback: (value) => excludeFileConfig = value,
      help: 'Specify the exclude config file path');

  parser.addOption(srcDir,
      abbr: 's',
      callback: (value) => srcDirectoryPath = value,
      help: 'Specify the src directory');

  parser.parse(arguments);

  final getStringsParse = GetStringsParse();
  await getStringsParse.processExcludeConfig(excludeFileConfig);
  final srcDirectory = getStringsParse.processSrcDirectory(srcDirectoryPath);
  if (srcDirectory != null) {
    final extractedStrings = await getStringsParse.run(srcDirectory);
    log.info(extractedStrings?.map((e) => e.string).toList());
    log.fine(extractedStrings?.length);
  }
}
