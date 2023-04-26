import 'package:MBA22/Pages/Charts/LineChart.dart';
import 'package:flutter/material.dart';
import 'package:MBA22/Pages/LeftDrawer.dart';
import '../Helpers/SharedPreferencesManager.dart';
import 'Charts/BarChart.dart';
import 'LeftDrawer.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_charts/sparkcharts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'Charts/PieChart.dart';
import 'package:MBA22/Services/RatesRequester.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPage createState() => _MainPage();
}

class _MainPage extends State<MainPage> {
  String? currentUserID;
  String? currentLedgerID;
  final SharedPreferencesManager prefs = SharedPreferencesManager();
  int touchedGroupIndex = -1;
  CarouselController buttonCarouselController = CarouselController();

  TooltipBehavior _tooltipBehavior = TooltipBehavior(enable: true);
  @override
  void initState() {
    super.initState();
    // prefs.getString("userID").then((value) {
    //   setState(() {
    //     currentUserID = value;
    //   });
    // });
    // prefs.getString("ledgerID").then((value) {
    //   setState(() {
    //     currentLedgerID = value;
    //   });
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Main Page'),
      ),
      drawer: LeftDrawer(),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(children: [
          CarouselSlider(
            carouselController: buttonCarouselController,
            options: CarouselOptions(
              height: 400,
              aspectRatio: 16 / 9,
              viewportFraction: 0.8,
              initialPage: 0,
              enableInfiniteScroll: true,
              reverse: false,
              autoPlay: false,
              enlargeCenterPage: true,
              enlargeFactor: 0.3,
              scrollDirection: Axis.horizontal,
            ),
            items: [PieChart(), LineChart(), BarChart(), LatestExchangeRates()]
                .map((i) {
              return Builder(
                builder: (BuildContext context) {
                  return i;
                },
              );
            }).toList(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => buttonCarouselController.previousPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.linear),
                child: Text('←'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0.0),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => buttonCarouselController.nextPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.linear),
                child: Text('→'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0.0),
                  ),
                ),
              )
            ],
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'Net:',
                          style: TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          '30000',
                          style: TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ]),
                  SizedBox(height: 10.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Row(children: [
                        Text(
                          'Revenue:',
                          style: TextStyle(
                            fontSize: 18.0,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '50000',
                          style: TextStyle(
                            fontSize: 18.0,
                            color: Colors.green,
                          ),
                        )
                      ]),
                      SizedBox(width: 30),
                      Row(children: [
                        Text(
                          'Expense:',
                          style: TextStyle(
                            fontSize: 18.0,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '20000',
                          style: TextStyle(
                            fontSize: 18.0,
                            color: Colors.red,
                          ),
                        )
                      ])
                    ],
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

Widget LatestExchangeRates() {
  ExchangerateRequester requester = new ExchangerateRequester();
  return Container(
      width: 500,
      height: 500,
      child: FutureBuilder<Map<String, double>>(
        future: requester.requestAll('TRY'),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final currency = snapshot.data!.keys.elementAt(index);
                final rate = snapshot.data![currency];
                return ListTile(
                  title: Text(currency),
                  trailing: Text(rate.toString()),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ));
}
