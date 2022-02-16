import 'package:flutter/material.dart';
import 'package:flutter_markdown/src/widget.dart';
import 'package:flutter_markdown/src/render/extension_set.dart' as md;
import 'package:flutter_markdown/src/render/block_parser.dart' as md;
import 'package:flutter_markdown/src/render/inline_parser.dart' as md;

import 'supscript.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _data = """
1. [1|note/1/1/1/0/1][a|bead/1/1/1/0/a]起初[2|note/1/1/1/0/2]神[3|note/1/1/1/0/3][b|bead/1/1/1/0/b]创造[4|note/1/1/1/0/4]诸天与地，

2. [上] [1|note/1/1/2/1/1]而地变为[2|note/1/1/2/1/2][a|bead/1/1/2/1/a]荒废空虚，[3|note/1/1/2/1/3]渊面[2|note/1/1/2/1/2]黑暗。

2. [下] [4|note/1/1/2/2/4]神的[5|note/1/1/2/2/5][b|bead/1/1/2/2/b]灵[6|note/1/1/2/2/6]覆罩在水面上。

3. 神[1|note/1/1/3/0/1][a|bead/1/1/3/0/a]说，要有[1|note/1/1/3/0/1][b|bead/1/1/3/0/b]光，就有了光。

4. 神看光是[a|bead/1/1/4/0/a]好的，就把光暗[1|note/1/1/4/0/1][b|bead/1/1/4/0/b]分开了。

5. 神称光为[a|bead/1/1/5/0/a]昼，称暗为夜；[b|bead/1/1/5/0/b]有晚上，有早晨，这是第一日。

6. 神[a|bead/1/1/6/0/a]说，诸水之间要有[1|note/1/1/6/0/1]广阔的空间，将水与水[2|note/1/1/6/0/2][b|bead/1/1/6/0/b]分开。

7. 神就造出[1|note/1/1/7/0/1]天空，将天空以下的水，与天空以上的[a|bead/1/1/7/0/a]水分开；事就这样成了。

8. 神称天空为天；[a|bead/1/1/8/0/a]有晚上，有早晨，是第二[1|note/1/1/8/0/1]日。
""";

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Flutter Markdown Demo"),
        ),
        body: Markdown(
          data: _data,
          extensionSet: md.ExtensionSet(
            <md.BlockSyntax>[],
            <md.InlineSyntax>[
              SuperscriptSyntax(),
            ],
          ),
          blockSyntaxes: md.ExtensionSet.gitHubFlavored.blockSyntaxes,
          builders: <String, MarkdownElementBuilder>{
            'sup': SuperscriptBuilder((text, title) {
              print(title);
            }),
          },
        ),
      ),
    );
  }
}
