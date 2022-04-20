import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:logging/logging.dart';

import 'model/exclude_config.dart';
import 'model/extracted_string.dart';
import 'yaml_parse.dart';

class GetStringsParse {
  final log = Logger('GetStringsParse');
  ExcludeConfig? excludeConfig;

  Future processExcludeConfig(excludeFileConfig) async {
    if (excludeFileConfig?.isEmpty ?? true) {
      Logger.root.fine('Сonfiguration exceptions not found');
    } else {
      if (await File(excludeFileConfig!).exists()) {
        final content = File(excludeFileConfig!).readAsStringSync();
        Map<String, dynamic> configMap = {};
        try {
          configMap = loadYamlAsMap(content)!;
        } catch (e) {
          log.shout(e);
        }

        final List<String> pathNames =
            configMap['excludes']['path'].cast<String>();
        final List<String> excludePrefix =
            configMap['excludes']['prefix_excludes'].cast<String>();

        excludeConfig = _processPathsNames(pathNames, excludePrefix);
        log.fine(excludeConfig);
      } else {
        log.shout(
            'exclude-congfig-file agrument $excludeFileConfig is not path or not exists');
      }
    }
  }

  Directory? processSrcDirectory(String? srcDirectory) {
    Directory? resultDirectory;
    if (srcDirectory != null) {
      if (FileSystemEntity.isDirectorySync(srcDirectory)) {
        resultDirectory = Directory(srcDirectory);
        Logger.root.fine(srcDirectory);
      } else {
        Logger.root.shout('$srcDirectory is not directory');
      }
    } else {
      Logger.root.fine('Directory has not specify, use current dir');
      resultDirectory = Directory.current;
    }

    return resultDirectory;
  }

  ExcludeConfig _processPathsNames(pathNames, List<String> excludePrefix) {
    final pathEntries = <PathEntry>[];

    for (var p in pathNames) {
      PathType? pathType;
      if (FileSystemEntity.isFileSync(p)) {
        Logger.root.fine('$p is file');
        pathType = PathType.file;
      } else if (FileSystemEntity.isDirectorySync(p)) {
        Logger.root.fine('$p is direcory');
        pathType = PathType.directory;
      }

      if (pathType != null) {
        pathEntries.add(PathEntry(p, pathType));
      }
    }

    return ExcludeConfig(pathEntries, excludePrefix);
  }

  List<ExtractedString>? run(srcDirectory) {
    List<ExtractedString>? extractedStrings;
    if (srcDirectory != null) {
      final paths = Directory(srcDirectory.path).listSync(recursive: true);
      log.info(Directory(paths.join('\n')));

      Stream<File> scannedFiles =
          scanningFilesWithAsyncRecursive(Directory(srcDirectory.path));

      scannedFiles.listen((File f) {
        if (f.path.endsWith(".dart") && !_checkFileInExcludes(f)) {
          extractedStrings = _processFile(f);
        }
      });
    }
    return extractedStrings;
  }

  Stream<File> scanningFilesWithAsyncRecursive(Directory dir) async* {
    var dirList = dir.list();
    await for (final FileSystemEntity entity in dirList) {
      if (entity is File) {
        yield entity;
      } else if (entity is Directory) {
        if (!_checkDirectoryInExcludes(entity)) {
          yield* scanningFilesWithAsyncRecursive(Directory(entity.path));
        }
      }
    }
  }

  List<ExtractedString> _processFile(File f) {
    return _processString(f.readAsStringSync(), fileName: f.path);
  }

  List<ExtractedString> _processString(String s, {fileName = ""}) {
    CompilationUnit unit =
        parseString(content: s, throwIfDiagnostics: false).unit;
    var extractor = StringExtractor(s, fileName, excludeConfig?.excludePrefix);
    unit.visitChildren(extractor);
    return extractor.strings;
  }

  bool _checkFileInExcludes(File f) {
    var result = false;
    if (excludeConfig != null) {
      for (var configItems in excludeConfig!.excludeItems) {
        if (configItems.path == f.path) {
          result = true;
          break;
        }
      }
    }
    return result;
  }

  bool _checkDirectoryInExcludes(Directory d) {
    var result = false;
    if (excludeConfig != null) {
      for (var configItems in excludeConfig!.excludeItems) {
        if (configItems.path.contains(d.path)) {
          result = true;
          break;
        }
      }
    }
    return result;
  }
}

class StringExtractor extends UnifyingAstVisitor<void> {
  List<ExtractedString> strings = [];
  final String source;
  final String fileName;
  final List<String>? excludePrefixes;

  StringExtractor(this.source, this.fileName, this.excludePrefixes);

  @override
  void visitNode(AstNode node) {
    return super.visitNode(node);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _handleString(node);
    return super.visitSimpleStringLiteral(node);
  }

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    _handleString(node);
  }

  void _handleString(StringLiteral node) {
    if (node.stringValue != null) {
      if (_handlePrefixRules(node)) {
        return;
      }

      var lineNo = "\n".allMatches(source.substring(0, node.offset)).length + 1;
      final ExtractedString s =
          ExtractedString(node.stringValue!, lineNo, sourceFile: fileName);
      strings.add(s);
    }
  }

  bool _handlePrefixRules(StringLiteral node) {
    Token? here = node.parent?.beginToken;

    if ((excludePrefixes?.contains(here?.type.lexeme) ?? false) ||
        (excludePrefixes?.contains(node.stringValue) ?? false)) {
      return true;
    }

    return false;
  }
}
