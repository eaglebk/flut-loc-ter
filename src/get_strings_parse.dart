import 'dart:async';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import 'model/parse_config.dart';
import 'model/extracted_string.dart';
import 'yaml_parse.dart';

class GetStringsParse {
  final log = Logger('GetStringsParse');
  ParseConfig? parseConfig;
  Set<ExtractedString> extractedStrings = {};

  Future processExcludeConfig(fileConfig) async {
    if (fileConfig?.isEmpty ?? true) {
      Logger.root.fine('Configuration exceptions not found');
    } else {
      if (await File(fileConfig!).exists()) {
        final content = File(fileConfig!).readAsStringSync();
        Map<String, dynamic> configMap = {};
        try {
          configMap = loadYamlAsMap(content)!;
        } catch (e) {
          log.shout(e);
        }

        final List<String> excludesPathNames =
            configMap['excludes']['path'].cast<String>();
        final List<String> excludePrefix =
            configMap['excludes']['prefix_excludes'].cast<String>();
        final List<String> rules = configMap['rules'].cast<String>();
        final Map<String, String> contextMapping =
            configMap['context_mapping'].cast<String, String>();

        parseConfig = _processPathsNames(
            excludesPathNames, excludePrefix, rules, contextMapping);
        log.fine(parseConfig);
      } else {
        log.shout(
            'congfig-file argument $fileConfig is not path or not exists');
      }
    }
  }

  Directory? processSrcDirectory(String? srcDirectory) {
    Directory? resultDirectory;
    if (srcDirectory != null) {
      if (FileSystemEntity.isDirectorySync(srcDirectory)) {
        resultDirectory = Directory(srcDirectory);
        // Logger.root.fine(srcDirectory);
      } else {
        Logger.root.shout('$srcDirectory is not directory');
      }
    } else {
      Logger.root.fine('Directory has not specify, use current dir');
      resultDirectory = Directory.current;
    }

    return resultDirectory;
  }

  ParseConfig _processPathsNames(pathNames, List<String> excludePrefix,
      List<String> rules, Map<String, String> contextMapping) {
    final pathEntries = <PathEntry>[];

    for (var p in pathNames) {
      PathType? pathType;
      if (FileSystemEntity.isFileSync(p)) {
        // Logger.root.fine('$p is file');
        pathType = PathType.file;
      } else if (FileSystemEntity.isDirectorySync(p)) {
        // Logger.root.fine('$p is direcory');
        pathType = PathType.directory;
      }

      if (pathType != null) {
        pathEntries.add(PathEntry(p, pathType));
      }
    }

    return ParseConfig(pathEntries, excludePrefix, rules, contextMapping);
  }

  Set<ExtractedString>? run(srcDirectory) {
    if (srcDirectory != null) {
      final paths = Directory(srcDirectory.path).listSync(recursive: true);
      for (var path in paths) {
        if (path is File) {
          if (path.path.endsWith(".dart") && !_checkFileInExcludes(path)) {
            extractedStrings.addAll(_processFile(path));
          }
        } else if (path is Directory) {
          if (!_checkDirectoryInExcludes(path)) {
            run(path);
          }
        }
      }
    }
    return extractedStrings;
  }

  List<ExtractedString> _processFile(File f) {
    return _processString(f.readAsStringSync(), fileName: f.path);
  }

  List<ExtractedString> _processString(String s, {fileName = ""}) {
    CompilationUnit unit =
        parseString(content: s, throwIfDiagnostics: false).unit;
    var extractor = StringExtractor(s, fileName, parseConfig?.excludePrefix,
        parseConfig?.rules, parseConfig?.contextMap);
    unit.visitChildren(extractor);
    return extractor.strings;
  }

  bool _checkFileInExcludes(File f) {
    var result = false;
    if (parseConfig != null) {
      for (var configItems in parseConfig!.excludeItems) {
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
    if (parseConfig != null) {
      for (var configItems in parseConfig!.excludeItems) {
        if ((configItems.path == path.basenameWithoutExtension(d.path)) ||
            configItems.path == d.path.split('\\').last) {
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
  final Map<String, String>? contextMap;
  final List<String>? rules;

  StringExtractor(this.source, this.fileName, this.excludePrefixes, this.rules,
      this.contextMap);

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
      if (ParseConfig.checkStringRulesMatch(node.stringValue, rules)) {
        if (_handleConfigRules(node)) {
          return;
        }
      } else {
        return;
      }

      var lineNo = "\n".allMatches(source.substring(0, node.offset)).length + 1;

      String? context;

      if (contextMap?.isNotEmpty ?? false) {
        for (var entry in contextMap!.entries) {
          if (fileName.contains(entry.key)) {
            context = entry.value;
            break;
          }
        }
      }

      final ExtractedString s = ExtractedString(node.stringValue!, lineNo,
          sourceFile: fileName, context: context);
      strings.add(s);
    }
  }

  bool _handleConfigRules(StringLiteral node) {
    Token? here = node.parent?.beginToken;

    if ((excludePrefixes?.contains(here?.type.lexeme) ?? false) ||
        (excludePrefixes?.contains(node.stringValue) ?? false) ||
        (node.stringValue?.trim().isEmpty ?? false)) {
      return true;
    }

    return false;
  }
}
