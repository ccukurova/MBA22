import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class PieChart extends StatefulWidget {
  final List<PieData> pieData;

  PieChart({required this.pieData});

  @override
  PieChartState createState() => PieChartState();
}

class PieChartState extends State<PieChart> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 600),
      height: MediaQuery.of(context).size.height / 2,
      child: SfCircularChart(series: <PieSeries<PieData, String>>[
        PieSeries<PieData, String>(
            explode: true,
            explodeIndex: 0,
            dataSource: widget.pieData,
            xValueMapper: (PieData data, _) => data.xData,
            yValueMapper: (PieData data, _) => data.yData,
            dataLabelMapper: (PieData data, _) => data.text,
            dataLabelSettings: DataLabelSettings(isVisible: true)),
      ]),
    );
  }
}

class PieData {
  PieData(this.xData, this.yData, this.text);
  final String xData;
  final num yData;
  final String text;
}
