import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'style_sheet.dart' show MarkdownStyleSheet;
import 'widget.dart';
import 'render/ast.dart';

const List<String> _kBlockTags = <String>[
  'p',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'img',
  'li',
  'blockquote',
  'pre',
  'ol',
  'ul',
  'hr',
];

const List<String> _kListTags = <String>['ul', 'ol'];

bool _isBlockTag(String? tag) => _kBlockTags.contains(tag);

bool _isListTag(String tag) => _kListTags.contains(tag);

class _BlockElement {
  _BlockElement(this.tag);

  final String? tag;
  final List<Widget> children = <Widget>[];

  int nextListIndex = 0;
}

/// A collection of widgets that should be placed adjacent to (inline with)
/// other inline elements in the same parent block.
///
/// Inline elements can be textual (a/em/strong) represented by [RichText]
/// widgets or images (img) represented by [Image.network] widgets.
///
/// Inline elements can be nested within other inline elements, inheriting their
/// parent's style along with the style of the block they are in.
///
/// When laying oufirst, any adjacent RichText widgets are
/// merged, then, all inline widgets are enclosed in a parent [Wrap] widget.
class _InlineElement {
  _InlineElement(this.tag, {this.style});

  final String? tag;

  /// Created by merging the style defined for this element's [tag] in the
  /// delegate's [MarkdownStyleSheet] with the style of its parent.
  final TextStyle? style;

  final List<InlineSpan> children = <InlineSpan>[];
}

/// A delegate used by [MarkdownBuilder] to control the widgets it creates.
abstract class MarkdownBuilderDelegate {
  /// Returns a gesture recognizer to use for an `a` element with the given
  /// text, `href` attribute, and title.
  GestureRecognizer createLink(String text, String? href, String title);

  /// Returns formatted text to use to display the given contents of a `pre`
  /// element.
  ///
  /// The `styleSheet` is the value of [MarkdownBuilder.styleSheet].
  TextSpan formatText(MarkdownStyleSheet styleSheet, String code);
}

/// Builds a [Widget] tree from parsed Markdown.
///
/// See also:
///
///  * [Markdown], which is a widget that parses and displays Markdown.
class MarkdownBuilder implements NodeVisitor {
  /// Creates an object that builds a [Widget] tree from parsed Markdown.
  MarkdownBuilder({
    required this.delegate,
    required this.styleSheet,
    required this.baseUrl,
    required this.onTapImage,
    required this.checkboxBuilder,
    required this.bulletBuilder,
    required this.builders,
    required this.paddingBuilders,
    required this.listItemCrossAxisAlignment,
    this.fitContent = false,
    this.softLineBreak = false,
  });

  /// A delegate that controls how link and `pre` elements behave.
  final MarkdownBuilderDelegate delegate;

  /// If true, the text is selectable.
  ///
  /// Defaults to false.

  /// Defines which [TextStyle] objects to use for each type of element.
  final MarkdownStyleSheet styleSheet;

//
  final String baseUrl;

  final void Function(String url, String? tag) onTapImage;

  /// Call when build a checkbox widget.
  final MarkdownCheckboxBuilder? checkboxBuilder;

  /// Called when building a custom bullet.
  final MarkdownBulletBuilder? bulletBuilder;

  /// Call when build a custom widget.
  final Map<String, MarkdownElementBuilder> builders;

  /// Call when build a padding for widget.
  final Map<String, MarkdownPaddingBuilder> paddingBuilders;

  /// Whether to allow the widget to fit the child content.
  final bool fitContent;

  /// Controls the cross axis alignment for the bullet and list item content
  /// in lists.
  ///
  /// Defaults to [MarkdownListItemCrossAxisAlignment.baseline], which
  /// does not allow for intrinsic height measurements.
  final MarkdownListItemCrossAxisAlignment listItemCrossAxisAlignment;

  /// The soft line break is used to identify the spaces at the end of aline of
  /// text and the leading spaces in the immediately following the line of text.
  ///
  /// Default these spaces are removed in accordance with the Markdown
  /// specification on soft line breaks when lines of text are joined.
  final bool softLineBreak;

  final List<String> _listIndents = <String>[];
  final List<_BlockElement> _blocks = <_BlockElement>[];
  final List<_InlineElement> _inlines = <_InlineElement>[];
  final List<GestureRecognizer> _linkHandlers = <GestureRecognizer>[];
  String? _currentBlockTag;
  String? _lastVisitedTag;
  bool _isInBlockquote = false;

  /// Returns widgets that display the given Markdown nodes.
  ///
  /// The returned widgets are typically used as children in a [ListView].
  List<Widget> build(List<MarkedNode> nodes) {
    _listIndents.clear();
    _blocks.clear();
    _inlines.clear();
    _linkHandlers.clear();
    _isInBlockquote = false;

    _blocks.add(_BlockElement(null));

    for (final MarkedNode node in nodes) {
      assert(_blocks.length == 1);
      node.accept(this);
    }

    assert(_inlines.isEmpty);
    assert(!_isInBlockquote);
    return _blocks.single.children;
  }

  @override
  bool visitElementBefore(MarkedElement element) {
    final String tag = element.tag;
    _currentBlockTag ??= tag;
    _lastVisitedTag = tag;

    if (builders.containsKey(tag)) {
      builders[tag]!.visitElementBefore(element);
    }

    if (paddingBuilders.containsKey(tag)) {
      paddingBuilders[tag]!.visitElementBefore(element);
    }

    int? start;
    if (_isBlockTag(tag)) {
      _addAnonymousBlockIfNeeded();

      if (_isListTag(tag)) {
        _listIndents.add(tag);
      } else {
        switch (tag) {
          case 'blockquote':
            _isInBlockquote = true;
            break;
        }
      }
      final _BlockElement bElement = _BlockElement(tag);
      if (start != null) {
        bElement.nextListIndex = start;
      }
      _blocks.add(bElement);
    } else {
      if (tag == 'a') {
        final String? text = extractTextFromElement(element);
        // Don't add empty links
        if (text == null) {
          return false;
        }
        final String? destination = element.attributes['href'];
        final String title = element.attributes['title'] ?? '';

        _linkHandlers.add(
          delegate.createLink(text, destination, title),
        );
      }
      _addParentInlineIfNeeded(_blocks.last.tag);

      final TextStyle parentStyle = _inlines.last.style!;
      _inlines.add(_InlineElement(
        tag,
        style: parentStyle.merge(styleSheet.styles[tag]),
      ));
    }

    return true;
  }

  /// Returns the text, if any, from [element] and its descendants.
  String? extractTextFromElement(MarkedNode element) {
    return element is MarkedElement && (element.children?.isNotEmpty ?? false)
        ? element.children!.map((MarkedNode e) => e is MarkedText ? e.text : extractTextFromElement(e)).join('')
        : (element is MarkedElement && (element.attributes.isNotEmpty) ? element.attributes['alt'] : '');
  }

  @override
  void visitText(MarkedText text) {
    // Don't allow text directly under the root.
    if (_blocks.last.tag == null) {
      return;
    }

    _addParentInlineIfNeeded(_blocks.last.tag);

    // Define trim text function to remove spaces from text elements in
    // accordance with Markdown specifications.
    String trimText(String text) {
      // The leading spaces pattern is used to identify spaces
      // at the beginning of a line of text.
      final RegExp _leadingSpacesPattern = RegExp(r'^ *');

      // The soft line break is used to identify the spaces at the end of a line
      // of text and the leading spaces in the immediately following the line
      // of text. These spaces are removed in accordance with the Markdown
      // specification on soft line breaks when lines of text are joined.
      final RegExp _softLineBreak = RegExp(r' ?\n *');

      // Leading spaces following a hard line break are ignored.
      // https://github.github.com/gfm/#example-657
      // Leading spaces in paragraph or list item are ignored
      // https://github.github.com/gfm/#example-192
      // https://github.github.com/gfm/#example-236
      if (const <String>['ul', 'ol', 'p', 'br'].contains(_lastVisitedTag)) {
        text = text.replaceAll(_leadingSpacesPattern, '');
      }

      if (softLineBreak) {
        return text;
      }
      return text.replaceAll(_softLineBreak, ' ');
    }

    InlineSpan? child;
    if (_blocks.isNotEmpty && builders.containsKey(_blocks.last.tag)) {
      child = builders[_blocks.last.tag!]!.visitText(text, styleSheet.styles[_blocks.last.tag!])!;
    } else if (_blocks.last.tag == 'pre') {
      child = WidgetSpan(
        child: Scrollbar(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: styleSheet.codeblockPadding,
            child: _buildRichText(delegate.formatText(styleSheet, text.text)),
          ),
        ),
      );
    } else {
      child = TextSpan(
        style: _isInBlockquote ? styleSheet.blockquote!.merge(_inlines.last.style) : _inlines.last.style,
        text: _isInBlockquote ? text.text : trimText(text.text),
        recognizer: _linkHandlers.isNotEmpty ? _linkHandlers.last : null,
      );
    }
    _inlines.last.children.add(child);

    _lastVisitedTag = null;
  }

  @override
  void visitElementAfter(MarkedElement element) {
    final String tag = element.tag;

    if (_isBlockTag(tag)) {
      _addAnonymousBlockIfNeeded();

      final _BlockElement current = _blocks.removeLast();
      Widget child;

      if (current.children.isNotEmpty) {
        child = Column(
          crossAxisAlignment: fitContent ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
          children: current.children,
        );
      } else {
        child = const SizedBox();
      }

      if (_isListTag(tag)) {
        assert(_listIndents.isNotEmpty);
        _listIndents.removeLast();
      } else {
        switch (tag) {
          case 'li':
            if (_listIndents.isNotEmpty) {
              if (element.children!.isEmpty) {
                element.children!.add(MarkedText(''));
              }
              Widget bullet;
              final el = element.children![0];
              if (el is MarkedElement && el.attributes['type'] == 'checkbox') {
                final bool val = el.attributes['checked'] != 'false';
                bullet = _buildCheckbox(val);
              } else {
                bullet = _buildBullet(_listIndents.last, element.attributes['index']);
              }

              child = Row(
                textBaseline: listItemCrossAxisAlignment == MarkdownListItemCrossAxisAlignment.start
                    ? null
                    : TextBaseline.alphabetic,
                crossAxisAlignment: listItemCrossAxisAlignment == MarkdownListItemCrossAxisAlignment.start
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.baseline,
                children: <Widget>[
                  // bullet,
                  SizedBox(
                    width: styleSheet.listIndent! +
                        styleSheet.listBulletPadding!.left +
                        styleSheet.listBulletPadding!.right,
                    child: bullet,
                  ),
                  Expanded(child: child)
                ],
              );
            }
            break;
          case 'blockquote':
            _isInBlockquote = false;
            child = DecoratedBox(
              decoration: styleSheet.blockquoteDecoration!,
              child: _buildPadding(styleSheet.blockquotePadding, child),
            );
            break;
          case 'pre':
            child = DecoratedBox(
              decoration: styleSheet.codeblockDecoration!,
              child: child,
            );
            break;
          case 'hr':
            child = Container(decoration: styleSheet.horizontalRuleDecoration);
            break;
          case 'img':
            child = Center(
              child: InkWell(
                onTap: () => onTapImage(
                  element.attributes['url']!.startsWith('http')
                      ? element.attributes['url']!
                      : '$baseUrl/${element.attributes['url']!}',
                  element.attributes['alt'],
                ),
                child: _buildPadding(
                  styleSheet.imgPadding,
                  Image.network(element.attributes['url']!),
                ),
              ),
            );
            break;
          default:
        }
      }

      _addBlockChild(child);
    } else {
      final _InlineElement current = _inlines.removeLast();
      final _InlineElement parent = _inlines.last;

      if (builders.containsKey(tag)) {
        final InlineSpan? child = builders[tag]!.visitElementAfter(element, styleSheet.styles[tag]);
        if (child != null) {
          current.children[0] = child;
        }
      } else {
        switch (tag) {
          case 'br':
            current.children.add(const TextSpan(text: '\n'));
            break;
          case 'a':
            _linkHandlers.removeLast();
            break;
          default:
        }
      }

      if (current.children.isNotEmpty) {
        parent.children.addAll(current.children);
      }
    }
    if (_currentBlockTag == tag) {
      _currentBlockTag = null;
    }
    _lastVisitedTag = tag;
  }

  Widget _buildCheckbox(bool checked) {
    if (checkboxBuilder != null) {
      return checkboxBuilder!(checked);
    }
    return _buildPadding(
        styleSheet.listBulletPadding,
        Icon(
          checked ? Icons.check_box : Icons.check_box_outline_blank,
          size: styleSheet.checkbox!.fontSize,
          color: styleSheet.checkbox!.color,
        ));
  }

  Widget _buildBullet(String listTag, String? idx) {
    final int index = _blocks.last.nextListIndex;

    final bool isUnordered = listTag == 'ul';

    if (bulletBuilder != null) {
      return _buildPadding(styleSheet.listBulletPadding,
          bulletBuilder!(index, isUnordered ? BulletStyle.unorderedList : BulletStyle.orderedList));
    }

    if (isUnordered) {
      return _buildPadding(
        styleSheet.listBulletPadding,
        Text(
          '•',
          textAlign: TextAlign.center,
          style: styleSheet.listBullet,
        ),
      );
    }

    return _buildPadding(
      styleSheet.listBulletPadding,
      Text(
        // '${index + 1}.',
        '$idx.',
        textAlign: TextAlign.right,
        style: styleSheet.listBullet,
      ),
    );
  }

  Widget _buildPadding(EdgeInsets? padding, Widget child) {
    if (padding == null || padding == EdgeInsets.zero) {
      return child;
    }

    return Padding(padding: padding, child: child);
  }

  void _addParentInlineIfNeeded(String? tag) {
    if (_inlines.isEmpty) {
      _inlines.add(_InlineElement(
        tag,
        style: styleSheet.styles[tag!],
      ));
    }
  }

  void _addBlockChild(Widget child) {
    final _BlockElement parent = _blocks.last;
    // if (parent.children.isNotEmpty) {
    //   parent.children.add(SizedBox(height: styleSheet.blockSpacing));
    // }
    parent.children.add(child);
    parent.nextListIndex += 1;
  }

  void _addAnonymousBlockIfNeeded() {
    if (_inlines.isEmpty) {
      return;
    }

    WrapAlignment blockAlignment = WrapAlignment.start;
    EdgeInsets textPadding = EdgeInsets.zero;
    if (_isBlockTag(_currentBlockTag)) {
      blockAlignment = _wrapAlignmentForBlockTag(_currentBlockTag);
      textPadding = _textPaddingForBlockTag(_currentBlockTag);

      if (paddingBuilders.containsKey(_currentBlockTag)) {
        textPadding = paddingBuilders[_currentBlockTag]!.getPadding();
      }
    }

    final _InlineElement inline = _inlines.single;
    if (inline.children.isNotEmpty) {
      // final List<InlineSpan> mergedInlines = inline.children;
      final Wrap wrap = Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SelectableText.rich(
            TextSpan(children: inline.children),
          )
        ],
        alignment: blockAlignment,
      );

      if (textPadding == EdgeInsets.zero) {
        _addBlockChild(wrap);
      } else {
        _addBlockChild(_buildPadding(textPadding, wrap));
      }

      _inlines.clear();
    }
  }

  WrapAlignment _wrapAlignmentForBlockTag(String? blockTag) {
    switch (blockTag) {
      case 'p':
        return styleSheet.textAlign;
      case 'h1':
        return styleSheet.h1Align;
      case 'h2':
        return styleSheet.h2Align;
      case 'h3':
        return styleSheet.h3Align;
      case 'h4':
        return styleSheet.h4Align;
      case 'h5':
        return styleSheet.h5Align;
      case 'h6':
        return styleSheet.h6Align;
      case 'ul':
        return styleSheet.unorderedListAlign;
      case 'ol':
        return styleSheet.orderedListAlign;
      case 'blockquote':
        return styleSheet.blockquoteAlign;
      case 'pre':
        return styleSheet.codeblockAlign;
      case 'hr':
        print('Markdown did not handle hr for alignment');
        break;
      case 'li':
        print('Markdown did not handle li for alignment');
        break;
    }
    return WrapAlignment.start;
  }

  EdgeInsets _textPaddingForBlockTag(String? blockTag) {
    switch (blockTag) {
      case 'p':
        return styleSheet.pPadding!;
      case 'h1':
        return styleSheet.h1Padding!;
      case 'h2':
        return styleSheet.h2Padding!;
      case 'h3':
        return styleSheet.h3Padding!;
      case 'h4':
        return styleSheet.h4Padding!;
      case 'h5':
        return styleSheet.h5Padding!;
      case 'h6':
        return styleSheet.h6Padding!;
    }
    return EdgeInsets.zero;
  }

  Widget _buildRichText(TextSpan? text, {TextAlign? textAlign, String? key}) {
    //Adding a unique key prevents the problem of using the same link handler for text spans with the same text
    final Key k = key == null ? UniqueKey() : Key(key);
    return SelectableText.rich(
      text!,
      textScaleFactor: styleSheet.textScaleFactor,
      textAlign: textAlign ?? TextAlign.start,
      key: k,
    );
  }
}
