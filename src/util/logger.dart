import 'package:logging/logging.dart';

import 'text_util.dart';

void initLogger() {
  Logger.root.level = Level.ALL;
  final f = 'Строка которая требует перевода';
  Logger.root.onRecord.listen((record) {
    print(colorizeText(
        '${record.level.name}: ${record.time}: ${record.message}',
        record.level));
  });
}
