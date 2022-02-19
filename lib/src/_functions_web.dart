// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html'; // ignore: avoid_web_libraries_in_flutter

import 'package:flutter/cupertino.dart' show CupertinoTheme;
import 'package:flutter/material.dart' show Theme;
import 'package:flutter/widgets.dart';

import 'style_sheet.dart';
import 'widget.dart';

/// Type for a function that creates image widgets.
typedef ImageBuilder = Widget Function(Uri uri, String? imageDirectory, double? width, double? height);

/// A default image builder handling http/https, resource, data, and file URLs.
// ignore: prefer_function_declarations_over_variables
final ImageBuilder kDefaultImageBuilder = (
  Uri uri,
  String? imageDirectory,
  double? width,
  double? height,
) {
  return Image.network(uri.toString(), width: width, height: height);
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
      final String userAgent = window.navigator.userAgent;
      result = userAgent.contains('Mac OS X')
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
