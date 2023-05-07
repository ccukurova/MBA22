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
import 'package:MBA22/Services/RatesRequester.dart';
import '../constants.dart';
import 'package:intl/intl.dart';

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
    getUserID();
    getLedgerID();
  }

  @override
  Widget build(BuildContext context) {
    try {
      checkForFutureTransactions(currentLedgerID!);
    } catch (e) {
      print(e);
    }

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

                            if (balance > 0)
                              return Center(
                                child: Text(
                                  balance.toString(),
                                  style: TextStyle(
                                    fontSize: 24.0,
                                    color: Colors.green,
                                  ),
                                ),
                              );
                            if (balance < 0)
                              return Center(
                                child: Text(
                                  balance.toString(),
                                  style: TextStyle(
                                    fontSize: 24.0,
                                    color: Colors.red,
                                  ),
                                ),
                              );
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
          SizedBox(height: 30),
          Text(
            'Upcoming transactions',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 30),
          showFutureTransactions(),
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
        .where('transactionType',
            whereIn: ['Sell', 'Collection', 'Decrease', 'Income']);

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
        .where('transactionType',
            whereIn: ['Buy', 'Payment', 'Increase', 'Outcome']);

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
          double totalPrice = doc['totalPrice'];
          categoryList[categoryName] =
              (categoryList[categoryName] ?? 0) + totalPrice;
        }
      });

      categoryList.forEach((categoryName, totalPrice) {
        PieData newData = PieData(categoryName, totalPrice, categoryName);
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
      if (targetDate !=
          Timestamp.fromDate(
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true))) {
        int dateTimeCompare = targetDate.compareTo(DateTime.now());

        if (dateTimeCompare <= 0) {
          doc.reference.update({
            'isDone': true,
            'targetDate': Timestamp.fromDate(
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true))
          });

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
    DateTime nextTargetDate =
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
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

  Future<void> getUserID() async {
    await prefs.getString("userID").then((value) {
      setState(() {
        currentUserID = value;
      });
    });
  }

  Future<void> getLedgerID() async {
    prefs.getString("ledgerID").then((value) {
      setState(() {
        currentLedgerID = value;
      });
    });
  }

  Widget showFutureTransactions() {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference transactions = firestore.collection('transactions');

    if (currentLedgerID == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    Timestamp zeroDate =
        Timestamp.fromDate(DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));
    Query ledgerTransactions = transactions
        .where('ledgerID', isEqualTo: currentLedgerID)
        .where('isActive', isEqualTo: true)
        .where('targetDate', isNotEqualTo: zeroDate)
        .orderBy('targetDate', descending: true);
    return Container(
        width: 700,
        height: 500,
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
                      DocumentSnapshot document = snapshot.data!.docs[index];
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
                                              '+${data['totalPrice'].toString()}',
                                              style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 20),
                                              textAlign: TextAlign.center,
                                            ),
                                          if (data['transactionType'] ==
                                              'Decrease')
                                            Text(
                                              '-${data['totalPrice'].toString()}',
                                              style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 20),
                                            ),
                                          if (data['transactionType'] ==
                                              'Income')
                                            Text(
                                              '+${data['totalPrice'].toString()}',
                                              style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 20),
                                              textAlign: TextAlign.center,
                                            ),
                                          if (data['transactionType'] ==
                                              'Outcome')
                                            Text(
                                              '-${data['totalPrice'].toString()}',
                                              style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 20),
                                            ),
                                          if (data['totalAmount'] == 0)
                                            Text(
                                              data['totalAmount'].toString(),
                                              style: TextStyle(fontSize: 16),
                                            ),
                                        ])),
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
                                                      leading: Icon(Icons.edit),
                                                      title: Text('Update'),
                                                      onTap: () {
                                                        // do something
                                                        Navigator.pop(context);
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
                                                        Navigator.pop(context);
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
                                if (data['targetDate'] !=
                                    Timestamp.fromDate(
                                        DateTime.fromMillisecondsSinceEpoch(0,
                                            isUtc: true)))
                                  Container(
                                    width: 250,
                                    padding: EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8.0),
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
                                          style: TextStyle(color: Colors.white),
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (data['transactionType'] == 'Collection')
                                      Text(
                                        '+${data['totalPrice'].toString()}',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 20,
                                        ),
                                      ),
                                    if (data['transactionType'] == 'Payment')
                                      Text(
                                        '-${data['totalPrice'].toString()} ',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 20,
                                        ),
                                      ),
                                    if (data['totalPrice'] == 0)
                                      Text(
                                        data['totalPrice'].toString(),
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
                                                mainAxisSize: MainAxisSize.min,
                                                children: <Widget>[
                                                  ListTile(
                                                    leading: Icon(Icons.edit),
                                                    title: Text('Update'),
                                                    onTap: () {
                                                      // do something
                                                      Navigator.pop(context);
                                                      // showAccountTransactionUpdaterDialog(
                                                      //     context,
                                                      //     document);
                                                    },
                                                  ),
                                                  ListTile(
                                                    leading: Icon(Icons.delete),
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
                                                      Navigator.pop(context);
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

                                      if (data['transactionType'] == 'Buy' ||
                                          data['transactionType'] == 'Payment')
                                        arrow = '\u2192';

                                      if (data['transactionType'] == 'Sell' ||
                                          data['transactionType'] ==
                                              'Collection') arrow = '\u2190';

                                      return Text(
                                          '$sourceAccountName $arrow $accountName');
                                    } else {
                                      return Text('Error: ${snapshot.error}');
                                    }
                                  } else {
                                    return CircularProgressIndicator();
                                  }
                                },
                              ),
                              Text(
                                  '${DateFormat('dd-MM-yyyy – kk:mm').format(data['createDate'].toDate().toLocal())}'),
                              SizedBox(height: 10),
                              if (data['targetDate'] !=
                                  Timestamp.fromDate(
                                      DateTime.fromMillisecondsSinceEpoch(0,
                                          isUtc: true)))
                                Container(
                                  width: 250,
                                  padding: EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.0),
                                    color: Colors.blue,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 16.0,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 4.0),
                                      Text(
                                        '${DateFormat('dd-MM-yyyy – kk:mm').format(data['targetDate'].toDate().toLocal())} / ${data['period']}',
                                        style: TextStyle(color: Colors.white),
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (data['transactionType'] == 'Buy')
                                      Text(
                                        '-${data['totalPrice'].toString()}',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 20,
                                        ),
                                      ),
                                    if (data['transactionType'] == 'Sell')
                                      Text(
                                        '+${data['totalPrice'].toString()} ',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 20,
                                        ),
                                      ),
                                    if (data['totalPrice'] == 0)
                                      Text(
                                        data['totalPrice'].toString(),
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
                                                mainAxisSize: MainAxisSize.min,
                                                children: <Widget>[
                                                  ListTile(
                                                    leading: Icon(Icons.edit),
                                                    title: Text('Update'),
                                                    onTap: () {
                                                      // do something
                                                      Navigator.pop(context);
                                                      // showStockTransactionUpdaterDialog(
                                                      //     context,
                                                      //     document);
                                                    },
                                                  ),
                                                  ListTile(
                                                    leading: Icon(Icons.delete),
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
                                                      Navigator.pop(context);
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
                                '${data['amount']}x${data['price'].toString()}=${data['totalPrice']}',
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

                                      if (data['transactionType'] == 'Buy' ||
                                          data['transactionType'] == 'Payment')
                                        arrow = '\u2192';

                                      if (data['transactionType'] == 'Sell' ||
                                          data['transactionType'] ==
                                              'Collection') arrow = '\u2190';

                                      return Text(
                                          '$sourceAccountName $arrow $accountName');
                                    } else {
                                      return Text('Error: ${snapshot.error}');
                                    }
                                  } else {
                                    return CircularProgressIndicator();
                                  }
                                },
                              ),
                              Text(
                                  '${DateFormat('dd-MM-yyyy – kk:mm').format(data['createDate'].toDate().toLocal())}'),
                              SizedBox(height: 10),
                              if (data['targetDate'] !=
                                  Timestamp.fromDate(
                                      DateTime.fromMillisecondsSinceEpoch(0,
                                          isUtc: true)))
                                Container(
                                  width: 250,
                                  padding: EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.0),
                                    color: Colors.blue,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 16.0,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 4.0),
                                      Text(
                                        '${DateFormat('dd-MM-yyyy – kk:mm').format(data['targetDate'].toDate().toLocal())} / ${data['period']}',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              SizedBox(height: 10)
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
