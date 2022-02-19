// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/cupertino.dart' show CupertinoTheme;
import 'package:flutter/material.dart' show Theme;
import 'package:flutter/widgets.dart';

import 'style_sheet.dart';
import 'widget.dart';

/// Type for a function that creates image widgets.
typedef ImageBuilder = WidgetSpan Function(Uri uri, String? imageDirectory);

/// A default image builder handling http/https, resource, and file URLs.
// ignore: prefer_function_declarations_over_variables
final ImageBuilder kDefaultImageBuilder = (
  Uri uri,
  String? imageDirectory,
) {
  return WidgetSpan(
      child:
          // GestureDetector(
          //         child: Hero(
          //             tag: _tag[0],
          //             child: CachedNetworkImage(
          //               imageUrl: _url[0],
          //               placeholder: (ctx, str) =>
          //                   const Center(child: SizedBox(width: 32, height: 32, child: CircularProgressIndicator())),
          //               errorWidget: (ctx, str, dyn) => const Icon(Icons.error),
          //             )),
          //         onTap: () {
          //           Navigator.push(context, MaterialPageRoute(builder: (_) {
          //             return ImagePreview(
          //               tag: _tag[0],
          //               url: _url[0],
          //               key: null,
          //             );
          //           }));
          //         },
          //       )
          Image.network(uri.toString()));
};

/// A default style sheet generator.
final MarkdownStyleSheet Function(BuildContext, MarkdownStyleSheetBaseTheme?)
// ignore: prefer_function_declarations_over_variables
    kFallbackStyle = (
  BuildContext context,
  MarkdownStyleSheetBaseTheme? baseTheme,
) {
  MarkdownStyleSheet result;
  switch (baseTheme) {
    case MarkdownStyleSheetBaseTheme.platform:
      result = (Platform.isIOS || Platform.isMacOS)
          ? MarkdownStyleSheet.fromCupertinoTheme(CupertinoTheme.of(context))
          : MarkdownStyleSheet.fromTheme(Theme.of(context));
      break;
    case MarkdownStyleSheetBaseTheme.cupertino:
      result = MarkdownStyleSheet.fromCupertinoTheme(CupertinoTheme.of(context));
      break;
    case MarkdownStyleSheetBaseTheme.material:
    default:
      result = MarkdownStyleSheet.fromTheme(Theme.of(context));
  }

  return result.copyWith(
    textScaleFactor: MediaQuery.textScaleFactorOf(context),
  );
};
