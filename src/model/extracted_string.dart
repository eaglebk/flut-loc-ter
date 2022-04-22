import 'dart:convert';

import 'package:equatable/equatable.dart';

class ExtractedString extends Equatable {
  final String string;
  final int lineNumber;
  final String sourceFile;
  final String? context;

  ExtractedString(this.string, this.lineNumber,
      {this.sourceFile = "", this.context});

  @override
  List<Object> get props => [string];

  @override
  String toString() =>
      'ExtractedString(\n\tstring: $string,\n\t lineNumber: $lineNumber,\n\t sourceFile: $sourceFile),\n\tcontext: $context)\n';

  Map<String, dynamic> toMap() {
    return {
      'name': string,
      'line_no': lineNumber,
      'file': sourceFile,
      'context': context,
    };
  }

  factory ExtractedString.fromMap(Map<String, dynamic> map) {
    return ExtractedString(
      map['name'] ?? '',
      map['line_no']?.toInt() ?? 0,
      sourceFile: map['file'],
      context: map['context'],
    );
  }

  String toJson() => json.encode(toMap());

  factory ExtractedString.fromJson(String source) =>
      ExtractedString.fromMap(json.decode(source));
}
