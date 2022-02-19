import 'package:charcode/charcode.dart';

import 'ast.dart';
import 'block_instance.dart';
import 'block_parser.dart';
import 'extension_set.dart';
import 'inline_parser.dart';

/// Maintains the context needed to parse a Markdown document.
class Document {
  final Map<String, LinkReference> linkReferences = <String, LinkReference>{};
  final ExtensionSet extensionSet;
  // final Resolver? linkResolver;
  final _blockSyntaxes = <BlockSyntax>{
    const EmptyBlockSyntax(),
    const SetextHeaderSyntax(),
    const ImageSyntax(),
    const HeaderSyntax(),
    // const CodeBlockSyntax(),
    const FencedCodeBlockSyntax(),
    const BlockquoteSyntax(),
    const HorizontalRuleSyntax(),
    const UnorderedListSyntax(),
    const OrderedListSyntax(),
    const ParagraphSyntax(),
  };
  final _inlineSyntaxes = <InlineSyntax>{
    EmailAutolinkSyntax(),
    AutolinkSyntax(),
    LineBreakSyntax(),
    // Allow any punctuation to be escaped.
    EscapeSyntax(),
    // "*" surrounded by spaces is left alone.
    TextSyntax(r' \* ', startCharacter: $space),
    // "_" surrounded by spaces is left alone.
    TextSyntax(r' _ ', startCharacter: $space),
    // Parse "**strong**" and "*emphasis*" tags.
    TagSyntax(r'\*+', requiresDelimiterRun: true),
    // Parse "__strong__" and "_emphasis_" tags.
    TagSyntax(r'_+', requiresDelimiterRun: true),
    CodeSyntax(),
  };

  Iterable<BlockSyntax> get blockSyntaxes => _blockSyntaxes;

  Iterable<InlineSyntax> get inlineSyntaxes => _inlineSyntaxes;

  Document({
    Iterable<BlockSyntax>? blockSyntaxes,
    Iterable<InlineSyntax>? inlineSyntaxes,
    ExtensionSet? extensionSet,
    // this.linkResolver,
  }) : extensionSet = extensionSet ?? ExtensionSet.commonMark {
    _blockSyntaxes
      ..addAll(blockSyntaxes ?? [])
      ..addAll(this.extensionSet.blockSyntaxes);
    _inlineSyntaxes
      ..addAll(inlineSyntaxes ?? [])
      ..addAll(this.extensionSet.inlineSyntaxes);
  }

  /// Parses the given [lines] of Markdown to a series of AST nodes.
  List<MarkedNode> parseLines(List<String> lines) {
    final nodes = BlockParser(lines, this).parseLines();
    _parseInlineContent(nodes);
    return nodes;
  }

  /// Parses the given inline Markdown [text] to a series of AST nodes.
  List<MarkedNode> parseInline(String text) => InlineParser(text, this).parse();

  void _parseInlineContent(List<MarkedNode> nodes) {
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      if (node is UnparsedContent) {
        final inlineNodes = parseInline(node.textContent);
        nodes.removeAt(i);
        nodes.insertAll(i, inlineNodes);
        i += inlineNodes.length - 1;
      } else if (node is MarkedElement && node.children != null) {
        _parseInlineContent(node.children!);
      }
    }
  }
}

/// A [link reference
/// definition](http://spec.commonmark.org/0.28/#link-reference-definitions).
class LinkReference {
  /// The [link label](http://spec.commonmark.org/0.28/#link-label).
  ///
  /// Temporarily, this class is also being used to represent the link data for
  /// an inline link (the destination and title), but this should change before
  /// the package is released.
  final String label;

  /// The [link destination](http://spec.commonmark.org/0.28/#link-destination).
  final String destination;

  /// The [link title](http://spec.commonmark.org/0.28/#link-title).
  final String? title;

  /// Construct a new [LinkReference], with all necessary fields.
  ///
  /// If the parsed link reference definition does not include a title, use
  /// `null` for the [title] parameter.
  LinkReference(this.label, this.destination, this.title);
}
