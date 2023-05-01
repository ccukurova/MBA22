import 'package:MBA22/Pages/Charts/LineChart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:MBA22/Pages/LeftDrawer.dart';
import '../Helpers/SharedPreferencesManager.dart';
import '../Models/TransactionModel.dart';
import 'Charts/BarChart.dart';
import 'LeftDrawer.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_charts/sparkcharts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'Charts/PieChart.dart';
import 'package:MBA22/Services/RatesRequester.dart';
import '../constants.dart';

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
    prefs.getString("userID").then((value) {
      setState(() {
        currentUserID = value;
      });
    });
    prefs.getString("ledgerID").then((value) {
      setState(() {
        currentLedgerID = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    checkForFutureTransactions(currentLedgerID!);
    ExchangerateRequester requester = new ExchangerateRequester();
    Future<double> rate = requester.getRate('EUR', 'TRY', 1000);
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
            items: [
              FutureBuilder<List<PieData>>(
                future: getPieList(currentLedgerID!),
                builder: (BuildContext context,
                    AsyncSnapshot<List<PieData>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasError) {
                      print('Error: ${snapshot.error}');
                      return Text('Error: ${snapshot.error}');
                    } else if (snapshot.data!.isEmpty) {
                      PieData noData = PieData(
                          "No data available.", 1, "No data available.");
                      List<PieData> noDataList = [noData];
                      return PieChart(pieData: noDataList);
                    } else {
                      return PieChart(pieData: snapshot.data!);
                    }
                  } else {
                    return CircularProgressIndicator();
                  }
                },
              ),
              FutureBuilder<List<LineData>>(
                future: getLineList(currentLedgerID!),
                builder: (BuildContext context,
                    AsyncSnapshot<List<LineData>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasError) {
                      print('Error: ${snapshot.error}');
                      return Text('Error: ${snapshot.error}');
                    } else {
                      return LineChart(lineData: snapshot.data!);
                    }
                  } else {
                    return CircularProgressIndicator();
                  }
                },
              ),
              BarChart(),
              LatestExchangeRates()
            ].map((i) {
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
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: <
                      Widget>[
                    Text(
                      'Net:',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10),
                    FutureBuilder<double>(
                      future: getSumOfRevenue(currentLedgerID!),
                      builder: (context, revenueSnapshot) {
                        if (revenueSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (revenueSnapshot.hasError) {
                          return Center(child: Text("Error loading revenue"));
                        }
                        return FutureBuilder<double>(
                          future: getSumOfExpense(currentLedgerID!),
                          builder: (context, expenseSnapshot) {
                            if (expenseSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (expenseSnapshot.hasError) {
                              return Center(
                                  child: Text("Error loading expenses"));
                            }
                            final double revenue = revenueSnapshot.data ?? 0;
                            final double expense = expenseSnapshot.data ?? 0;
                            final double balance = revenue - expense;
                            return Center(
                              child: Text(
                                balance.toString(),
                                style: TextStyle(
                                  fontSize: 24.0,
                                  color: Colors.grey[600],
                                ),
                              ),
                            );
                          },
                        );
                      },
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
                        FutureBuilder<double>(
                          future: getSumOfRevenue(currentLedgerID!),
                          builder: (BuildContext context,
                              AsyncSnapshot<double> snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              // While the future is being fetched, display a loading spinner
                              return CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              // If there was an error fetching the data, display an error message
                              return Text('Error: ${snapshot.error}');
                            } else {
                              // If the future has completed successfully, display the data
                              return Text(
                                snapshot.data.toString(),
                                style: TextStyle(
                                  fontSize: 18.0,
                                  color: Colors.green,
                                ),
                              );
                            }
                          },
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
                        FutureBuilder<double>(
                          future: getSumOfExpense(currentLedgerID!),
                          builder: (BuildContext context,
                              AsyncSnapshot<double> snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              // While the future is being fetched, display a loading spinner
                              return CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              // If there was an error fetching the data, display an error message
                              return Text('Error: ${snapshot.error}');
                            } else {
                              // If the future has completed successfully, display the data
                              return Text(
                                snapshot.data.toString(),
                                style: TextStyle(
                                  fontSize: 18.0,
                                  color: Colors.red,
                                ),
                              );
                            }
                          },
                        )
                      ]),
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

  Future<double> getSumOfRevenue(String ledgerID) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference transactions = firestore.collection('transactions');
    Query userAccountTransactions = transactions
        .where('ledgerID', isEqualTo: ledgerID)
        .where('isActive', isEqualTo: true)
        .where('transactionType', whereIn: ['Sell', 'Collection', 'Decrease']);

    double totalRevenue = 0;

    try {
      QuerySnapshot snapshot = await userAccountTransactions.get();
      snapshot.docs.forEach((DocumentSnapshot doc) {
        totalRevenue += doc['totalPrice'];
        print(doc['totalPrice']);
      });
    } catch (error) {
      print('Error getting transactions: $error');
    }

    return totalRevenue;
  }

  Future<double> getSumOfExpense(String ledgerID) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference transactions = firestore.collection('transactions');
    Query userAccountTransactions = transactions
        .where('ledgerID', isEqualTo: ledgerID)
        .where('isActive', isEqualTo: true)
        .where('transactionType', whereIn: ['Buy', 'Payment', 'Increase']);

    double totalExpense = 0;

    try {
      QuerySnapshot snapshot = await userAccountTransactions.get();
      snapshot.docs.forEach((DocumentSnapshot doc) {
        print(doc['totalPrice']);
        totalExpense += doc['totalPrice'];
      });
    } catch (error) {
      print('Error getting transactions: $error');
    }

    return totalExpense;
  }

  Future<List<PieData>> getPieList(String ledgerID) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference transactions = firestore.collection('transactions');
    List<PieData> pieData = [];
    List<String> categoryList = [];

    Query userAccounts = transactions
        .where('ledgerID', isEqualTo: ledgerID)
        .where('isActive', isEqualTo: true);

    try {
      QuerySnapshot snapshot = await userAccounts.get();
      snapshot.docs.forEach((DocumentSnapshot doc) {
        if (doc['transactionType'] == 'Buy' ||
            doc['transactionType'] == 'Payment') {
          categoryList.add(doc['categoryName']);
        }
      });
      categoryList.forEach((selectedCategory) {
        int counter = 0;
        categoryList.forEach((category) {
          if (selectedCategory == category) {
            counter++;
          }
        });
        PieData newData = PieData(selectedCategory, counter, selectedCategory);
        pieData.add(newData);
      });
      return pieData;
    } catch (error) {
      print('Error getting transactions: $error');
    }

    return pieData;
  }

  Future<List<LineData>> getLineList(String ledgerID) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference transactions = firestore.collection('transactions');
    List<String> months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    int previousMonthOrder = DateTime.now().month - 1;
    String previousMonth = months.elementAt(previousMonthOrder - 1);
    List<String> selectedMonths = [];
    for (int monthCounter = 0; monthCounter < 6; monthCounter++) {
      if (previousMonthOrder == 0) {
        previousMonthOrder = 12;
      }
      selectedMonths.add(months.elementAt(previousMonthOrder - 1));
      previousMonthOrder--;
    }
    selectedMonths = selectedMonths.reversed.toList();
    Query userFutureTransactions = transactions
        .where('ledgerID', isEqualTo: ledgerID)
        .where('isActive', isEqualTo: true);

    return <LineData>[
      LineData('Jan', -100000),
      LineData('Feb', -40000),
      LineData('Mar', 34000),
      LineData('Apr', 60000),
      LineData('May', 100000),
      LineData('Jun', 70000),
    ];
  }

  Future<void> checkForFutureTransactions(String ledgerID) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference transactions = firestore.collection('transactions');

    Query userFutureTransactions = transactions
        .where('ledgerID', isEqualTo: ledgerID)
        .where('isDone', isEqualTo: false)
        .where('isActive', isEqualTo: true);

    QuerySnapshot snapshot = await userFutureTransactions.get();
    snapshot.docs.forEach((DocumentSnapshot doc) {
      DateTime targetDate = (doc['targetDate'] as Timestamp).toDate();
      if (targetDate != DateTime(0)) {
        int dateTimeCompare = targetDate.compareTo(DateTime.now());

        if (dateTimeCompare <= 0) {
          doc.reference.update({'isDone': true, 'targetDate': DateTime(0)});

          if (doc['duration'] > 0) CreateFutureTransaction(doc);
        }
      }
    });
  }

  int _daysInMonth(int year, int month) {
    var date = DateTime(year, month);
    var lastDay = DateTime(date.year, date.month + 1, 0);
    return lastDay.day;
  }

  Future<void> CreateFutureTransaction(DocumentSnapshot doc) async {
    String? currentLedgerID = await prefs.getString("ledgerID");
    var newTransaction;
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference transactions = firestore.collection('transactions');
    bool isDone = false;
    DateTime targetDate = (doc['targetDate'] as Timestamp).toDate();
    DateTime nextTargetDate = DateTime(0);
    //   Period can be:
    //   'For once',
    //   'Every day'
    //   'Every week',
    //   'Every month',
    //   'Every year'
    if ('period' == 'Every day') {
      nextTargetDate = targetDate.add(Duration(days: 1));
    } else if ('period' == 'Every week') {
      nextTargetDate = targetDate.add(Duration(days: 7));
    } else if ('period' == 'Every month') {
      nextTargetDate = targetDate
          .add(Duration(days: _daysInMonth(targetDate.year, targetDate.month)));
    } else if ('period' == 'Every year') {
      nextTargetDate = targetDate.add(Duration(days: 365));
    }
    if (doc['duration'] - 1 <= 0) {
      isDone = true;
      nextTargetDate = DateTime(0);
    }

    try {
      newTransaction = TransactionModel(
          accountID: doc['accountID'],
          ledgerID: doc['ledgerID'],
          stockID: doc['stockID'],
          transactionType: doc['transactionType'],
          amount: doc['amount'],
          totalPrice: doc['totalPrice'],
          price: doc['price'],
          transactionDetail: doc['transactionDetail'],
          categoryName: doc['categoryName'],
          period: doc['period'],
          duration: doc['duration'] - 1,
          targetDate: nextTargetDate,
          isDone: isDone,
          createDate: doc['createDate'],
          updateDate: doc['updateDate'],
          isActive: true);

      DocumentReference transactionsDoc = await transactions.add({
        'accountID': newTransaction.accountID,
        'ledgerID': newTransaction.ledgerID,
        'stockID': newTransaction.stockID,
        'transactionType': newTransaction.transactionType,
        'amount': newTransaction.amount,
        'totalPrice': newTransaction.totalPrice,
        'price': newTransaction.price,
        'transactionDetail': newTransaction.transactionDetail,
        'categoryName': newTransaction.categoryName,
        'period': newTransaction.period,
        'duration': newTransaction.duration,
        'targetDate': newTransaction.targetDate,
        'isDone': newTransaction.isDone,
        'createDate': Timestamp.fromDate(newTransaction.createDate),
        'updateDate': Timestamp.fromDate(newTransaction.updateDate),
        'isActive': newTransaction.isActive
      });
    } catch (e) {
      print('Error caught: $e');
    }
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
