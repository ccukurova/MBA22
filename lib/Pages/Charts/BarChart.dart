import 'package:flutter/material.dart';

import 'package:syncfusion_flutter_charts/charts.dart';

class BarChart extends StatefulWidget {
  @override
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
            ColumnSeries<SalesData, String>(
              name: 'Revenue',
              dataSource: <SalesData>[
                SalesData('Jan', 25000.53),
                SalesData('Feb', 34567.32),
                SalesData('Mar', 34567),
                SalesData('Apr', 29780),
                SalesData('May', 42657.45),
              ],
              xValueMapper: (SalesData sales, _) => sales.month,
              yValueMapper: (SalesData sales, _) => sales.sales,
              yAxisName: 'Primary Axis',
            ),
            ColumnSeries<SalesData, String>(
              name: 'Expense',
              dataSource: <SalesData>[
                SalesData('Jan', 42657.45),
                SalesData('Feb', 29780),
                SalesData('Mar', 45587.43),
                SalesData('Apr', 23876.32),
                SalesData('May', 15000),
              ],
              xValueMapper: (SalesData sales, _) => sales.month,
              yValueMapper: (SalesData sales, _) => sales.sales,
              yAxisName: 'Secondary Axis',
            ),
          ],
        ));
  }
}

class SalesData {
  final String month;
  final double sales;

  SalesData(this.month, this.sales);
}
