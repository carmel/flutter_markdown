import 'package:flutter/material.dart';

import 'render/inline_parser.dart';
import 'scroll_to.dart' show AutoScrollController;
import 'scroll_tag.dart' show AutoScrollTag;
import 'style_sheet.dart' show MarkdownStyleSheet;
import 'widget.dart'
    show
        Markdown,
        MarkdownTapImageCallback,
        MarkdownTapLinkCallback,
        MarkdownStyleSheetBaseTheme,
        SyntaxHighlighter,
        MarkdownCheckboxBuilder,
        MarkdownBulletBuilder,
        MarkdownElementBuilder,
        MarkdownListItemCrossAxisAlignment;
import 'render/block_parser.dart' show BlockSyntax;
import 'render/extension_set.dart' show ExtensionSet;

class PositionableMarkdown extends Markdown {
  const PositionableMarkdown({
    Key? key,
    required this.appbar,
    required this.notifyHandler,
    required String data,
    required String baseUrl,
    required MarkdownTapImageCallback onTapImage,
    required MarkdownTapLinkCallback onTapLink,
    required AutoScrollController controller,
    EdgeInsets? padding,
    bool selectable = false,
    MarkdownStyleSheet? styleSheet,
    MarkdownStyleSheetBaseTheme? styleSheetTheme,
    SyntaxHighlighter? syntaxHighlighter,
    List<BlockSyntax>? blockSyntaxes,
    List<InlineSyntax>? inlineSyntaxes,
    ExtensionSet? extensionSet,
    MarkdownCheckboxBuilder? checkboxBuilder,
    MarkdownBulletBuilder? bulletBuilder,
    Map<String, MarkdownElementBuilder> builders = const <String, MarkdownElementBuilder>{},
    MarkdownListItemCrossAxisAlignment listItemCrossAxisAlignment = MarkdownListItemCrossAxisAlignment.baseline,
  }) : super(
          key: key,
          data: data,
          baseUrl: baseUrl,
          controller: controller,
          padding: padding ?? const EdgeInsets.only(top: 4, bottom: 24, left: 15, right: 15),
          selectable: selectable,
          styleSheet: styleSheet,
          styleSheetTheme: styleSheetTheme,
          syntaxHighlighter: syntaxHighlighter,
          onTapLink: onTapLink,
          onTapImage: onTapImage,
          blockSyntaxes: blockSyntaxes,
          inlineSyntaxes: inlineSyntaxes,
          extensionSet: extensionSet,
          checkboxBuilder: checkboxBuilder,
          builders: builders,
          listItemCrossAxisAlignment: listItemCrossAxisAlignment,
          bulletBuilder: bulletBuilder,
        );

  final SliverAppBar appbar;
  final void Function(double, double) notifyHandler;

  @override
  Widget build(BuildContext context, List<Widget>? children) {
    return NotificationListener<ScrollNotification>(
      child: CustomScrollView(
        controller: controller,
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        slivers: <Widget>[
          appbar,
          SliverPadding(
            padding: padding,
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  return children![i];
                  // if (children![i] is! SizedBox) {
                  //   return AutoScrollTag(
                  //     key: ValueKey(i),
                  //     controller: controller,
                  //     index: i + 1,
                  //     child: children[i],
                  //   );
                  // }
                  // return const SizedBox();
                },
                childCount: children?.length,
              ),
            ),
          ),
        ],
      ),
      onNotification: (ScrollNotification notification) {
        final double maxScroll = notification.metrics.maxScrollExtent;
        final offset = notification.metrics.pixels;
        if (notification is ScrollEndNotification) {
          notifyHandler(maxScroll, offset);
        }
        return false;
      },
    );
  }
}
