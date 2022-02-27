import 'ast.dart';
import 'document.dart';

/// Maintains the internal state needed to parse a series of lines into blocks
/// of Markdown suitable for further inline parsing.
class BlockParser {
  final List<String> lines;

  /// The Markdown document this parser is parsing.
  final Document document;

  /// The enabled block syntaxes.
  ///
  /// To turn a series of lines into blocks, each of these will be tried in
  /// turn. Order matters here.
  final List<BlockSyntax> blockSyntaxes = [];

  /// Index of the current line.
  int _pos = 0;

  /// Whether the parser has encountered a blank line between two block-level
  /// elements.
  bool encounteredBlankLine = false;

  BlockParser(this.lines, this.document) {
    blockSyntaxes.addAll(document.blockSyntaxes);
  }

  /// Gets the current line.
  String get current => lines[_pos];

  bool get isDone => _pos >= lines.length;

  /// Gets the line after the current one or `null` if there is none.
  String? get next {
    // Don't read past the end.
    if (_pos >= lines.length - 1) return null;
    return lines[_pos + 1];
  }

  void advance() {
    _pos++;
  }

  /// Gets whether or not the current line matches the given pattern.
  bool matches(RegExp regex) {
    if (isDone) return false;
    return regex.hasMatch(current);
  }

  /// Gets whether or not the next line matches the given pattern.
  bool matchesNext(RegExp regex) {
    if (next == null) return false;
    return regex.hasMatch(next!);
  }

  List<MarkedNode> parseLines() {
    final blocks = <MarkedNode>[];
    while (!isDone) {
      for (final syntax in blockSyntaxes) {
        if (syntax.canParse(this)) {
          final block = syntax.parse(this);
          if (block != null) blocks.add(block);
          break;
        }
      }
    }

    return blocks;
  }

  /// Gets the line that is [linesAhead] lines ahead of the current one, or
  /// `null` if there is none.
  ///
  /// `peek(0)` is equivalent to [current].
  ///
  /// `peek(1)` is equivalent to [next].
  String? peek(int linesAhead) {
    if (linesAhead < 0) {
      throw ArgumentError('Invalid linesAhead: $linesAhead; must be >= 0.');
    }
    // Don't read past the end.
    if (_pos >= lines.length - linesAhead) return null;
    return lines[_pos + linesAhead];
  }
}

abstract class BlockSyntax {
  const BlockSyntax();

  /// Gets the regex used to identify the beginning of this block, if any.
  RegExp get pattern;

  bool canEndBlock(BlockParser parser) => true;

  bool canParse(BlockParser parser) {
    return pattern.hasMatch(parser.current);
  }

  MarkedNode? parse(BlockParser parser);

  List<String?> parseChildLines(BlockParser parser) {
    // Grab all of the lines that form the block element.
    final childLines = <String?>[];

    while (!parser.isDone) {
      final match = pattern.firstMatch(parser.current);
      if (match == null) break;
      childLines.add(match[1]);
      parser.advance();
    }

    return childLines;
  }

  /// Generates a valid HTML anchor from the inner text of [element].
  static String generateAnchorHash(MarkedElement element) => element.children!.first.textContent
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9 _-]'), '')
      .replaceAll(RegExp(r'\s'), '-');

  /// Gets whether or not [parser]'s current line should end the previous block.
  static bool isAtBlockEnd(BlockParser parser) {
    if (parser.isDone) return true;
    return parser.blockSyntaxes.any((s) => s.canParse(parser) && s.canEndBlock(parser));
  }
}
