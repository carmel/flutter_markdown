import 'package:charcode/charcode.dart';

import 'ast.dart';
import 'block_parser.dart';
import 'document.dart';
import 'util.dart';

/// The line contains only whitespace or is empty.
final _emptyPattern = RegExp(r'^(?:[ \t]*)$');

/// A series of `=` or `-` (on the next line) define setext-style headers.
final _setextPattern = RegExp(r'^[ ]{0,3}(=+|-+)\s*$');

/// Leading (and trailing) `#` define atx-style headers.
///
/// Starts with 1-6 unescaped `#` characters which must not be followed by a
/// non-space character. Line may end with any number of `#` characters,.
final _headerPattern = RegExp(r'^ {0,3}(#{1,6})[ \x09\x0b\x0c](.*?)#*$');

final _imgPattern = RegExp(r'^\!\[(\S*?)\]\((\S+?)\)$');

/// The line starts with `>` with one optional space after.
final _blockquotePattern = RegExp(r'^[ ]{0,3}>[ ]?(.*)$');

/// A line indented four spaces. Used for code blocks and lists.
final _indentPattern = RegExp(r'^(?:    | {0,3}\t)(.*)$');

/// Fenced code block.
final _codeFencePattern = RegExp(r'^[ ]{0,3}(`{3,}|~{3,})(.*)$');

/// Three or more hyphens, asterisks or underscores by themselves. Note that
/// a line like `----` is valid as both HR and SETEXT. In case of a tie,
/// SETEXT should win.
final _hrPattern = RegExp(r'^ {0,3}([-*_])[ \t]*\1[ \t]*\1(?:\1|[ \t])*$');

/// A line starting with one of these markers: `-`, `*`, `+`. May have up to
/// three leading spaces before the marker and any number of spaces or tabs
/// after.
///
/// Contains a dummy group at [2], so that the groups in [_ulPattern] and
/// [_olPattern] match up; in both, [2] is the length of the number that begins
/// the list marker.
final _ulPattern = RegExp(r'^([ ]{0,3})()([*+-])(([ \t])([ \t]*)(.*))?$');

/// A line starting with a number like `123.`. May have up to three leading
/// spaces before the marker and any number of spaces or tabs after.
final _olPattern = RegExp(r'^([ ]{0,3})(\d{1,9})([\.)])(([ \t])([ \t]*)(.*))?$');

/// A pattern which should never be used. It just satisfies non-nullability of
/// pattern fields.
final _dummyPattern = RegExp('');

class EmptyBlockSyntax extends BlockSyntax {
  @override
  RegExp get pattern => _emptyPattern;

  const EmptyBlockSyntax();

  @override
  MarkedNode? parse(BlockParser parser) {
    parser.encounteredBlankLine = true;
    parser.advance();

    // Don't actually emit anything.
    return null;
  }
}

/// Parses setext-style headers.
class SetextHeaderSyntax extends BlockSyntax {
  @override
  RegExp get pattern => _dummyPattern;

  const SetextHeaderSyntax();

  @override
  bool canParse(BlockParser parser) {
    if (!_interperableAsParagraph(parser.current)) return false;
    var i = 1;
    while (true) {
      final nextLine = parser.peek(i);
      if (nextLine == null) {
        // We never reached an underline.
        return false;
      }
      if (_setextPattern.hasMatch(nextLine)) {
        return true;
      }
      // Ensure that we're still in something like paragraph text.
      if (!_interperableAsParagraph(nextLine)) {
        return false;
      }
      i++;
    }
  }

  @override
  MarkedNode parse(BlockParser parser) {
    final lines = <String>[];
    String? tag;
    while (!parser.isDone) {
      final match = _setextPattern.firstMatch(parser.current);
      if (match == null) {
        // More text.
        lines.add(parser.current);
        parser.advance();
        continue;
      } else {
        // The underline.
        tag = (match[1]![0] == '=') ? 'h1' : 'h2';
        parser.advance();
        break;
      }
    }

    final contents = UnparsedContent(lines.join('\n').trimRight());

    return MarkedElement(tag!, [contents]);
  }

  bool _interperableAsParagraph(String line) => !(_indentPattern.hasMatch(line) ||
      _codeFencePattern.hasMatch(line) ||
      _headerPattern.hasMatch(line) ||
      _blockquotePattern.hasMatch(line) ||
      _hrPattern.hasMatch(line) ||
      _ulPattern.hasMatch(line) ||
      _olPattern.hasMatch(line) ||
      _emptyPattern.hasMatch(line));
}

/// Parses setext-style headers, and adds generated IDs to the generated
/// elements.
class SetextHeaderWithIdSyntax extends SetextHeaderSyntax {
  const SetextHeaderWithIdSyntax();

  @override
  MarkedNode parse(BlockParser parser) {
    final element = super.parse(parser) as MarkedElement;
    element.generatedId = BlockSyntax.generateAnchorHash(element);
    return element;
  }
}

class ImageSyntax extends BlockSyntax {
  @override
  RegExp get pattern => _imgPattern;

  const ImageSyntax();

  @override
  MarkedNode parse(BlockParser parser) {
    final match = pattern.firstMatch(parser.current)!;
    parser.advance();

    final e = MarkedElement('img', null);
    e.attributes['url'] = match[2]!;

    if (match[1] != '') {
      e.attributes['alt'] = match[1]!;
    }
    return e;
  }
}

/// Parses atx-style headers: `## Header ##`.
class HeaderSyntax extends BlockSyntax {
  @override
  RegExp get pattern => _headerPattern;

  const HeaderSyntax();

  @override
  MarkedNode parse(BlockParser parser) {
    final match = pattern.firstMatch(parser.current)!;
    parser.advance();
    final level = match[1]!.length;
    final contents = UnparsedContent(match[2]!.trim());
    return MarkedElement('h$level', [contents]);
  }
}

/// Parses atx-style headers, and adds generated IDs to the generated elements.
class HeaderWithIdSyntax extends HeaderSyntax {
  const HeaderWithIdSyntax();

  @override
  MarkedNode parse(BlockParser parser) {
    final element = super.parse(parser) as MarkedElement;
    element.generatedId = BlockSyntax.generateAnchorHash(element);
    return element;
  }
}

/// Parses email-style blockquotes: `> quote`.
class BlockquoteSyntax extends BlockSyntax {
  @override
  RegExp get pattern => _blockquotePattern;

  const BlockquoteSyntax();

  @override
  List<String> parseChildLines(BlockParser parser) {
    // Grab all of the lines that form the blockquote, stripping off the ">".
    final childLines = <String>[];

    while (!parser.isDone) {
      final match = pattern.firstMatch(parser.current);
      if (match != null) {
        childLines.add(match[1]!);
        parser.advance();
        continue;
      }

      // A paragraph continuation is OK. This is content that cannot be parsed
      // as any other syntax except Paragraph, and it doesn't match the bar in
      // a Setext header.
      if (parser.blockSyntaxes.firstWhere((s) => s.canParse(parser)) is ParagraphSyntax) {
        childLines.add(parser.current);
        parser.advance();
      } else {
        break;
      }
    }

    return childLines;
  }

  @override
  MarkedNode parse(BlockParser parser) {
    final childLines = parseChildLines(parser);

    // Recursively parse the contents of the blockquote.
    final children = BlockParser(childLines, parser.document).parseLines();

    return MarkedElement('blockquote', children);
  }
}

/// Parses preformatted code blocks that are indented four spaces.
class CodeBlockSyntax extends BlockSyntax {
  @override
  RegExp get pattern => _indentPattern;

  @override
  bool canEndBlock(BlockParser parser) => false;

  const CodeBlockSyntax();

  @override
  List<String?> parseChildLines(BlockParser parser) {
    final childLines = <String?>[];

    while (!parser.isDone) {
      final match = pattern.firstMatch(parser.current);
      if (match != null) {
        childLines.add(match[1]);
        parser.advance();
      } else {
        // If there's a codeblock, then a newline, then a codeblock, keep the
        // code blocks together.
        final nextMatch = parser.next != null ? pattern.firstMatch(parser.next!) : null;
        if (parser.current.trim() == '' && nextMatch != null) {
          childLines.add('');
          childLines.add(nextMatch[1]);
          parser.advance();
          parser.advance();
        } else {
          break;
        }
      }
    }
    return childLines;
  }

  @override
  MarkedNode parse(BlockParser parser) {
    final childLines = parseChildLines(parser);

    // The Markdown tests expect a trailing newline.
    childLines.add('');

    final content = childLines.join('\n');

    return MarkedElement('pre', [MarkedElement.text('code', content)]);
  }
}

/// Parses preformatted code blocks between two ~~~ or ``` sequences.
///
/// See the CommonMark spec: https://spec.commonmark.org/0.29/#fenced-code-blocks
class FencedCodeBlockSyntax extends BlockSyntax {
  @override
  RegExp get pattern => _codeFencePattern;

  const FencedCodeBlockSyntax();

  @override
  bool canParse(BlockParser parser) {
    final match = pattern.firstMatch(parser.current);
    if (match == null) return false;
    final codeFence = match.group(1)!;
    final infoString = match.group(2);
    // From the CommonMark spec:
    //
    // > If the info string comes after a backtick fence, it may not contain
    // > any backtick characters.
    return (codeFence.codeUnitAt(0) != $backquote || !infoString!.codeUnits.contains($backquote));
  }

  @override
  List<String> parseChildLines(BlockParser parser, [String? endBlock]) {
    endBlock ??= '';

    final childLines = <String>[];
    parser.advance();

    while (!parser.isDone) {
      final match = pattern.firstMatch(parser.current);
      if (match == null || !match[1]!.startsWith(endBlock)) {
        childLines.add(parser.current);
        parser.advance();
      } else {
        parser.advance();
        break;
      }
    }

    return childLines;
  }

  @override
  MarkedNode parse(BlockParser parser) {
    // Get the syntax identifier, if there is one.
    final match = pattern.firstMatch(parser.current)!;
    final endBlock = match.group(1);
    var infoString = match.group(2)!;

    final childLines = parseChildLines(parser, endBlock);

    // The Markdown tests expect a trailing newline.
    childLines.add('');

    final text = childLines.join('\n');
    final code = MarkedElement.text('code', text);

    // the info-string should be trimmed
    // http://spec.commonmark.org/0.22/#example-100
    infoString = infoString.trim();
    if (infoString.isNotEmpty) {
      // only use the first word in the syntax
      // http://spec.commonmark.org/0.22/#example-100
      final firstSpace = infoString.indexOf(' ');
      if (firstSpace >= 0) {
        infoString = infoString.substring(0, firstSpace);
      }
      code.attributes['class'] = 'language-$infoString';
    }

    final element = MarkedElement('pre', [code]);

    return element;
  }
}

/// Parses horizontal rules like `---`, `_ _ _`, `*  *  *`, etc.
class HorizontalRuleSyntax extends BlockSyntax {
  @override
  RegExp get pattern => _hrPattern;

  const HorizontalRuleSyntax();

  @override
  MarkedNode parse(BlockParser parser) {
    parser.advance();
    return MarkedElement.empty('hr');
  }
}

class ListItem {
  bool forceBlock = false;
  final List<String> lines;
  final String index;

  ListItem(this.lines, this.index);
}

/// Base class for both ordered and unordered lists.
abstract class ListSyntax extends BlockSyntax {
  @override
  bool canEndBlock(BlockParser parser) {
    // An empty list cannot interrupt a paragraph. See
    // https://spec.commonmark.org/0.29/#example-255.
    // Ideally, [BlockSyntax.canEndBlock] should be changed to be a method
    // which accepts a [BlockParser], but this would be a breaking change,
    // so we're going with this temporarily.
    final match = pattern.firstMatch(parser.current)!;
    // The seventh group, in both [_olPattern] and [_ulPattern] is the text
    // after the delimiter.
    return match[7]?.isNotEmpty ?? false;
  }

  String get listTag;

  const ListSyntax();

  /// A list of patterns that can start a valid block within a list item.
  static final blocksInList = [_blockquotePattern, _headerPattern, _hrPattern, _indentPattern, _ulPattern, _olPattern];

  static final _whitespaceRe = RegExp('[ \t]*');

  @override
  MarkedNode parse(BlockParser parser) {
    final items = <ListItem>[];
    var childLines = <String>[];

    void endItem(String childIndex) {
      if (childLines.isNotEmpty) {
        items.add(ListItem(childLines, childIndex));
        childLines = <String>[];
      }
    }

    Match? match;
    bool tryMatch(RegExp pattern) {
      match = pattern.firstMatch(parser.current);
      return match != null;
    }

    String? listMarker;
    String? indent;

    while (!parser.isDone) {
      final leadingSpace = _whitespaceRe.matchAsPrefix(parser.current)!.group(0)!;
      final leadingExpandedTabLength = _expandedTabLength(leadingSpace);

      if (tryMatch(_emptyPattern)) {
        if (_emptyPattern.hasMatch(parser.next ?? '')) {
          // Two blank lines ends a list.
          break;
        }
        // Add a blank line to the current list item.
        childLines.add('');
      } else if (indent != null && indent.length <= leadingExpandedTabLength) {
        // Strip off indent and add to current item.
        final line = parser.current.replaceFirst(leadingSpace, ' ' * leadingExpandedTabLength).replaceFirst(indent, '');
        childLines.add(line);
      } else if (tryMatch(_hrPattern)) {
        // Horizontal rule takes precedence to a new list item.
        break;
      } else if (tryMatch(_ulPattern) || tryMatch(_olPattern)) {
        final precedingWhitespace = match![1]!;
        final digits = match![2] ?? '';
        final marker = match![3]!;
        final firstWhitespace = match![5] ?? '';
        final restWhitespace = match![6] ?? '';
        final content = match![7] ?? '';
        final isBlank = content.isEmpty;
        if (listMarker != null && listMarker != marker) {
          // Changing the bullet or ordered list delimiter starts a new list.
          break;
        }
        listMarker = marker;
        final markerAsSpaces = ' ' * (digits.length + marker.length);
        if (isBlank) {
          // See http://spec.commonmark.org/0.28/#list-items under "3. Item
          // starting with a blank line."
          //
          // If the list item starts with a blank line, the final piece of the
          // indentation is just a single space.
          indent = precedingWhitespace + markerAsSpaces + ' ';
        } else if (restWhitespace.length >= 4) {
          // See http://spec.commonmark.org/0.28/#list-items under "2. Item
          // starting with indented code."
          //
          // If the list item starts with indented code, we need to _not_ count
          // any indentation past the required whitespace character.
          indent = precedingWhitespace + markerAsSpaces + firstWhitespace;
        } else {
          indent = precedingWhitespace + markerAsSpaces + firstWhitespace + restWhitespace;
        }

        childLines.add(restWhitespace + content);
        endItem(digits);
      } else if (BlockSyntax.isAtBlockEnd(parser)) {
        // Done with the list.
        break;
      } else {
        // If the previous item is a blank line, this means we're done with the
        // list and are starting a new top-level paragraph.
        if ((childLines.isNotEmpty) && (childLines.last == '')) {
          parser.encounteredBlankLine = true;
          break;
        }

        // Anything else is paragraph continuation text.
        childLines.add(parser.current);
      }
      parser.advance();
    }

    // endItem('#');
    final itemNodes = <MarkedElement>[];

    items.forEach(_removeLeadingEmptyLine);
    final anyEmptyLines = _removeTrailingEmptyLines(items);
    var anyEmptyLinesBetweenBlocks = false;

    if (listTag == 'ol') {
      for (final item in items) {
        final itemParser = BlockParser(item.lines, parser.document);
        itemNodes.add(MarkedElement('li', itemParser.parseLines())..attributes['index'] = item.index);
        anyEmptyLinesBetweenBlocks = anyEmptyLinesBetweenBlocks || itemParser.encounteredBlankLine;
      }
    } else {
      for (final item in items) {
        final itemParser = BlockParser(item.lines, parser.document);
        itemNodes.add(MarkedElement('li', itemParser.parseLines()));
        anyEmptyLinesBetweenBlocks = anyEmptyLinesBetweenBlocks || itemParser.encounteredBlankLine;
      }
    }

    // Must strip paragraph tags if the list is "tight".
    // http://spec.commonmark.org/0.28/#lists
    final listIsTight = !anyEmptyLines && !anyEmptyLinesBetweenBlocks;

    if (listIsTight) {
      // We must post-process the list items, converting any top-level paragraph
      // elements to just text elements.
      for (final item in itemNodes) {
        final children = item.children;
        if (children != null) {
          for (var i = 0; i < children.length; i++) {
            final child = children[i];
            if (child is MarkedElement && child.tag == 'p') {
              children.removeAt(i);
              children.insertAll(i, child.children!);
            }
          }
        }
      }
    }

    return MarkedElement(listTag, itemNodes);
  }

  void _removeLeadingEmptyLine(ListItem item) {
    if (item.lines.isNotEmpty && _emptyPattern.hasMatch(item.lines.first)) {
      item.lines.removeAt(0);
    }
  }

  /// Removes any trailing empty lines and notes whether any items are separated
  /// by such lines.
  bool _removeTrailingEmptyLines(List<ListItem> items) {
    var anyEmpty = false;
    for (var i = 0; i < items.length; i++) {
      if (items[i].lines.length == 1) continue;
      while (items[i].lines.isNotEmpty && _emptyPattern.hasMatch(items[i].lines.last)) {
        if (i < items.length - 1) {
          anyEmpty = true;
        }
        items[i].lines.removeLast();
      }
    }
    return anyEmpty;
  }

  static int _expandedTabLength(String input) {
    var length = 0;
    for (var char in input.codeUnits) {
      length += char == 0x9 ? 4 - (length % 4) : 1;
    }
    return length;
  }
}

/// Parses unordered lists.
class UnorderedListSyntax extends ListSyntax {
  @override
  RegExp get pattern => _ulPattern;

  @override
  String get listTag => 'ul';

  const UnorderedListSyntax();
}

/// Parses ordered lists.
class OrderedListSyntax extends ListSyntax {
  @override
  RegExp get pattern => _olPattern;

  @override
  String get listTag => 'ol';

  const OrderedListSyntax();
}

/// Parses paragraphs of regular text.
class ParagraphSyntax extends BlockSyntax {
  static final _reflinkDefinitionStart = RegExp(r'[ ]{0,3}\[');

  static final _whitespacePattern = RegExp(r'^\s*$');

  @override
  RegExp get pattern => _dummyPattern;

  @override
  bool canEndBlock(BlockParser parser) => false;

  const ParagraphSyntax();

  @override
  bool canParse(BlockParser parser) => true;

  @override
  MarkedNode parse(BlockParser parser) {
    final childLines = <String>[];

    // Eat until we hit something that ends a paragraph.
    while (!BlockSyntax.isAtBlockEnd(parser)) {
      childLines.add(parser.current);
      parser.advance();
    }

    final paragraphLines = _extractReflinkDefinitions(parser, childLines);
    if (paragraphLines == null) {
      parser.advance();
      // Paragraph consisted solely of reference link definitions.
      return MarkedText('');
    } else {
      final contents = UnparsedContent(paragraphLines.join('\n').trimRight());
      return MarkedElement('p', [contents]);
    }
  }

  /// Extract reference link definitions from the front of the paragraph, and
  /// return the remaining paragraph lines.
  List<String>? _extractReflinkDefinitions(BlockParser parser, List<String> lines) {
    bool lineStartsReflinkDefinition(int i) => lines.isNotEmpty && lines[i].startsWith(_reflinkDefinitionStart);

    var i = 0;
    loopOverDefinitions:
    while (true) {
      // Check for reflink definitions.
      if (!lineStartsReflinkDefinition(i)) {
        // It's paragraph content from here on out.
        break;
      }
      var contents = lines[i];
      var j = i + 1;
      while (j < lines.length) {
        // Check to see if the _next_ line might start a new reflink definition.
        // Even if it turns out not to be, but it started with a '[', then it
        // is not a part of _this_ possible reflink definition.
        if (lineStartsReflinkDefinition(j)) {
          // Try to parse [contents] as a reflink definition.
          if (_parseReflinkDefinition(parser, contents)) {
            // Loop again, starting at the next possible reflink definition.
            i = j;
            continue loopOverDefinitions;
          } else {
            // Could not parse [contents] as a reflink definition.
            break;
          }
        } else {
          contents = contents + '\n' + lines[j];
          j++;
        }
      }
      // End of the block.
      if (_parseReflinkDefinition(parser, contents)) {
        i = j;
        break;
      }

      // It may be that there is a reflink definition starting at [i], but it
      // does not extend all the way to [j], such as:
      //
      //     [link]: url     // line i
      //     "title"
      //     garbage
      //     [link2]: url   // line j
      //
      // In this case, [i, i+1] is a reflink definition, and the rest is
      // paragraph content.
      while (j >= i) {
        // This isn't the most efficient loop, what with this big ole'
        // Iterable allocation (`getRange`) followed by a big 'ole String
        // allocation, but we
        // must walk backwards, checking each range.
        contents = lines.getRange(i, j).join('\n');
        if (_parseReflinkDefinition(parser, contents)) {
          // That is the last reflink definition. The rest is paragraph
          // content.
          i = j;
          break;
        }
        j--;
      }
      // The ending was not a reflink definition at all. Just paragraph
      // content.

      break;
    }

    if (i == lines.length) {
      // No paragraph content.
      return null;
    } else {
      // Ends with paragraph content.
      return lines.sublist(i);
    }
  }

  // Parse [contents] as a reference link definition.
  //
  // Also adds the reference link definition to the document.
  //
  // Returns whether [contents] could be parsed as a reference link definition.
  bool _parseReflinkDefinition(BlockParser parser, String contents) {
    final pattern = RegExp(
        // Leading indentation.
        r'''^[ ]{0,3}'''
        // Reference id in brackets, and URL.
        r'''\[((?:\\\]|[^\]])+)\]:\s*(?:<(\S+)>|(\S+))\s*'''
        // Title in double or single quotes, or parens.
        r'''("[^"]+"|'[^']+'|\([^)]+\)|)\s*$''',
        multiLine: true);
    final match = pattern.firstMatch(contents);
    if (match == null) {
      // Not a reference link definition.
      return false;
    }
    if (match.match.length < contents.length) {
      // Trailing text. No good.
      return false;
    }

    var label = match[1]!;
    final destination = match[2] ?? match[3]!;
    var title = match[4];

    // The label must contain at least one non-whitespace character.
    if (_whitespacePattern.hasMatch(label)) {
      return false;
    }

    if (title == '') {
      // No title.
      title = null;
    } else {
      // Remove "", '', or ().
      title = title!.substring(1, title.length - 1);
    }

    // References are case-insensitive, and internal whitespace is compressed.
    label = normalizeLinkLabel(label);

    parser.document.linkReferences.putIfAbsent(label, () => LinkReference(label, destination, title));
    return true;
  }
}
