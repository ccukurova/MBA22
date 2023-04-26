import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class LineChart extends StatefulWidget {
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
            title: ChartTitle(text: 'Income'),
            // Enable legend
            legend: Legend(isVisible: true),
            // Enable tooltip
            tooltipBehavior: TooltipBehavior(enable: true),
            primaryXAxis: CategoryAxis(),
            series: <LineSeries<SalesData2, String>>[
              LineSeries<SalesData2, String>(
                  // Bind data source
                  dataSource: <SalesData2>[
                    SalesData2('Jan', -100000),
                    SalesData2('Feb', -40000),
                    SalesData2('Mar', 34000),
                    SalesData2('Apr', 60000),
                    SalesData2('May', 100000),
                    SalesData2('Jun', 70000),
                  ],
                  xValueMapper: (SalesData2 sales, _) => sales.year,
                  yValueMapper: (SalesData2 sales, _) => sales.sales),
            ]));
  }
}

class SalesData2 {
  SalesData2(this.year, this.sales);
  final String year;
  final double sales;
}
