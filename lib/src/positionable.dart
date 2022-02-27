import 'package:flutter/material.dart';

import 'parser/block_parser.dart' show BlockSyntax;
import 'parser/extension_set.dart' show ExtensionSet;
import 'parser/inline_parser.dart';
import 'scroll_to.dart' show AutoScrollController;
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

class PositionableMarkdown extends Markdown {
  final SliverAppBar appbar;

  final void Function(double, double) notifyHandler;
  PositionableMarkdown({
    Key? key,
    required this.appbar,
    required this.notifyHandler,
    required String data,
    required String baseUrl,
    required MarkdownTapImageCallback onTapImage,
    required MarkdownTapLinkCallback onTapLink,
    required AutoScrollController controller,
    required int initialScrollOffset,
    EdgeInsets? padding,
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
          initialScrollOffset: initialScrollOffset,
          padding: padding ?? const EdgeInsets.only(top: 4, bottom: 24, left: 15, right: 15),
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

  @override
  Widget build(BuildContext context, List<Widget>? children) {
    return NotificationListener<ScrollNotification>(
      child: CustomScrollView(
        controller: controller,
        cacheExtent: 1000,
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        slivers: <Widget>[
          appbar,
          super.build(
            context,
            children,
          ),
        ],
      ),
      onNotification: (ScrollNotification notification) {
        // bool? isForward;
        // if (notification is UserScrollNotification) {
        //   if (notification.direction == ScrollDirection.forward) {
        //     isForward = true;
        //   }
        //   if (notification.direction == ScrollDirection.reverse) {
        //     isForward = false;
        //   }
        // }
        if (notification is ScrollEndNotification) {
          // final len = super.widgetHeight.length;
          final offset = notification.metrics.pixels;
          final max = notification.metrics.maxScrollExtent;

          // int index = 0;

          // if (offset > max) {
          //   index = len;
          // } else {
          //   var height = .0;
          //   for (var i = 0; i < len; i++) {
          //     // height += super.widgetHeight[i];
          //     if (offset <= height) {
          //       index = i + 1;
          //       break;
          //     }
          //   }
          // }

          notifyHandler(
            max,
            offset,
          );
        }
        return false;
      },
    );
  }
}
