/*
 * Copyright (C) 2017, David PHAM-VAN <dev.nfet.net@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// ignore_for_file: omit_local_variable_types

import 'dart:ui' as ui;

import 'package:barcode/barcode.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class BarcodePainter extends LeafRenderObjectWidget {
  BarcodePainter(
    this.data,
    this.barcode,
    this.color,
    this.drawText,
    this.style,
  ) : super();

  final String data;

  final Barcode barcode;

  final Color color;

  final bool drawText;

  final TextStyle style;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderBarcode(
      data,
      barcode,
      Paint()..color = color,
      drawText,
      style,
    );
  }
}

class RenderBarcode extends RenderBox {
  RenderBarcode(
    this.data,
    this.barcode,
    this.barStyle,
    this.drawText,
    this.style,
  );

  final String data;

  final Barcode barcode;

  final Paint barStyle;

  final bool drawText;

  final TextStyle style;

  @override
  bool get sizedByParent => true;

  @override
  void performResize() {
    Size _size = constraints.biggest;

    if (_size.width >= double.infinity) {
      if (_size.height >= double.infinity) {
        _size = Size(200, 100);
      } else {
        _size = Size(_size.height * 2, _size.height);
      }
    }
    if (_size.height >= double.infinity) {
      _size = Size(_size.width, _size.width / 2);
    }

    size = _size;
  }

  void paintBar(PaintingContext context, Offset offset, BarcodeBar element) {
    if (!element.black) {
      return;
    }

    context.canvas.drawRect(
      Rect.fromLTWH(
        offset.dx + element.left,
        offset.dy + element.top,
        element.width,
        element.height,
      ),
      barStyle,
    );
  }

  void paintText(PaintingContext context, Offset offset, BarcodeText element) {
    final builder = ui.ParagraphBuilder(
      style.getParagraphStyle(
          textAlign: TextAlign.center,
          fontSize: element.height,
          maxLines: 1,
          ellipsis: '...'),
    )
      ..pushStyle(style.getTextStyle())
      ..addText(element.text);

    final paragraph = builder.build();
    paragraph.layout(ui.ParagraphConstraints(width: element.width));

    context.canvas.drawParagraph(
      paragraph,
      Offset(offset.dx + element.left, offset.dy + element.top),
    );
  }

  void drawError(PaintingContext context, ui.Offset offset, String message) {
    final RenderErrorBox errorBox = RenderErrorBox(message);
    errorBox.layout(constraints);
    errorBox.paint(context, offset);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    try {
      for (BarcodeElement element in barcode.make(
        data,
        width: size.width,
        height: size.height,
        drawText: drawText,
        fontHeight: style.fontSize,
      )) {
        if (element is BarcodeBar) {
          paintBar(context, offset, element);
        } else if (element is BarcodeText) {
          paintText(context, offset, element);
        }
      }
    } on BarcodeException catch (error) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        library: 'Barcode Widget',
      ));

      assert(() {
        drawError(context, offset, error.message);
        return true;
      }());
    }
  }
}