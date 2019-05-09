import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' as painting;

typedef DoubleCallback = double Function([double]);

enum GradientType { linear, radial, sweep }

class GradientSpec {
  GradientType type = GradientType.linear;
  Offset from = Offset(-1.0, 0.0), to = Offset(1.0, 0.0), center = Offset(0.0, 0.0), focal;
  double radius = 1.0, focalRadius = 0.0, startAngle = 0.0, endAngle = pi * 2;
  List<Color> colors = <Color>[ Colors.black, Colors.white ];
  List<double> colorStops = <double>[ 0.0, 1.0 ];
  TileMode tileMode = TileMode.clamp;
  Float64List matrix4;

  bool operator == (GradientSpec x) {
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
        return true;
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
    }
  }

  static Offset boxCoords(Offset x, double hw, double hh) =>
    Offset(x.dx * hw + hw, x.dy * hh + hh);
}

class GradientPicker extends StatefulWidget {
  GradientSpec gradient;
  Paint paint;
  GradientPicker(this.gradient, this.paint);

  @override
  _GradientPickerState createState() => _GradientPickerState();
}

class _GradientPickerState extends State<GradientPicker> {
  Size previewSize = Size(100, 100);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      child: ListView(
        shrinkWrap: true,
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

          widget.gradient.type == GradientType.radial ? NumberPicker(
            'Radius', ([double x]) {
              if (x != null) setState(() => widget.gradient.radius = x);
              return widget.gradient.radius;
            }, increment: 0.01,
          ) : null,

          widget.gradient.type == GradientType.radial ? NumberPicker(
            'Focal Radius', ([double x]) {
              if (x != null) setState(() => widget.gradient.focalRadius = x);
              return widget.gradient.focalRadius;
            }, increment: 0.01,
          ) : null,

          widget.gradient.type == GradientType.sweep ? NumberPicker(
            'Start Angle', ([double x]) {
              if (x != null) setState(() => widget.gradient.startAngle = x);
              return widget.gradient.startAngle;
            }, increment: 0.01,
          ) : null,

          widget.gradient.type == GradientType.sweep ? NumberPicker(
            'End Angle', ([double x]) {
              if (x != null) setState(() => widget.gradient.endAngle = x);
              return widget.gradient.endAngle;
            }, increment: 0.01,
          ) : null,

          Card(
            color: Colors.blueGrey[50],
            child: Container(
              height: 100,
              child: ClipRect(
                child: CustomPaint(
                  painter: GradientPainter(widget.paint, widget.gradient),
                ),
              ),
            ),
          ),
        ].where((x) => x != null).toList(),
      ),
    );
  }
}

class GradientPainter extends CustomPainter {
  Paint style;
  GradientSpec gradient;
  GradientPainter(this.style, this.gradient);

  @override
  void paint(Canvas canvas, Size size) {
    style.shader = gradient.build(Rect.fromLTWH(0.0, 0.0, size.width.toDouble(), size.height.toDouble()));
    canvas.drawPaint(style);
  }

  @override
  bool shouldRepaint(GradientPainter oldDelegate) => true;
}

class NumberPicker extends StatefulWidget {
  String title;
  DoubleCallback value;
  double increment = 1.0;
  NumberPicker(this.title, this.value, {this.increment});

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
    controller.text = widget.value().toStringAsFixed(3);

    return ListTile(
      title: Text(widget.title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            padding: const EdgeInsets.all(0.0), 
            icon: Icon(Icons.arrow_left),
            onPressed: () =>
                setState((){ widget.value(widget.value() - widget.increment); }),
          ),

          Container(
            width: 50,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              onChanged: (String v) =>
                setState((){ widget.value(double.parse(v)); }),
            ),
          ),

          IconButton(
            padding: const EdgeInsets.all(0.0), 
            icon: Icon(Icons.arrow_right),
            onPressed: () =>
                setState((){ widget.value(widget.value() + widget.increment); }),
          ),
        ],
      ),
    );
  }
}

class PopupMenuBuilder {
  final Icon icon;
  int nextIndex = 0;
  List<PopupMenuItem<int>> item = <PopupMenuItem<int>>[];
  List<VoidCallback> onSelectedCallback = <VoidCallback>[];

  PopupMenuBuilder({this.icon});

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

  Widget build() {
    return PopupMenuButton(
      icon: icon,
      itemBuilder: (_) => item,
      onSelected: (int v) { onSelectedCallback[v](); }
    );
  }
} 

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
