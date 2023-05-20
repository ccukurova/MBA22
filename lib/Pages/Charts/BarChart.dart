import 'package:flutter/material.dart';

import 'package:syncfusion_flutter_charts/charts.dart';

class BarChart extends StatefulWidget {
  final List<BarData> revenueData;
  final List<BarData> expenseData;
  const BarChart({required this.revenueData, required this.expenseData});
  BarChartState createState() => BarChartState();
}

class BarChartState extends State<BarChart> {
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
          tooltipBehavior: TooltipBehavior(enable: true),
          primaryXAxis: CategoryAxis(),
          title: ChartTitle(text: 'Revenue-Expense'),
          legend: Legend(isVisible: true),
          series: <ChartSeries>[
            ColumnSeries<BarData, String>(
              name: 'Revenue',
              dataSource: widget.revenueData,
              xValueMapper: (revenueData, _) => revenueData.month,
              yValueMapper: (revenueData, _) => revenueData.total,
              yAxisName: 'Primary Axis',
            ),
            ColumnSeries<BarData, String>(
              name: 'Expense',
              dataSource: widget.expenseData,
              xValueMapper: (expenseData, _) => expenseData.month,
              yValueMapper: (expenseData, _) => expenseData.total,
              yAxisName: 'Secondary Axis',
            ),
          ],
        ));
  }
}

class BarData {
  String month;
  double total;

  BarData(this.month, this.total);
}
