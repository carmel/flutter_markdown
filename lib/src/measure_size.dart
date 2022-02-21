import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

typedef OnWidgetSizeChange = void Function(int index, Size size);

class MeasureSizeRenderObject extends RenderProxyBox {
  Size? oldSize;
  final int index;
  final OnWidgetSizeChange onChange;

  MeasureSizeRenderObject(this.index, this.onChange);

  @override
  void performLayout() {
    super.performLayout();

    Size newSize = child!.size;
    if (oldSize == newSize) return;

    oldSize = newSize;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      onChange(index, newSize);
    });
  }
}

class MeasureSize extends SingleChildRenderObjectWidget {
  final OnWidgetSizeChange onChange;
  final int index;

  const MeasureSize({
    Key? key,
    required this.index,
    required this.onChange,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return MeasureSizeRenderObject(index, onChange);
  }
}
