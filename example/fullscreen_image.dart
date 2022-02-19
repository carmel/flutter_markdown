import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _url = [
    'https://raw.githubusercontent.com/flutter/website/master/src/_includes/code/layout/lakes/images/lake.jpg',
    'https://github.com/flutter/plugins/raw/master/packages/video_player/doc/demo_ipod.gif?raw=true'
  ];
  final _tag = ['imageHero', 'imageHero2'];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Screen'),
      ),
      body: ListView(
        children: <Widget>[
          GestureDetector(
            child: Hero(
                tag: _tag[0],
                child: CachedNetworkImage(
                  imageUrl: _url[0],
                  placeholder: (ctx, str) =>
                      const Center(child: SizedBox(width: 32, height: 32, child: CircularProgressIndicator())),
                  errorWidget: (ctx, str, dyn) => const Icon(Icons.error),
                )),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) {
                return ImagePreview(
                  tag: _tag[0],
                  url: _url[0],
                  key: null,
                );
              }));
            },
          ),
          GestureDetector(
            child: Hero(
                tag: _tag[1],
                child: CachedNetworkImage(
                  imageUrl: _url[1],
                  placeholder: (ctx, str) =>
                      const Center(child: SizedBox(width: 32, height: 32, child: CircularProgressIndicator())),
                  errorWidget: (ctx, str, dyn) => const Icon(Icons.error),
                )),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) {
                return ImagePreview(tag: _tag[1], url: _url[1]);
              }));
            },
          ),
        ],
      ),
    );
  }
}

class ImagePreview extends StatefulWidget {
  final String tag;
  final String url;

  const ImagePreview({Key? key, required this.tag, required this.url}) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<ImagePreview> {
  @override
  initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    super.initState();
  }

  @override
  void dispose() {
    //SystemChrome.restoreSystemUIOverlays();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Center(
        child: Hero(
          tag: widget.tag,
          child: PhotoView(
            imageProvider: NetworkImage(widget.url),
          ),
        ),
      ),
      onTap: () {
        Navigator.pop(context);
      },
    );
  }
}
