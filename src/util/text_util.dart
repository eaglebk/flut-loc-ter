import 'package:colorize/colorize.dart';
import 'package:logging/logging.dart';

String colorizeText(String srcText, [Level level = Level.FINE]) {
  Colorize? colorize;
  if (level == Level.FINE) {
    colorize = Colorize(srcText)..green();
  } else if (level == Level.SHOUT) {
    colorize = Colorize(srcText)..red();
  } else if (level == Level.WARNING) {
    colorize = Colorize(srcText)..blue();
  }

  return colorize?.initial ?? srcText;
}
