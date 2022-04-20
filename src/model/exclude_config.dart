enum PathType { file, directory }

class ExcludeConfig {
  final List<PathEntry> excludeItems;
  final List<String>? excludePrefix;

  ExcludeConfig(this.excludeItems, this.excludePrefix);

  @override
  String toString() =>
      'ExcludeConfig(excludeItems: $excludeItems, excludePrefix: $excludePrefix)';
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
