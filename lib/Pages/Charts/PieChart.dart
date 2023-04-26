import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class PieChart extends StatefulWidget {
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
    List<_PieData> pieData = [
      _PieData("category1", 10, "category1"),
      _PieData("category2", 20, "category2"),
      _PieData("category3", 30, "category3"),
      _PieData("category4", 30, "category4"),
      _PieData("category5", 10, "category5"),
      _PieData("category6", 20, "category6"),
      _PieData("category7", 30, "category7"),
      _PieData("category8", 10, "category8"),
      _PieData("category9", 20, "category9"),
      _PieData("category10", 30, "category10"),
      _PieData("category11", 30, "category11"),
      _PieData("category12", 10, "category12"),
    ];
    return Container(
      width: 500,
      height: 500,
      child: SfCircularChart(
          title: ChartTitle(text: 'Categories'),
          series: <PieSeries<_PieData, String>>[
            PieSeries<_PieData, String>(
                explode: true,
                explodeIndex: 0,
                dataSource: pieData,
                xValueMapper: (_PieData data, _) => data.xData,
                yValueMapper: (_PieData data, _) => data.yData,
                dataLabelMapper: (_PieData data, _) => data.text,
                dataLabelSettings: DataLabelSettings(isVisible: true)),
          ]),
    );
  }
}

class _PieData {
  _PieData(this.xData, this.yData, this.text);
  final String xData;
  final num yData;
  final String text;
}
