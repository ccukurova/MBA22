import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class LineChart extends StatefulWidget {
  final List<LineData> lineData;

  LineChart({required this.lineData});

  @override
  LineChartState createState() => LineChartState();
}

class LineChartState extends State<LineChart> {
  // declare state variables here

  @override
  void initState() {
    super.initState();
    // initialize state variables here
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 500,
        height: 500,
        child: SfCartesianChart(
            // Initialize category axis
            title: ChartTitle(text: 'Profit'),
            // Enable legend
            legend: Legend(isVisible: true),
            // Enable tooltip
            tooltipBehavior: TooltipBehavior(enable: true),
            primaryXAxis: CategoryAxis(),
            series: <LineSeries<LineData, String>>[
              LineSeries<LineData, String>(
                  // Bind data source
                  dataSource: widget.lineData,
                  xValueMapper: (LineData data, _) => data.month,
                  yValueMapper: (LineData data, _) => data.profit),
            ]));
  }
}

class LineData {
  LineData(this.month, this.profit);
  final String month;
  final double profit;
}
