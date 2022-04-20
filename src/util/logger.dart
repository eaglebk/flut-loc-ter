import 'package:logging/logging.dart';

import 'text_util.dart';

void initLogger() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print(colorizeText('===', record.level));

    print(colorizeText(
        '${record.level.name}: ${record.time}: ${record.message}',
        record.level));
    print(colorizeText('===', record.level));
  });
}
