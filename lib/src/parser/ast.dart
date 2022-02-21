// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef Resolver = MarkedNode? Function(String name, [String? title]);

/// Base class for any AST item.
///
/// Roughly corresponds to MarkedNode in the DOM. Will be either an MarkedElement or Text.
abstract class MarkedNode {
  void accept(NodeVisitor visitor);

  String get textContent;
}

/// A named tag that can contain other nodes.
class MarkedElement implements MarkedNode {
  final String tag;
  final List<MarkedNode>? children;
  final Map<String, String> attributes;
  String? generatedId;

  /// Instantiates a [tag] MarkedElement with [children].
  MarkedElement(this.tag, this.children) : attributes = <String, String>{};

  /// Instantiates an empty, self-closing [tag] MarkedElement.
  MarkedElement.empty(this.tag)
      : children = null,
        attributes = {};

  /// Instantiates a [tag] MarkedElement with no [children].
  MarkedElement.withTag(this.tag)
      : children = [],
        attributes = {};

  /// Instantiates a [tag] MarkedElement with a single Text child.
  MarkedElement.text(this.tag, String text)
      : children = [MarkedText(text)],
        attributes = {};

  /// Whether this element is self-closing.
  bool get isEmpty => children == null;

  @override
  void accept(NodeVisitor visitor) {
    if (visitor.visitElementBefore(this)) {
      if (children != null) {
        for (var child in children!) {
          child.accept(visitor);
        }
      }
      visitor.visitElementAfter(this);
    }
  }

  @override
  String get textContent {
    return (children ?? []).map((MarkedNode? child) => child!.textContent).join('');
  }
}

/// A plain text element.
class MarkedText implements MarkedNode {
  final String text;

  MarkedText(this.text);

  @override
  void accept(NodeVisitor visitor) => visitor.visitText(this);

  @override
  String get textContent => text;
}

/// Inline content that has not been parsed into inline nodes (strong, links,
/// etc).
///
/// These placeholder nodes should only remain in place while the block nodes
/// of a document are still being parsed, in order to gather all reference link
/// definitions.
class UnparsedContent implements MarkedNode {
  @override
  final String textContent;

  UnparsedContent(this.textContent);

  @override
  void accept(NodeVisitor visitor) {}
}

/// Visitor pattern for the AST.
///
/// Renderers or other AST transformers should implement this.
abstract class NodeVisitor {
  /// Called when a Text node has been reached.
  void visitText(MarkedText text);

  /// Called when an MarkedElement has been reached, before its children have been
  /// visited.
  ///
  /// Returns `false` to skip its children.
  bool visitElementBefore(MarkedElement element);

  /// Called when an MarkedElement has been reached, after its children have been
  /// visited.
  ///
  /// Will not be called if [visitElementBefore] returns `false`.
  void visitElementAfter(MarkedElement element);
}
