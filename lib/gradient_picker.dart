import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' as painting;

import 'package:flutter_colorpicker/flutter_colorpicker.dart';

typedef DoubleCallback = double Function([double]);
typedef DoubleItemCallback = void Function(int, double);

enum GradientType { linear, radial, sweep }

class GradientSpec {
  GradientType type = GradientType.linear;
  Offset from = Offset(-1.0, 0.0), to = Offset(1.0, 0.0), center = Offset(0.0, 0.0), focal;
  double radius = 1.0, focalRadius = 0.0, startAngle = 0.0, endAngle = pi * 2;
  List<Color> colors = <Color>[ Colors.black, Colors.white ];
  List<double> colorStops = <double>[ 0.0, 1.0 ];
  TileMode tileMode = TileMode.clamp;
  Float64List matrix4;

  @override
  int get hashCode {
    switch(type) {
      case GradientType.linear:
        return hashValues(from, to, colors, colorStops, tileMode);
      case GradientType.radial:
        return hashValues(center, radius, colors, colorStops, tileMode, matrix4, focal, focalRadius);
      case GradientType.sweep:
        return hashValues(center, colors, colorStops, tileMode, startAngle, endAngle, matrix4);
      default:
        return 0;
    }
  }

  @override
  bool operator == (dynamic other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final GradientSpec x = other;
    if (type != x.type) return false;
    switch(type) {
      case GradientType.linear:
        return from == x.from && to == x.to && colors == x.colors && colorStops == x.colorStops && tileMode == x.tileMode;
      case GradientType.radial:
        return center == x.center && radius == x.radius && colors == x.colors && colorStops == x.colorStops &&
          tileMode == x.tileMode && matrix4 == x.matrix4 && focal == x.focal && focalRadius == x.focalRadius;
      case GradientType.sweep:
        return center == x.center && colors == x.colors && colorStops == x.colorStops &&
          tileMode == x.tileMode && startAngle == x.startAngle && endAngle == x.endAngle && matrix4 == x.matrix4;
      default:
        return false;
    }
  }

  ui.Gradient build(Rect box) {
    double hw = box.width / 2.0, hh = box.height / 2.0;
    switch(type) {
      case GradientType.linear:
        return ui.Gradient.linear(boxCoords(from, hw, hh), boxCoords(to, hw, hh), colors, colorStops, tileMode);
      case GradientType.radial:
        return ui.Gradient.radial(boxCoords(center, hw, hh), radius * (hw + hh), colors, colorStops, tileMode, matrix4, focal, focalRadius);
      case GradientType.sweep:
        return ui.Gradient.sweep(boxCoords(center, hw, hh), colors, colorStops, tileMode, startAngle, endAngle, matrix4);
      default:
        return null;
    }
  }

  painting.Gradient buildPaintingGradient() {
    switch(type) {
      case GradientType.linear:
        return painting.LinearGradient(
          begin:    Alignment(from.dx, from.dy),
          end:      Alignment(to.dx, to.dy),
          colors:   colors,
          stops:    colorStops, 
          tileMode: tileMode
        );
      case GradientType.radial:
        return painting.RadialGradient(
          center: Alignment(center.dx, center.dy),
          radius: radius,
          colors: colors,
          stops: colorStops, 
          tileMode: tileMode,
          focal: focal != null ? Alignment(focal.dx, focal.dy) : null,
          focalRadius: focalRadius,
        );
      case GradientType.sweep:
        return painting.SweepGradient(
          center: Alignment(center.dx, center.dy),
          startAngle: startAngle,
          endAngle: endAngle,
          colors: colors,
          stops: colorStops, 
          tileMode: tileMode
        );
      default:
        return null;
    }
  }

  static Offset boxCoords(Offset x, double hw, double hh) =>
    Offset(x.dx * hw + hw, x.dy * hh + hh);
}

class GradientPicker extends StatefulWidget {
  final GradientSpec gradient;
  GradientPicker(this.gradient);

  @override
  _GradientPickerState createState() => _GradientPickerState();
}

class _GradientPickerState extends State<GradientPicker> {
  Size previewSize = Size(100, 100);
  int selectedColorIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      child: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: <Widget>[
          ListTile(
            title: Text('Type'),
            trailing: DropdownButton<String>(
              value: enumName(widget.gradient.type),
              onChanged: (String val) =>
                setState((){ widget.gradient.type = GradientType.values.firstWhere((x) => enumName(x) == val); }),
              items: buildDropdownMenuItem(GradientType.values.map(enumName).toList()),
            ),
          ),

          ListTile(
            title: Text('Tile Mode'),
            trailing: DropdownButton<String>(
              value: enumName(widget.gradient.tileMode),
              onChanged: (String val) =>
                setState((){ widget.gradient.tileMode = TileMode.values.firstWhere((x) => enumName(x) == val); }),
              items: buildDropdownMenuItem(TileMode.values.map(enumName).toList()),
            ),
          ),

          widget.gradient.type == GradientType.radial ?
            ListTile(
              title: Text('Radius'),
              trailing: NumberPicker(
                ([double x]) {
                  if (x != null) setState(() => widget.gradient.radius = x);
                  return widget.gradient.radius;
                },
                increment: 0.01,
              ),
            ) : null,

          widget.gradient.type == GradientType.radial ?
            ListTile(
              title: Text('Focal Radius'),
              trailing: NumberPicker(
                ([double x]) {
                  if (x != null) setState(() => widget.gradient.focalRadius = x);
                  return widget.gradient.focalRadius;
                },
                increment: 0.01,
              ),
            ) : null,

          widget.gradient.type == GradientType.sweep ?
            ListTile(
              title: Text('Start Angle'),
              trailing: NumberPicker(
                ([double x]) {
                  if (x != null) setState(() => widget.gradient.startAngle = x);
                  return widget.gradient.startAngle;
                },
                increment: 0.01,
              ),
            ) : null,

          widget.gradient.type == GradientType.sweep ?
            ListTile(
              title: Text('End Angle'),
              trailing: NumberPicker(
                ([double x]) {
                  if (x != null) setState(() => widget.gradient.endAngle = x);
                  return widget.gradient.endAngle;
                },
                increment: 0.01,
              ),
            ) : null,

          Card(
            color: Colors.blueGrey[50],
            child: Container(
              height: 100,
              child: ClipRect(
                child: CustomPaint(
                  painter: GradientPainter(widget.gradient),
                ),
              ),
            ),
          ),
          
          MultiSlider(widget.gradient.colorStops,
            gradient: painting.LinearGradient(
              begin:    Alignment(-1.0, 0.0),
              end:      Alignment( 1.0, 0.0),
              colors:   widget.gradient.colors,
              stops:    widget.gradient.colorStops, 
              tileMode: widget.gradient.tileMode
            ),
          ),

          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  padding: const EdgeInsets.all(0.0), 
                  icon: Icon(Icons.arrow_left),
                  onPressed: () =>
                      setState(() => selectedColorIndex = (selectedColorIndex-1).clamp(0, widget.gradient.colors.length-1)),
                ),
              
                Text('Color ' + (selectedColorIndex + 1).toString()),
               
                IconButton(
                  padding: const EdgeInsets.all(0.0), 
                  icon: Icon(Icons.arrow_right),
                  onPressed: () =>
                      setState(() => selectedColorIndex = (selectedColorIndex+1).clamp(0, widget.gradient.colors.length-1)),
                ),
              ],
            ),
          ),

          ColorPicker(
            pickerColor: widget.gradient.colors[selectedColorIndex],
            onColorChanged: (Color x) => setState(() => widget.gradient.colors[selectedColorIndex] = x),
            enableLabel: false,
            pickerAreaHeightPercent: 0.35,
          ),

        ].where((x) => x != null).toList(),
      ),
    );
  }
}

class GradientPainter extends CustomPainter {
  GradientSpec gradient;
  GradientPainter(this.gradient);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPaint(Paint()
      ..shader = gradient.build(Rect.fromLTWH(0.0, 0.0, size.width.toDouble(), size.height.toDouble()))
    );
  }

  @override
  bool shouldRepaint(GradientPainter oldDelegate) => true;
}

class NumberPicker extends StatefulWidget {
  final DoubleCallback value;
  final double width, increment;
  final int fixed;
  NumberPicker(this.value, {this.width=50.0, this.increment=1.0, this.fixed=3});

  @override
  _NumberPickerState createState() => _NumberPickerState();
}

class _NumberPickerState extends State<NumberPicker> {
  TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    controller.text = widget.value().toStringAsFixed(widget.fixed);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          padding: const EdgeInsets.all(0.0), 
          icon: Icon(Icons.arrow_left),
          onPressed: () =>
              setState(() => widget.value(widget.value() - widget.increment)),
        ),

        Container(
          width: widget.width,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.right,
            keyboardType: TextInputType.number,
            onChanged: (String v) =>
              setState(() => widget.value(double.parse(v))),
          ),
        ),

        IconButton(
          padding: const EdgeInsets.all(0.0), 
          icon: Icon(Icons.arrow_right),
          onPressed: () =>
              setState(() => widget.value(widget.value() + widget.increment)),
        ),
      ],
    );
  }
}

class MultiSlider extends StatefulWidget {
  final List<double> positions;
  final DoubleItemCallback onChanged;
  final Gradient gradient;
  final Color selectColor;

  MultiSlider(this.positions, {this.onChanged, this.gradient, this.selectColor=const Color.fromRGBO(37, 213, 253, 1.0)});

  @override
  _MultiSliderState createState() => _MultiSliderState();
}

class _MultiSliderState extends State<MultiSlider> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) =>
          Stack(children: buildSliders(constraints)),
      ), 
    );
  }

  List<Widget> buildSliders(BoxConstraints constraints) {
    assert(constraints.minWidth == constraints.maxWidth);

    List<Widget> ret = <Widget>[
      Container(
        color: widget.gradient != null ? null : Colors.grey,
        height: 4,
        margin: EdgeInsets.fromLTRB(0, 18, 0, 18),
        decoration: widget.gradient == null ? null : BoxDecoration(
           gradient: widget.gradient,
        ),
      ),
    ];

    for (double position in widget.positions)
      ret.add(
        Positioned.fromRect(
          rect: centerRect(
            Rect.fromLTWH(0, 0, 40, 40),
            Offset(position * constraints.maxWidth, 20)
          ),
          child: Icon(Icons.open_with,
            color: widget.selectColor,
          ),
        ),
      );
    return ret;
  }
}

class PopupMenuBuilder {
  int nextIndex = 0;
  List<PopupMenuItem<int>> item = <PopupMenuItem<int>>[];
  List<VoidCallback> onSelectedCallback = <VoidCallback>[];

  PopupMenuBuilder addItem({Icon icon, String text, VoidCallback onSelected}) {
    onSelectedCallback.add(onSelected);
    if (icon != null) {
      item.add(
        PopupMenuItem<int>(
          child: Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8.0),
                child: icon
              ),
              Container(
                padding: const EdgeInsets.all(10.0),
                child: Text(text),
              ),
            ],
          ),
          value: nextIndex++
        )
      );
    } else {
      item.add(
        PopupMenuItem<int>(
          child: Text(text),
          value: nextIndex++
        )
      );
    }
    return this;
  }

  Widget build({Icon icon, Widget child}) {
    return PopupMenuButton(
      icon: icon,
      child: child,
      itemBuilder: (_) => item,
      onSelected: (int v) { onSelectedCallback[v](); }
    );
  }
} 

Rect rectFromSize(Size x) => Rect.fromLTWH(0, 0, x.width, x.height);

Rect centerRect(Rect x, Offset c) =>
  Rect.fromLTWH(c.dx - x.width / 2.0, c.dy - x.height / 2.0, x.width, x.height);

String enumName(var x) {
  String ret = x.toString().split('.')[1];
  return ret.length > 0 ? ret[0].toUpperCase() + ret.substring(1) : ret;
}

List<DropdownMenuItem<String>> buildDropdownMenuItem(List<String> x) {
  return x.map<DropdownMenuItem<String>>(
    (String value) => DropdownMenuItem<String>(
      value: value,
      child: Text(value),
    )
  ).toList();
}

Widget buildDragRecognizer(Widget child, GestureMultiDragStartCallback onStart, {VoidCallback onTap}) {
  var gestures = <Type, GestureRecognizerFactory> {
    ImmediateMultiDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<ImmediateMultiDragGestureRecognizer>(
      () => ImmediateMultiDragGestureRecognizer(),
      (ImmediateMultiDragGestureRecognizer instance) {
        instance..onStart = onStart;
      }
    )
  };
  if (onTap != null) {
    gestures[TapGestureRecognizer] = GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
      () => TapGestureRecognizer(),
      (TapGestureRecognizer instance) {
        instance..onTap = onTap;
      }
    );
  }
  return RawGestureDetector(
    child: child,
    behavior: HitTestBehavior.opaque,
    gestures: gestures,
  );
}
