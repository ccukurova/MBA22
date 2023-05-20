import 'package:MBA22/Pages/Charts/LineChart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:MBA22/Pages/LeftDrawer.dart';
import '../Helpers/SharedPreferencesManager.dart';
import '../Models/TransactionModel.dart';
import 'AccountTransactionPage.dart';
import 'Charts/BarChart.dart';
import 'LeftDrawer.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_charts/sparkcharts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'Charts/PieChart.dart';
import '../Services/ExchangerateRequester.dart';
import '../constants.dart';
import 'package:intl/intl.dart';

class MainPage extends StatefulWidget {
  final String currentLedgerID;
  MainPage(this.currentLedgerID);
  @override
  _MainPage createState() => _MainPage();
}

class _MainPage extends State<MainPage> {
  final SharedPreferencesManager prefs = SharedPreferencesManager();
  int touchedGroupIndex = -1;
  CarouselController buttonCarouselController = CarouselController();
  double sumOfRevenue = 0.0;
  double sumOfExpense = 0.0;

  TooltipBehavior _tooltipBehavior = TooltipBehavior(enable: true);

  Future<void> setSumOfRevenue() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference transactions = firestore.collection('transactions');
    Query userAccountTransactions = transactions
        .where('ledgerID', isEqualTo: widget.currentLedgerID)
        .where('isActive', isEqualTo: true)
        .where('isDone', isEqualTo: true)
        .where('transactionType',
            whereIn: ['Sell', 'Collection', 'Decrease', 'Income']);

    double totalRevenue = 0;

    try {
      QuerySnapshot snapshot = await userAccountTransactions.get();
      ExchangerateRequester requester = new ExchangerateRequester();
      for (DocumentSnapshot doc in snapshot.docs) {
        double convertedCurrency =
            await requester.getRate(doc['currencies'][0], 'TRY', doc['total']);
        totalRevenue += convertedCurrency;
      }
    } catch (error) {
      print('Error getting transactions: $error');
    }
    setState(() {
      sumOfRevenue = totalRevenue;
    });
  }

  Future<void> setSumOfExpense() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference transactions = firestore.collection('transactions');
    Query userAccountTransactions = transactions
        .where('ledgerID', isEqualTo: widget.currentLedgerID)
        .where('isActive', isEqualTo: true)
        .where('isDone', isEqualTo: true)
        .where('transactionType',
            whereIn: ['Buy', 'Payment', 'Increase', 'Outcome']);

    double totalExpense = 0;

    try {
      QuerySnapshot snapshot = await userAccountTransactions.get();
      ExchangerateRequester requester = new ExchangerateRequester();
      for (DocumentSnapshot doc in snapshot.docs) {
        double convertedCurrency =
            await requester.getRate(doc['currencies'][0], 'TRY', doc['total']);
        totalExpense += convertedCurrency;
      }
    } catch (error) {
      print('Error getting transactions: $error');
    }
    setState(() {
      sumOfExpense = totalExpense;
    });
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      await checkForFutureTransactions(widget.currentLedgerID);
      await Future.wait([
        setSumOfRevenue(),
        setSumOfExpense(),
      ]);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    ExchangerateRequester requester = new ExchangerateRequester();
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
                future: getPieList(widget.currentLedgerID),
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
                future: getLineList(widget.currentLedgerID!),
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
              FutureBuilder<List<BarData>>(
                future: getRevenueBarList(widget.currentLedgerID!),
                builder: (BuildContext context,
                    AsyncSnapshot<List<BarData>> revenueListSnapshot) {
                  if (revenueListSnapshot.connectionState ==
                      ConnectionState.done) {
                    if (revenueListSnapshot.hasError) {
                      print('Error: ${revenueListSnapshot.error}');
                      return Text('Error: ${revenueListSnapshot.error}');
                    } else {
                      return FutureBuilder<List<BarData>>(
                        future: getExpenseBarList(widget.currentLedgerID!),
                        builder: (BuildContext context,
                            AsyncSnapshot<List<BarData>> expenseListSnapshot) {
                          if (expenseListSnapshot.connectionState ==
                              ConnectionState.done) {
                            if (expenseListSnapshot.hasError) {
                              print('Error: ${expenseListSnapshot.error}');
                              return Text(
                                  'Error: ${expenseListSnapshot.error}');
                            } else {
                              return BarChart(
                                  revenueData: revenueListSnapshot.data!,
                                  expenseData: expenseListSnapshot.data!);
                            }
                          } else {
                            return CircularProgressIndicator();
                          }
                        },
                      );
                    }
                  } else {
                    return CircularProgressIndicator();
                  }
                },
              ),
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
                          if (sumOfRevenue - sumOfExpense > 0)
                            Center(
                              child: Text(
                                (sumOfRevenue - sumOfExpense)
                                    .toStringAsFixed(2),
                                style: TextStyle(
                                  fontSize: 24.0,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          if (sumOfRevenue - sumOfExpense < 0)
                            Center(
                              child: Text(
                                (sumOfRevenue - sumOfExpense)
                                    .toStringAsFixed(2),
                                style: TextStyle(
                                  fontSize: 24.0,
                                  color: Colors.red,
                                ),
                              ),
                            )
                        ]),
                    SizedBox(height: 10.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
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
                                sumOfRevenue.toStringAsFixed(2),
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
                                sumOfExpense.toStringAsFixed(2),
                                style: TextStyle(
                                  fontSize: 18.0,
                                  color: Colors.red,
                                ),
                              )
                            ]),
                          ],
                        ),
                      ],
                    ),
                  ]),
            ),
          ),
          SizedBox(height: 30),
          Text(
            'Upcoming transactions',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 30),
          showFutureTransactions(),
          SizedBox(height: 30),
          Text(
            'Upcoming to-dos',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 30),
          showFutureTodos(),
        ]),
      ),
    );
  }

  Future<List<PieData>> getPieList(String ledgerID) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference transactions = firestore.collection('transactions');
    List<PieData> pieData = [];
    Map<String, double> categoryList = {};

    Query userTransactions = transactions
        .where('ledgerID', isEqualTo: ledgerID)
        .where('isActive', isEqualTo: true);

    try {
      QuerySnapshot snapshot = await userTransactions.get();
      snapshot.docs.forEach((DocumentSnapshot doc) {
        if ((doc['transactionType'] == 'Buy' ||
                doc['transactionType'] == 'Payment' ||
                doc['transactionType'] == 'Outcome' ||
                doc['transactionType'] == 'Increase') &&
            doc['categoryName'] != '') {
          String categoryName = doc['categoryName'];
          double total = doc['total'];
          categoryList[categoryName] =
              (categoryList[categoryName] ?? 0) + total;
        }
      });

      categoryList.forEach((categoryName, total) {
        PieData newData = PieData(categoryName, total, categoryName);
        pieData.add(newData);
      });

      return pieData;
    } catch (error) {
      print('Error getting transactions: $error');
    }

    return pieData;
  }

  Future<List<BarData>> getRevenueBarList(String ledgerID) async {
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
    List<int> selectedMonthsIndexes = [];
    List<BarData> barList = [];
    for (int monthCounter = 0; monthCounter < 6; monthCounter++) {
      if (previousMonthOrder == 0) {
        previousMonthOrder = 12;
      }
      BarData newBarData = BarData(months.elementAt(previousMonthOrder - 1), 0);
      barList.add(newBarData);
      selectedMonthsIndexes.add(previousMonthOrder - 1);
      previousMonthOrder--;
    }

    QuerySnapshot ledgerTransactions = await transactions
        .where('ledgerID', isEqualTo: ledgerID)
        .where('isDone', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .get();

    ledgerTransactions.docs.forEach((element) {
      int transactionMonth = (element['targetDate'].toDate()).month;
      if (selectedMonthsIndexes.contains(transactionMonth - 1)) {
        if (element['transactionType'] == 'Sell' ||
            element['transactionType'] == 'Collection' ||
            element['transactionType'] == 'Income' ||
            element['transactionType'] == 'Decrease') {
          String monthName = months[transactionMonth - 1];
          barList.forEach((BarDataElement) {
            if (BarDataElement.month == monthName) {
              BarDataElement.total += element['convertedTotal'];
            }
          });
        }
      }
    });
    barList = barList.reversed.toList();
    return barList;
  }

  Future<List<BarData>> getExpenseBarList(String ledgerID) async {
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
    List<int> selectedMonthsIndexes = [];
    List<BarData> barList = [];
    for (int monthCounter = 0; monthCounter < 6; monthCounter++) {
      if (previousMonthOrder == 0) {
        previousMonthOrder = 12;
      }
      BarData newBarData = BarData(months.elementAt(previousMonthOrder - 1), 0);
      barList.add(newBarData);
      selectedMonthsIndexes.add(previousMonthOrder - 1);
      previousMonthOrder--;
    }

    QuerySnapshot ledgerTransactions = await transactions
        .where('ledgerID', isEqualTo: ledgerID)
        .where('isDone', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .get();

    ledgerTransactions.docs.forEach((element) {
      int transactionMonth = (element['targetDate'].toDate()).month;
      if (selectedMonthsIndexes.contains(transactionMonth - 1)) {
        if (element['transactionType'] == 'Buy' ||
            element['transactionType'] == 'Payment' ||
            element['transactionType'] == 'Outcome' ||
            element['transactionType'] == 'Increase') {
          String monthName = months[transactionMonth - 1];
          barList.forEach((BarDataElement) {
            if (BarDataElement.month == monthName) {
              BarDataElement.total += element['convertedTotal'];
            }
          });
        }
      }
    });
    barList = barList.reversed.toList();
    return barList;
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
    List<int> selectedMonthsIndexes = [];
    List<LineData> lineList = [];
    for (int monthCounter = 0; monthCounter < 6; monthCounter++) {
      if (previousMonthOrder == 0) {
        previousMonthOrder = 12;
      }
      LineData newLineData =
          LineData(months.elementAt(previousMonthOrder - 1), 0);
      lineList.add(newLineData);
      selectedMonthsIndexes.add(previousMonthOrder - 1);
      previousMonthOrder--;
    }

    QuerySnapshot ledgerTransactions = await transactions
        .where('ledgerID', isEqualTo: ledgerID)
        .where('isDone', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .get();

    ledgerTransactions.docs.forEach((element) {
      int transactionMonth = (element['targetDate'].toDate()).month;
      if (selectedMonthsIndexes.contains(transactionMonth - 1)) {
        if (element['transactionType'] == 'Buy' ||
            element['transactionType'] == 'Payment' ||
            element['transactionType'] == 'Outcome' ||
            element['transactionType'] == 'Increase') {
          String monthName = months[transactionMonth - 1];
          lineList.forEach((LineDataElement) {
            if (LineDataElement.month == monthName) {
              LineDataElement.profit -= element['convertedTotal'];
            }
          });
        } else if (element['transactionType'] == 'Sell' ||
            element['transactionType'] == 'Collection' ||
            element['transactionType'] == 'Income' ||
            element['transactionType'] == 'Decrease') {
          String monthName = months[transactionMonth - 1];
          lineList.forEach((LineDataElement) {
            if (LineDataElement.month == monthName) {
              LineDataElement.profit += element['convertedTotal'];
            }
          });
        }
      }
    });
    lineList = lineList.reversed.toList();
    return lineList;
  }

  Future<void> checkForFutureTransactions(String ledgerID) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      CollectionReference transactions = firestore.collection('transactions');

      QuerySnapshot snapshot = await transactions
          .where('ledgerID', isEqualTo: ledgerID)
          .where('isDone', isEqualTo: false)
          .where('isActive', isEqualTo: true)
          .get();

      if (snapshot != null && snapshot.docs.isNotEmpty) {
        snapshot.docs.forEach((DocumentSnapshot doc) {
          DateTime targetDate = doc["targetDate"].toDate();
          int dateTimeCompare = targetDate.compareTo(DateTime.now());

          if (dateTimeCompare <= 0) {
            doc.reference.update({'isDone': true});
            if (doc["period"] != "For once") {
              CreateFutureTransaction(doc);
            }
          }
        });
      } else {
        print('No future transactions found for ledgerID: $ledgerID');
      }
    } catch (error) {
      // Handle the error gracefully
      print('Error fetching future transactions: $error');
    }
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
    DateTime nextTargetDate =
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    //   Period can be:
    //   'Now'
    //   'Past'
    //   'For once',
    //   'Every day'
    //   'Every week',
    //   'Every month',
    //   'Every year'
    if (doc['period'] == 'Every day') {
      nextTargetDate = targetDate.add(Duration(days: 1));
    } else if (doc['period'] == 'Every week') {
      nextTargetDate = targetDate.add(Duration(days: 7));
    } else if (doc['period'] == 'Every month') {
      nextTargetDate = targetDate
          .add(Duration(days: _daysInMonth(targetDate.year, targetDate.month)));
    } else if (doc['period'] == 'Every year') {
      nextTargetDate = targetDate.add(Duration(days: 365));
    }

    List<String> accountIDList = List<String>.from(doc['accountID']
        .map((item) => item is String ? item : item.toString()));
    List<String> currencyList = List<String>.from(doc['currencies']
        .map((item) => item is String ? item : item.toString()));

    try {
      newTransaction = TransactionModel(
          accountID: accountIDList,
          ledgerID: doc['ledgerID'],
          stockID: doc['stockID'],
          transactionType: doc['transactionType'],
          amount: doc['amount'],
          total: doc['total'],
          convertedTotal: doc['convertedTotal'],
          currencies: currencyList,
          price: doc['price'],
          transactionDetail: doc['transactionDetail'],
          categoryName: doc['categoryName'],
          period: doc['period'],
          duration: doc['duration'] - 1,
          targetDate: nextTargetDate,
          isDone: doc['isDone'],
          createDate: doc['createDate'].toDate(),
          updateDate: doc['updateDate'].toDate(),
          isActive: true);

      DocumentReference transactionsDoc = await transactions.add({
        'accountID': newTransaction.accountID,
        'ledgerID': newTransaction.ledgerID,
        'stockID': newTransaction.stockID,
        'transactionType': newTransaction.transactionType,
        'amount': newTransaction.amount,
        'total': newTransaction.total,
        'convertedTotal': newTransaction.convertedTotal,
        'currencies': newTransaction.currencies,
        'price': newTransaction.price,
        'transactionDetail': newTransaction.transactionDetail,
        'categoryName': newTransaction.categoryName,
        'period': newTransaction.period,
        'duration': newTransaction.duration,
        'targetDate': Timestamp.fromDate(newTransaction.targetDate),
        'isDone': newTransaction.isDone,
        'createDate': Timestamp.fromDate(newTransaction.createDate),
        'updateDate': Timestamp.fromDate(newTransaction.updateDate),
        'isActive': newTransaction.isActive
      });
    } catch (e) {
      print('Error caught: $e');
    }
  }

  Widget showFutureTransactions() {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference transactions = firestore.collection('transactions');

    if (widget.currentLedgerID == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    Query ledgerTransactions = transactions
        .where('ledgerID', isEqualTo: widget.currentLedgerID)
        .where('isActive', isEqualTo: true)
        .where('isDone', isEqualTo: false)
        .orderBy('targetDate', descending: true);
    return Padding(
        padding: EdgeInsets.only(left: 50, top: 0, right: 50, bottom: 0),
        child: Container(
            constraints: BoxConstraints(
              maxWidth: 1000,
              maxHeight: 400,
            ),
            child: SingleChildScrollView(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: ledgerTransactions.snapshots(),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }

                    if (snapshot.hasData && snapshot.data != null) {
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (BuildContext context, int index) {
                          DocumentSnapshot document =
                              snapshot.data!.docs[index];
                          Map<String, dynamic> data =
                              document.data() as Map<String, dynamic>;
                          bool showIcons = false;
                          String documentId = document.id;
                          if (data['transactionType'] == 'Increase' ||
                              data['transactionType'] == 'Decrease' ||
                              data['transactionType'] == 'Income' ||
                              data['transactionType'] == 'Outcome') {
                            return InkWell(
                              onTap: () {
                                // Go to transaction details
                              },
                              child: ListTile(
                                title: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Expanded(
                                        child: Text(data['transactionType'],
                                            style: TextStyle(fontSize: 14)),
                                        flex: 2),
                                    Expanded(
                                        flex: 6,
                                        child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              if (data['transactionType'] ==
                                                  'Increase')
                                                Text(
                                                  '+${data['total'].toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                      color: Colors.green,
                                                      fontSize: 20),
                                                  textAlign: TextAlign.center,
                                                ),
                                              if (data['transactionType'] ==
                                                  'Decrease')
                                                Text(
                                                  '-${data['total'].toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 20),
                                                ),
                                              if (data['transactionType'] ==
                                                  'Income')
                                                Text(
                                                  '+${data['total'].toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                      color: Colors.green,
                                                      fontSize: 20),
                                                  textAlign: TextAlign.center,
                                                ),
                                              if (data['transactionType'] ==
                                                  'Outcome')
                                                Text(
                                                  '-${data['total'].toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 20),
                                                ),
                                              if (data['totalAmount'] == 0)
                                                Text(
                                                  data['totalAmount']
                                                      .toString(),
                                                  style:
                                                      TextStyle(fontSize: 16),
                                                ),
                                            ])),
                                    Expanded(
                                        child: IconButton(
                                          icon: Icon(Icons.more_vert),
                                          onPressed: () {
                                            setState(() {
                                              showModalBottomSheet(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return Container(
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: <Widget>[
                                                        ListTile(
                                                          leading:
                                                              Icon(Icons.edit),
                                                          title: Text('Update'),
                                                          onTap: () {
                                                            // do something
                                                            Navigator.pop(
                                                                context);
                                                            // showAccountTransactionUpdaterDialog(
                                                            //     context,
                                                            //     document);
                                                          },
                                                        ),
                                                        ListTile(
                                                          leading: Icon(
                                                              Icons.delete),
                                                          title: Text('Delete'),
                                                          onTap: () async {
                                                            // do something
                                                            String documentId =
                                                                document.id;
                                                            await transactions
                                                                .doc(documentId)
                                                                .update({
                                                              'isActive': false
                                                            });
                                                            await transactions
                                                                .doc(documentId)
                                                                .update({
                                                              'updateDate':
                                                                  DateTime.now()
                                                            });
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              );
                                            });
                                          },
                                        ),
                                        flex: 2),
                                  ],
                                ),
                                subtitle: Column(
                                  children: [
                                    Text(
                                        '${DateFormat('dd-MM-yyyy – kk:mm').format(data['createDate'].toDate().toLocal())}'),
                                    SizedBox(height: 10),
                                    if (data['period'] != 'Now')
                                      Container(
                                        width: 250,
                                        padding: EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          color: Colors.blue,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              size: 16.0,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 4.0),
                                            Text(
                                              '${DateFormat('dd-MM-yyyy – kk:mm').format(data['targetDate'].toDate().toLocal())} / ${data['period']}',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ],
                                        ),
                                      ),
                                    SizedBox(height: 10)
                                  ],
                                ),
                              ),
                            );
                          }
                          if (data['transactionType'] == 'Collection' ||
                              data['transactionType'] == 'Payment') {
                            return InkWell(
                              onTap: () {
                                // Go to transaction details
                              },
                              child: ListTile(
                                title: Row(children: [
                                  Expanded(
                                      child: Text(
                                        '${data['transactionType']}',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      flex: 2),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (data['transactionType'] ==
                                            'Collection')
                                          Text(
                                            '+${data['total'].toStringAsFixed(2)} ${data['currencies'][0]}',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 20,
                                            ),
                                          ),
                                        if (data['transactionType'] ==
                                            'Payment')
                                          Text(
                                            '-${data['total'].toStringAsFixed(2)} ${data['currencies'][0]}',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 20,
                                            ),
                                          ),
                                        if (data['total'] == 0)
                                          Text(
                                            data['total'].toStringAsFixed(2),
                                            style: TextStyle(fontSize: 20),
                                          ),
                                      ],
                                    ),
                                    flex: 6,
                                  ),
                                  Expanded(
                                      child: IconButton(
                                        icon: Icon(Icons.more_vert),
                                        onPressed: () {
                                          setState(() {
                                            showModalBottomSheet(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return Container(
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: <Widget>[
                                                      ListTile(
                                                        leading:
                                                            Icon(Icons.edit),
                                                        title: Text('Update'),
                                                        onTap: () {
                                                          // do something
                                                          Navigator.pop(
                                                              context);
                                                          // showAccountTransactionUpdaterDialog(
                                                          //     context,
                                                          //     document);
                                                        },
                                                      ),
                                                      ListTile(
                                                        leading:
                                                            Icon(Icons.delete),
                                                        title: Text('Delete'),
                                                        onTap: () async {
                                                          // do something
                                                          String documentId =
                                                              document.id;
                                                          await transactions
                                                              .doc(documentId)
                                                              .update({
                                                            'isActive': false
                                                          });
                                                          await transactions
                                                              .doc(documentId)
                                                              .update({
                                                            'updateDate':
                                                                DateTime.now()
                                                          });
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            );
                                          });
                                        },
                                      ),
                                      flex: 2),
                                ]),
                                subtitle: Column(children: [
                                  FutureBuilder<List<String>>(
                                    future: Future.wait([
                                      getAccountNameByID(data['accountID'][0]),
                                      getAccountNameByID(data['accountID'][1]),
                                    ]),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<List<String>> snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.done) {
                                        if (snapshot.hasData) {
                                          final sourceAccountName =
                                              snapshot.data![1];
                                          final accountName = snapshot.data![0];
                                          String arrow = "-";

                                          if (data['transactionType'] ==
                                                  'Buy' ||
                                              data['transactionType'] ==
                                                  'Payment') arrow = '\u2192';

                                          if (data['transactionType'] ==
                                                  'Sell' ||
                                              data['transactionType'] ==
                                                  'Collection')
                                            arrow = '\u2190';

                                          return Text(
                                              '$sourceAccountName $arrow $accountName');
                                        } else {
                                          return Text(
                                              'Error: ${snapshot.error}');
                                        }
                                      } else {
                                        return CircularProgressIndicator();
                                      }
                                    },
                                  ),
                                  Text(
                                      '${DateFormat('dd-MM-yyyy – kk:mm').format(data['createDate'].toDate().toLocal())}'),
                                  SizedBox(height: 10),
                                  if (data['period'] != 'Now')
                                    Container(
                                      width: 250,
                                      padding: EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        color: Colors.blue,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 16.0,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 4.0),
                                          Text(
                                            '${DateFormat('dd-MM-yyyy – kk:mm').format(data['targetDate'].toDate().toLocal())} / ${data['period']}',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  SizedBox(height: 10)
                                ]),
                              ),
                            );
                          }
                          if (data['transactionType'] == 'Buy' ||
                              data['transactionType'] == 'Sell') {
                            return InkWell(
                              onTap: () {
                                // Go to transaction details
                              },
                              child: ListTile(
                                title: Row(children: [
                                  Expanded(
                                      child: Text(
                                        '${data['transactionType']}',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      flex: 2),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (data['transactionType'] == 'Buy')
                                          Text(
                                            '-${data['total'].toStringAsFixed(2)} ${data['currencies'][0]}',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 20,
                                            ),
                                          ),
                                        if (data['transactionType'] == 'Sell')
                                          Text(
                                            '+${data['total'].toStringAsFixed(2)} ${data['currencies'][0]}',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 20,
                                            ),
                                          ),
                                        if (data['total'] == 0)
                                          Text(
                                            data['total'].toStringAsFixed(2),
                                            style: TextStyle(fontSize: 20),
                                          ),
                                      ],
                                    ),
                                    flex: 6,
                                  ),
                                  Expanded(
                                      child: IconButton(
                                        icon: Icon(Icons.more_vert),
                                        onPressed: () {
                                          setState(() {
                                            showModalBottomSheet(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return Container(
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: <Widget>[
                                                      ListTile(
                                                        leading:
                                                            Icon(Icons.edit),
                                                        title: Text('Update'),
                                                        onTap: () {
                                                          // do something
                                                          Navigator.pop(
                                                              context);
                                                          // showStockTransactionUpdaterDialog(
                                                          //     context,
                                                          //     document);
                                                        },
                                                      ),
                                                      ListTile(
                                                        leading:
                                                            Icon(Icons.delete),
                                                        title: Text('Delete'),
                                                        onTap: () async {
                                                          // do something
                                                          String documentId =
                                                              document.id;
                                                          await transactions
                                                              .doc(documentId)
                                                              .update({
                                                            'isActive': false
                                                          });
                                                          await transactions
                                                              .doc(documentId)
                                                              .update({
                                                            'updateDate':
                                                                DateTime.now()
                                                          });
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            );
                                          });
                                        },
                                      ),
                                      flex: 2),
                                ]),
                                subtitle: Column(children: [
                                  Text(
                                    '${data['amount']}x${data['price'].toStringAsFixed(2)}=${data['total'].toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  FutureBuilder<List<String>>(
                                    future: Future.wait([
                                      getAccountNameByID(data['accountID'][1]),
                                      getAccountNameByID(data['accountID'][0]),
                                    ]),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<List<String>> snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.done) {
                                        if (snapshot.hasData) {
                                          final sourceAccountName =
                                              snapshot.data![0];
                                          final accountName = snapshot.data![1];
                                          String arrow = "-";

                                          if (data['transactionType'] ==
                                                  'Buy' ||
                                              data['transactionType'] ==
                                                  'Payment') arrow = '\u2192';

                                          if (data['transactionType'] ==
                                                  'Sell' ||
                                              data['transactionType'] ==
                                                  'Collection')
                                            arrow = '\u2190';

                                          return Text(
                                              '$sourceAccountName $arrow $accountName');
                                        } else {
                                          return Text(
                                              'Error: ${snapshot.error}');
                                        }
                                      } else {
                                        return CircularProgressIndicator();
                                      }
                                    },
                                  ),
                                  Text(
                                      '${DateFormat('dd-MM-yyyy – kk:mm').format(data['createDate'].toDate().toLocal())}'),
                                  SizedBox(height: 10),
                                  if (data['period'] != 'Now')
                                    Container(
                                      width: 250,
                                      padding: EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        color: Colors.blue,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 16.0,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 4.0),
                                          Text(
                                            '${DateFormat('dd-MM-yyyy – kk:mm').format(data['targetDate'].toDate().toLocal())} / ${data['period']}',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                ]),
                              ),
                            );
                          }
                        },
                      );
                    } else {
                      return Text('No data available');
                    }
                  },
                ),
              ],
            ))));
  }

  void showNoteUpdaterDialog(
      BuildContext context, DocumentSnapshot<Object?> document) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            //content: NoteUpdater(document),
            );
      },
    );
  }

  Widget showFutureTodos() {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference notes = firestore.collection('notes');

    if (widget.currentLedgerID == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    Query userNotes = notes
        .where('ledgerID', isEqualTo: widget.currentLedgerID)
        .where('isActive', isEqualTo: true)
        .orderBy('updateDate', descending: true);
    return Padding(
        padding: EdgeInsets.only(left: 50, top: 0, right: 50, bottom: 0),
        child: Container(
            constraints: BoxConstraints(
              maxWidth: 1000,
              maxHeight: 400,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: userNotes.snapshots(),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }

                        if (snapshot.hasData && snapshot.data != null) {
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (BuildContext context, int index) {
                              DocumentSnapshot document =
                                  snapshot.data!.docs[index];
                              Map<String, dynamic> data =
                                  document.data() as Map<String, dynamic>;
                              bool showIcons = false;

                              if (data['noteType'] == 'To do')
                                return InkWell(
                                  onTap: () {},
                                  child: ListTile(
                                      title: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(data['noteType']),
                                            Text(data['heading']),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: Icon(Icons.more_vert),
                                                  onPressed: () {
                                                    setState(() {
                                                      showModalBottomSheet(
                                                        context: context,
                                                        builder: (BuildContext
                                                            context) {
                                                          return Container(
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: <
                                                                  Widget>[
                                                                ListTile(
                                                                  leading: Icon(
                                                                      Icons
                                                                          .edit),
                                                                  title: Text(
                                                                      'Update'),
                                                                  onTap: () {
                                                                    // do something
                                                                    Navigator.pop(
                                                                        context);
                                                                    showNoteUpdaterDialog(
                                                                        context,
                                                                        document);
                                                                  },
                                                                ),
                                                                ListTile(
                                                                  leading: Icon(
                                                                      Icons
                                                                          .delete),
                                                                  title: Text(
                                                                      'Delete'),
                                                                  onTap:
                                                                      () async {
                                                                    // do something
                                                                    String
                                                                        documentId =
                                                                        document
                                                                            .id;
                                                                    await notes
                                                                        .doc(
                                                                            documentId)
                                                                        .update({
                                                                      'isActive':
                                                                          false
                                                                    });
                                                                    await notes
                                                                        .doc(
                                                                            documentId)
                                                                        .update({
                                                                      'updateDate':
                                                                          DateTime
                                                                              .now()
                                                                    });
                                                                    Navigator.pop(
                                                                        context);
                                                                  },
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    });
                                                  },
                                                ),
                                              ],
                                            )
                                          ]),
                                      subtitle: Column(children: [
                                        Text(data['noteDetail']),
                                        Row(children: [
                                          if (data['targetDate'] == DateTime(0))
                                            Text(
                                                DateFormat('dd-MM-yyyy – kk:mm')
                                                    .format(data['createDate']
                                                        .toDate()
                                                        .toLocal())),
                                          if (data['targetDate'] != DateTime(0))
                                            Text(
                                                DateFormat('dd-MM-yyyy – kk:mm')
                                                    .format(data['targetDate']
                                                        .toDate()
                                                        .toLocal())),
                                        ]),
                                        SizedBox(height: 25),
                                        SizedBox(height: 10),
                                        if (data['period'] != 'Now')
                                          Container(
                                            width: 250,
                                            padding: EdgeInsets.all(5),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              color: Colors.blue,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: 16.0,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(width: 4.0),
                                                Text(
                                                  '${DateFormat('dd-MM-yyyy – kk:mm').format(data['targetDate'].toDate().toLocal())} / ${data['period']}',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
                                        SizedBox(height: 10)
                                      ])),
                                );
                            },
                          );
                        } else {
                          return Text('No data available');
                        }
                      },
                    ),
                  ],
                ),
              ),
            )));
  }
}

Widget LatestExchangeRates() {
  ExchangerateRequester requester = new ExchangerateRequester();
  return Container(
      width: 500,
      height: 500,
      child: FutureBuilder<Map<String, dynamic>>(
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
