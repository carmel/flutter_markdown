import 'package:flutter/material.dart';

import 'package:flutter_markdown/markdown.dart';

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

[vue3-markdown](https://www.npmjs.com/package/vue3-markdown) ![RUNOOB 图标](http://static.runoob.com/images/runoob-logo.png)


![RUNOOB](http://via.placeholder.com/350x150)


## Markdown Basic Syntax

I just love **bold text**. Italicized text is the _cat's meow_. At the command prompt, type `nano`.

My favorite markdown editor is [vue3-markdown](https://www.npmjs.com/package/vue3-markdown).

1. First item
2. Second item
3. Third item

> Dorothy followed her through many of the beautiful rooms in her castle.

```js
import { ref } from 'vue'
import { VMarkdownEditor } from 'vue3-markdown'
import 'vue3-markdown/dist/style.css'

const handleUpload = (file) => {
  console.log(file)
  return 'https://i.postimg.cc/52qCzTVw/pngwing-com.png'
}
```

## GFM Extended Syntax

Automatic URL Linking: https://www.npmjs.com/package/vue3-markdown

~~The world is flat.~~ We now know that the world is round.

- [x] Write the press release
- [ ] Update the website
- [ ] Contact the media

1. First item
2. Second item
3. Third item
---
1. First item
2. Second item
3. Third item
---
1. First item
2. Second item
3. Third item
---
1. First item
2. Second item
3. Third item
---
1. First item
2. Second item
3. Third item
---
1. First item
2. Second item
3. Third item
---
1. First item
2. Second item
3. Third item
---
1. First item
2. Second item
3. Third item
---
1. First item
2. Second item
3. Third item
---
1. First item
2. Second item
3. Third item
---
1. First item
2. Second item
3. Third item
---
1. First item
2. Second item
3. Third item
---
1. First item
2. Second item
3. Third item
---
1. First item
2. Second item
3. Third item
---
1. First item
2. Second item
3. Third item
---
1. First item
2. Second item
3. Third item
---
""";

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: PositionableMarkdown(
          data: _data,
          onTapLink: (text, href, title) {
            print('onTapLink>>>>>>>>>>>>>>>>>');
            print(text);
            print(href);
            print('<<<<<<<<<<<<<<<<<onTapLink');
          },
          onTapImage: (url, tag) {
            print('onTapImage>>>>>>>>>>>>>>>>>');
            print(url);
            print(tag);
            print('<<<<<<<<<<<<<<<<<onTapImage');

            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (BuildContext context) {
            //       return ImagePreview(
            //         url: url,
            //         tag: tag ?? '',
            //       );
            //     },
            //   ),
            // );
          },
          extensionSet: ExtensionSet(
            <BlockSyntax>[],
            <InlineSyntax>[
              SuperscriptSyntax(),
            ],
          ),
          blockSyntaxes: ExtensionSet.gitHubFlavored.blockSyntaxes,
          builders: <String, MarkdownElementBuilder>{
            'sup': SuperscriptBuilder((text, title) {
              print(title);
            }),
          },
          baseUrl: '',
          controller: AutoScrollController(),
          padding: const EdgeInsets.only(top: 4, bottom: 24, left: 15, right: 15),
          appbar: SliverAppBar(
            floating: true,
            elevation: 4,
            automaticallyImplyLeading: false,
            // backgroundColor: Color(0xf0EBEDEE),
            // expandedHeight: 120.0,
            // iconTheme: IconThemeData(color: Colors.black38),
            title: const Text('flutter markdown demo'),
            // bottom: Layout.appBar(ctx: context, title: 'testw'),
            actions: <Widget>[
              // IconButton(icon: Icon(Icons.settings), disabledColor: Colors.grey, onPressed: null),
              PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  padding: EdgeInsets.zero,
                  elevation: 5,
                  itemBuilder: (_) => <PopupMenuEntry<int>>[
                        const PopupMenuDivider(
                          height: 0.5,
                        ),
                        const PopupMenuItem<int>(
                            value: 1,
                            child: ListTile(
                              dense: true,
                              leading: Icon(Icons.sync),
                              title: Text('同步更新'),
                            )),
                        const PopupMenuDivider(
                          height: 0.5,
                        ),
                        const PopupMenuItem<int>(
                            value: 2,
                            child: ListTile(
                              dense: true,
                              leading: Icon(Icons.bookmark_add_outlined),
                              title: Text('保存书签'),
                            )),
                      ],
                  onSelected: (value) {
                    switch (value) {
                      case 1:
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('同步更新')));
                        break;
                      case 2:
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存书签')));
                        break;
                    }
                  }),
            ],
          ),
          initialScrollOffset: 30, // means 30%
          notifyHandler: (maxScrollExtent, offset, index) {
            print('max>>>>>>>>$maxScrollExtent, offset>>>>>>>>$offset');
            print('reading>>>>>>>>>>>>> ${(offset * 100 / maxScrollExtent).round()}%');
            print('reading index>>>>>>>>>>>>> $index');
          },
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            textScaleFactor: 1.3,
            listPadding: const EdgeInsets.all(20),
            p: const TextStyle(fontSize: 24),
            listBullet: const TextStyle(fontSize: 24),
            checkbox: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}
