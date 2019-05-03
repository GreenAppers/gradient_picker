
enum GradientType { linear, radial, sweep }

class _GradientPicker extends StatefulWidget {
  Paint paint;
  _GradientPicker(this.paint);

  @override
  _GradientPickerState createState() => _GradientPickerState();
}

class _GradientPickerState extends State<_GradientPicker> {
  @override
  Widget build(BuildContext context) {
    widthController.text = widget.paint.strokeWidth.toString();
    return Container(
      width: double.maxFinite,
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          ListTile(
            title: Text('Type'),
            trailing: DropdownButton<String>(
              value: enumName(widget.paint.strokeCap),
              onChanged: (String val) =>
                setState((){ widget.paint.strokeCap = StrokeCap.values.firstWhere((x) => enumName(x) == val); }),
              items: _buildDropdownMenuItem(StrokeCap.values.map(enumName).toList()),
            ),
          ),

          Card(
            color: Colors.blueGrey[50],
            child: Container(
              width: 100,
              height: 100,
              child: CustomPaint(
                painter: _BrushPainter(widget.paint),
              ),
            ),
          ),
        ]
      ),
    );
  }
}

List<DropdownMenuItem<String>> _buildDropdownMenuItem(List<String> x) {
  return x.map<DropdownMenuItem<String>>(
    (String value) => DropdownMenuItem<String>(
      value: value,
      child: Text(value),
    )
  ).toList();
}

