enum PathType { file, directory }

class AllRules {
  static const cyrillicPattern = r'[ЁёА-я].*';

  static Map<String, String> get rulesMap => {'ru_only': cyrillicPattern};
}

class ParseConfig {
  final List<PathEntry> excludeItems;
  final List<String>? excludePrefix;
  final List<String>? rules;
  final Map<String, String>? contextMap;

  ParseConfig(
      this.excludeItems, this.excludePrefix, this.rules, this.contextMap);

  static bool checkStringRulesMatch(String? text, List<String>? configRules) {
    if (text != null) {
      if (configRules?.isEmpty ?? true) {
        return true;
      }

      for (var configRule in configRules!) {
        for (var globalRule in AllRules.rulesMap.entries) {
          if (configRule == globalRule.key) {
            RegExp regexp = RegExp(globalRule.value);
            bool hasMatch = regexp.hasMatch(text);
            if (hasMatch) {
              return true;
            }
          }
        }
      }
    }

    return false;
  }

  @override
  String toString() =>
      'ExcludeConfig(excludeItems: $excludeItems, excludePrefix: $excludePrefix, rules: $rules)';
}

class PathEntry {
  final String path;
  final PathType type;

  PathEntry(this.path, this.type);

  get fileIsDart => path.split('.').last == 'dart';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PathEntry && other.path == path && other.type == type;
  }

  @override
  int get hashCode => path.hashCode ^ type.hashCode;

  @override
  String toString() => 'PathEntry(path: $path, type: $type)';
}
