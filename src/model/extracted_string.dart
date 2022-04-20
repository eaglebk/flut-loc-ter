import 'package:equatable/equatable.dart';

class ExtractedString extends Equatable {
  final String string;
  final int lineNumber;
  final String sourceFile;

  ExtractedString(this.string, this.lineNumber, {this.sourceFile = ""});

  @override
  List<Object> get props => [string, sourceFile, lineNumber];

  @override
  String toString() =>
      'ExtractedString(\n\tstring: $string,\n\t lineNumber: $lineNumber,\n\t sourceFile: $sourceFile)\n';
}
