import 'package:flutter/material.dart';
import 'package:flutter_markdown/markdown.dart';

class SuperscriptSyntax extends InlineSyntax {
  SuperscriptSyntax() : super(r'\[([0-9]+|[a-z])\|([^\]]+)\]');

  @override
  bool onMatch(InlineParser parser, Match match) {
    final sup = MarkedElement.text('sup', match[1]!);
    sup.attributes['title'] = match[2]!;
    // final sup = Element.withTag('sup');
    // final anchor = Element.text('a', match[1]!);
    // anchor.attributes['href'] = Uri.encodeFull('www.baidu.com');
    // sup.children!.add(anchor);
    parser.addNode(sup);

    return true;
  }
}

class SuperscriptBuilder extends MarkdownElementBuilder {
  final Function(String, String?) onTabSup;
  static const Map<String, String> _supscripts = <String, String>{
    '0': '\u2070',
    '1': '\u00B9',
    '2': '\u00B2',
    '3': '\u00B3',
    '4': '\u2074',
    '5': '\u2075',
    '6': '\u2076',
    '7': '\u2077',
    '8': '\u2078',
    '9': '\u2079',
    'a': '\u1d43',
    'b': '\u1d47',
    'c': '\u1d9c',
    'd': '\u1d48',
    'e': '\u1d49',
    'f': '\u1da0',
    'g': '\u1d4d',
    'h': '\u02b0',
    'i': '\u2071',
    'j': '\u02b2',
    'k': '\u1d4f',
    'l': '\u02e1',
    'm': '\u1d50',
    'n': '\u207f',
    'o': '\u1d52',
    'p': '\u1d56',
    'q': '?',
    'r': '\u02b3',
    's': '\u02e2',
    't': '\u1d57',
    'u': '\u1d58',
    'v': '\u1d5b',
    'w': '\u02b7',
    'x': '\u02e3',
    'y': '\u02b8',
    'z': '\u1DBB',
  };

  SuperscriptBuilder(this.onTabSup);
  @override
  InlineSpan visitElementAfter(MarkedElement element, TextStyle? preferredStyle) {
    // final String textContent = element.textContent;
    // String text = '';
    // for (int i = 0; i < textContent.length; i++) {
    //   text += _supscripts[textContent[i]] ?? '';
    // }

    // return SelectableText.rich(TextSpan(text: text));
    // return SelectableText.rich(
    //   TextSpan(
    //     children: [
    //       WidgetSpan(
    //         child: Transform.translate(
    //           offset: const Offset(0.0, -7.0),
    //           child: Text(
    //             text,
    //             style: const TextStyle(fontSize: 10),
    //           ),
    //         ),
    //       ),
    //     ],
    //   ),
    // );

    return WidgetSpan(
      child: Transform.translate(
        offset: const Offset(0.0, -10.0),
        child: InkWell(
          onTap: () {
            print(element.attributes['title']);
          },
          child: Text(
            element.textContent,
            style: const TextStyle(fontSize: 15, color: Colors.red),
          ),
        ),
      ),
    );

    // return Text.rich(
    //   WidgetSpan(
    //     child: Transform.translate(
    //       offset: const Offset(0.0, -7.0),
    //       child: Text(
    //         text,
    //         style: const TextStyle(fontSize: 10),
    //       ),
    //     ),
    //   ),
    // );
  }
}
