import 'package:MBA22/Pages/Widgets/TargetDateBar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:MBA22/Models/AccountModel.dart';
import 'package:MBA22/Models/TransactionModel.dart';
import 'package:MBA22/Pages/CategoriesPage.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Helpers/SharedPreferencesManager.dart';
import 'package:MBA22/Models/LedgerModel.dart';
import '../Models/TransactionModel.dart';
import 'MainPage.dart';
import 'package:intl/intl.dart';
import 'package:textfield_search/textfield_search.dart';
import '../Services/ExchangerateRequester.dart';

class ArchiveTransactionPage extends StatefulWidget {
  @override
  ArchiveTransactionPageState createState() => ArchiveTransactionPageState();
}

class ArchiveTransactionPageState extends State<ArchiveTransactionPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? currentAccountID;

  final SharedPreferencesManager prefs = SharedPreferencesManager();

  @override
  void initState() {
    super.initState();

    prefs.getString("accountID").then((value) {
      setState(() {
        currentAccountID = value;
      });
    });
  }

  Future<DocumentSnapshot> getCurrentAccount() async {
    CollectionReference accounts = firestore.collection('accounts');

    DocumentSnapshot accountSnapshot =
        await accounts.doc(currentAccountID).get();
    return accountSnapshot;
  }

  @override
  Widget build(BuildContext context) {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference transactions = firestore.collection('transactions');
    CollectionReference stockTransactions =
        firestore.collection('transactions');

    if (currentAccountID == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    Query userAccountTransactions = transactions
        .where('accountID', arrayContains: currentAccountID)
        .where('isActive', isEqualTo: false)
        .orderBy('createDate', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text('Account Transactions'),
      ),
      body: Stack(
        children: [
          Center(
              child: Padding(
                  padding:
                      EdgeInsets.only(left: 10, top: 0, right: 10, bottom: 0),
                  child: Container(
                      height: double.infinity,
                      constraints: BoxConstraints(
                        maxWidth: 1000,
                      ),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              StreamBuilder<QuerySnapshot>(
                                stream: userAccountTransactions.snapshots(),
                                builder: (BuildContext context,
                                    AsyncSnapshot<QuerySnapshot> snapshot) {
                                  if (snapshot.hasError) {
                                    return Text('Error1: ${snapshot.error}');
                                  }

                                  if (snapshot.hasData &&
                                      snapshot.data != null) {
                                    return ListView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: snapshot.data!.docs.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        DocumentSnapshot document =
                                            snapshot.data!.docs[index];
                                        Map<String, dynamic> data = document
                                            .data() as Map<String, dynamic>;
                                        bool showIcons = false;
                                        String documentId = document.id;
                                        if (data['transactionType'] == 'Increase' ||
                                            data['transactionType'] ==
                                                'Decrease' ||
                                            data['transactionType'] ==
                                                'Income' ||
                                            data['transactionType'] ==
                                                'Outcome') {
                                          return InkWell(
                                              onTap: () {
                                                // Go to transaction details
                                              },
                                              child: Card(
                                                child: ListTile(
                                                  title: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Expanded(
                                                          child: Text(
                                                              data[
                                                                  'transactionType'],
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      12)),
                                                          flex: 4),
                                                      Expanded(
                                                          flex: 13,
                                                          child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                if (data[
                                                                        'transactionType'] ==
                                                                    'Increase')
                                                                  Text(
                                                                    '+${data['total'].toStringAsFixed(2)}',
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .green,
                                                                        fontSize:
                                                                            20),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                  ),
                                                                if (data[
                                                                        'transactionType'] ==
                                                                    'Decrease')
                                                                  Text(
                                                                    '-${data['total'].toStringAsFixed(2)}',
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .red,
                                                                        fontSize:
                                                                            20),
                                                                  ),
                                                                if (data[
                                                                        'transactionType'] ==
                                                                    'Income')
                                                                  Text(
                                                                    '+${data['total'].toStringAsFixed(2)}',
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .green,
                                                                        fontSize:
                                                                            20),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                  ),
                                                                if (data[
                                                                        'transactionType'] ==
                                                                    'Outcome')
                                                                  Text(
                                                                    '-${data['total'].toStringAsFixed(2)}',
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .red,
                                                                        fontSize:
                                                                            20),
                                                                  ),
                                                                if (data[
                                                                        'totalAmount'] ==
                                                                    0)
                                                                  Text(
                                                                    data['totalAmount']
                                                                        .toStringAsFixed(
                                                                            2),
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            16),
                                                                  ),
                                                              ])),
                                                      Expanded(
                                                          child: SizedBox(),
                                                          flex: 2),
                                                      Expanded(
                                                          child: IconButton(
                                                            icon: Icon(
                                                                Icons.delete),
                                                            onPressed:
                                                                () async {
                                                              // do something
                                                              String
                                                                  documentId =
                                                                  document.id;
                                                              await stockTransactions
                                                                  .doc(
                                                                      documentId)
                                                                  .delete();
                                                            },
                                                          ),
                                                          flex: 2)
                                                    ],
                                                  ),
                                                  subtitle: Column(
                                                    children: [
                                                      SizedBox(height: 10),
                                                      if (data[
                                                              'transactionDetail'] !=
                                                          "")
                                                        Text(data[
                                                            'transactionDetail']),
                                                      if (data[
                                                              'categoryName'] !=
                                                          "")
                                                        Text(
                                                          '#${data['categoryName']}',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.blue),
                                                        ),
                                                      if (data['createDate'] ==
                                                          data['updateDate'])
                                                        Text(
                                                            'Created at ${DateFormat('dd-MM-yyyy – kk:mm').format(data['createDate'].toDate().toLocal())}'),
                                                      if (data['createDate'] !=
                                                          data['updateDate'])
                                                        Text(
                                                            'Updated at ${DateFormat('dd-MM-yyyy – kk:mm').format(data['updateDate'].toDate().toLocal())}'),
                                                      SizedBox(height: 10),
                                                      if (data[
                                                              'period'] !=
                                                          'Now')
                                                        TargetDateBar(
                                                            targetDate: data[
                                                                    'targetDate']
                                                                .toDate(),
                                                            period:
                                                                data['period'],
                                                            duration: data[
                                                                'duration'],
                                                            isDone:
                                                                data['isDone']),
                                                      SizedBox(height: 10)
                                                    ],
                                                  ),
                                                ),
                                              ));
                                        }
                                        if (data['transactionType'] ==
                                                'Collection' ||
                                            data['transactionType'] ==
                                                'Payment') {
                                          return InkWell(
                                            onTap: () {
                                              // Go to transaction details
                                            },
                                            child: Card(
                                                child: ListTile(
                                              title: Row(children: [
                                                Expanded(
                                                    child: Text(
                                                      '${data['transactionType']}',
                                                      style: TextStyle(
                                                          fontSize: 12),
                                                    ),
                                                    flex: 2),
                                                FutureBuilder<DocumentSnapshot>(
                                                  future: getCurrentAccount(),
                                                  builder: (BuildContext
                                                          context,
                                                      AsyncSnapshot<
                                                              DocumentSnapshot>
                                                          snapshot) {
                                                    if (snapshot.hasData) {
                                                      final accountData =
                                                          snapshot.data!;

                                                      return Expanded(
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            if (data['transactionType'] ==
                                                                    'Collection' &&
                                                                accountData[
                                                                        'accountType'] ==
                                                                    'External')
                                                              Text(
                                                                '-${data['total'].toStringAsFixed(2)} ',
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .red,
                                                                  fontSize: 20,
                                                                ),
                                                              ),
                                                            if (data['transactionType'] ==
                                                                    'Collection' &&
                                                                accountData[
                                                                        'accountType'] ==
                                                                    'Internal')
                                                              Text(
                                                                '+${data['convertedTotal'].toStringAsFixed(2)}',
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .green,
                                                                  fontSize: 20,
                                                                ),
                                                              ),
                                                            if (data['transactionType'] ==
                                                                    'Payment' &&
                                                                accountData[
                                                                        'accountType'] ==
                                                                    'External')
                                                              Text(
                                                                '+${data['total'].toStringAsFixed(2)}',
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .green,
                                                                  fontSize: 20,
                                                                ),
                                                              ),
                                                            if (data['transactionType'] ==
                                                                    'Payment' &&
                                                                accountData[
                                                                        'accountType'] ==
                                                                    'Internal')
                                                              Text(
                                                                '-${data['convertedTotal'].toStringAsFixed(2)} ',
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .red,
                                                                  fontSize: 20,
                                                                ),
                                                              ),
                                                            if (data['total'] ==
                                                                0)
                                                              Text(
                                                                data['total']
                                                                    .toStringAsFixed(
                                                                        2),
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        20),
                                                              ),
                                                          ],
                                                        ),
                                                        flex: 6,
                                                      );
                                                    } else if (snapshot
                                                        .hasError) {
                                                      return Text(
                                                          'Error2: ${snapshot.error}');
                                                    } else {
                                                      return CircularProgressIndicator();
                                                    }
                                                  },
                                                ),
                                                Expanded(
                                                    child: IconButton(
                                                      icon: Icon(Icons.delete),
                                                      onPressed: () async {
                                                        // do something
                                                        String documentId =
                                                            document.id;
                                                        await stockTransactions
                                                            .doc(documentId)
                                                            .delete();
                                                      },
                                                    ),
                                                    flex: 2)
                                              ]),
                                              subtitle: Column(children: [
                                                FutureBuilder<List<String>>(
                                                  future: Future.wait([
                                                    getAccountNameByID(
                                                        data['accountID'][0]),
                                                    getAccountNameByID(
                                                        data['accountID'][1]),
                                                  ]),
                                                  builder:
                                                      (BuildContext context,
                                                          AsyncSnapshot<
                                                                  List<String>>
                                                              snapshot) {
                                                    if (snapshot
                                                            .connectionState ==
                                                        ConnectionState.done) {
                                                      if (snapshot.hasData) {
                                                        final sourceAccountName =
                                                            snapshot.data![1];
                                                        final accountName =
                                                            snapshot.data![0];
                                                        String arrow = "-";

                                                        if (data['transactionType'] ==
                                                                'Buy' ||
                                                            data['transactionType'] ==
                                                                'Payment')
                                                          arrow = '\u2192';

                                                        if (data['transactionType'] ==
                                                                'Sell' ||
                                                            data['transactionType'] ==
                                                                'Collection')
                                                          arrow = '\u2190';

                                                        return Text(
                                                            '$sourceAccountName $arrow $accountName');
                                                      } else {
                                                        return Text(
                                                            'Error3: ${snapshot.error}');
                                                      }
                                                    } else {
                                                      return CircularProgressIndicator();
                                                    }
                                                  },
                                                ),
                                                SizedBox(height: 10),
                                                if (data['transactionDetail'] !=
                                                    "")
                                                  Text(data[
                                                      'transactionDetail']),
                                                if (data['categoryName'] != "")
                                                  Text(
                                                    '#${data['categoryName']}',
                                                    style: TextStyle(
                                                        color: Colors.blue),
                                                  ),
                                                if (data['createDate'] ==
                                                    data['updateDate'])
                                                  Text(
                                                      'Created at ${DateFormat('dd-MM-yyyy – kk:mm').format(data['createDate'].toDate().toLocal())}'),
                                                if (data['createDate'] !=
                                                    data['updateDate'])
                                                  Text(
                                                      'Updated at ${DateFormat('dd-MM-yyyy – kk:mm').format(data['updateDate'].toDate().toLocal())}'),
                                                SizedBox(height: 10),
                                                if (data['period'] != 'Now')
                                                  TargetDateBar(
                                                      targetDate:
                                                          data['targetDate']
                                                              .toDate(),
                                                      period: data['period'],
                                                      duration:
                                                          data['duration'],
                                                      isDone: data['isDone']),
                                                SizedBox(height: 10)
                                              ]),
                                            )),
                                          );
                                        }
                                        if (data['transactionType'] == 'Buy' ||
                                            data['transactionType'] == 'Sell') {
                                          return InkWell(
                                              onTap: () {
                                                // Go to transaction details
                                              },
                                              child: Card(
                                                child: ListTile(
                                                  title: Row(children: [
                                                    Expanded(
                                                        child: Text(
                                                          '${data['transactionType']}',
                                                          style: TextStyle(
                                                              fontSize: 12),
                                                        ),
                                                        flex: 2),
                                                    FutureBuilder<
                                                        DocumentSnapshot>(
                                                      future:
                                                          getCurrentAccount(),
                                                      builder: (BuildContext
                                                              context,
                                                          AsyncSnapshot<
                                                                  DocumentSnapshot>
                                                              snapshot) {
                                                        if (snapshot.hasData) {
                                                          final accountData =
                                                              snapshot.data!;
                                                          return Expanded(
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                if (data['transactionType'] ==
                                                                        'Buy' &&
                                                                    accountData[
                                                                            'accountType'] ==
                                                                        'External')
                                                                  Text(
                                                                    '+${data['total'].toStringAsFixed(2)} ',
                                                                    style:
                                                                        TextStyle(
                                                                      color: Colors
                                                                          .green,
                                                                      fontSize:
                                                                          20,
                                                                    ),
                                                                  ),
                                                                if (data['transactionType'] ==
                                                                        'Buy' &&
                                                                    accountData[
                                                                            'accountType'] ==
                                                                        'Internal')
                                                                  Text(
                                                                    '-${data['convertedTotal'].toStringAsFixed(2)}',
                                                                    style:
                                                                        TextStyle(
                                                                      color: Colors
                                                                          .red,
                                                                      fontSize:
                                                                          20,
                                                                    ),
                                                                  ),
                                                                if (data['transactionType'] ==
                                                                        'Sell' &&
                                                                    accountData[
                                                                            'accountType'] ==
                                                                        'External')
                                                                  Text(
                                                                    '-${data['total'].toStringAsFixed(2)}',
                                                                    style:
                                                                        TextStyle(
                                                                      color: Colors
                                                                          .red,
                                                                      fontSize:
                                                                          20,
                                                                    ),
                                                                  ),
                                                                if (data['transactionType'] ==
                                                                        'Sell' &&
                                                                    accountData[
                                                                            'accountType'] ==
                                                                        'Internal')
                                                                  Text(
                                                                    '+${data['convertedTotal'].toStringAsFixed(2)} ',
                                                                    style:
                                                                        TextStyle(
                                                                      color: Colors
                                                                          .green,
                                                                      fontSize:
                                                                          20,
                                                                    ),
                                                                  ),
                                                                if (data[
                                                                        'total'] ==
                                                                    0)
                                                                  Text(
                                                                    data['total']
                                                                        .toStringAsFixed(
                                                                            2),
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            20),
                                                                  ),
                                                              ],
                                                            ),
                                                            flex: 6,
                                                          );
                                                        } else if (snapshot
                                                            .hasError) {
                                                          return Text(
                                                              'Error4: ${snapshot.error}');
                                                        } else {
                                                          return CircularProgressIndicator();
                                                        }
                                                      },
                                                    ),
                                                    Expanded(
                                                        child: IconButton(
                                                          icon: Icon(
                                                              Icons.delete),
                                                          onPressed: () async {
                                                            // do something
                                                            String documentId =
                                                                document.id;
                                                            await stockTransactions
                                                                .doc(documentId)
                                                                .delete();
                                                          },
                                                        ),
                                                        flex: 2)
                                                  ]),
                                                  subtitle: Column(children: [
                                                    if (data['currencies'][0] !=
                                                        data['currencies'][1])
                                                      Text(
                                                        '${data['amount']}x${data['price'].toStringAsFixed(2)}=${data['total'].toStringAsFixed(2)} ${data['currencies'][0]} (${data['convertedTotal'].toStringAsFixed(2)} ${data['currencies'][1]})',
                                                        style: TextStyle(
                                                            fontSize: 12),
                                                      ),
                                                    if (data['currencies'][0] ==
                                                        data['currencies'][1])
                                                      Text(
                                                        '${data['amount']}x${data['price'].toStringAsFixed(2)}=${data['total'].toStringAsFixed(2)} ${data['currencies'][0]}',
                                                        style: TextStyle(
                                                            fontSize: 12),
                                                      ),
                                                    FutureBuilder<List<String>>(
                                                      future: Future.wait([
                                                        getAccountNameByID(
                                                            data['accountID']
                                                                [1]),
                                                        getAccountNameByID(
                                                            data['accountID']
                                                                [0]),
                                                      ]),
                                                      builder: (BuildContext
                                                              context,
                                                          AsyncSnapshot<
                                                                  List<String>>
                                                              snapshot) {
                                                        if (snapshot
                                                                .connectionState ==
                                                            ConnectionState
                                                                .done) {
                                                          if (snapshot
                                                              .hasData) {
                                                            final sourceAccountName =
                                                                snapshot
                                                                    .data![0];
                                                            final accountName =
                                                                snapshot
                                                                    .data![1];
                                                            String arrow = "-";

                                                            if (data['transactionType'] ==
                                                                    'Buy' ||
                                                                data['transactionType'] ==
                                                                    'Payment')
                                                              arrow = '\u2192';

                                                            if (data['transactionType'] ==
                                                                    'Sell' ||
                                                                data['transactionType'] ==
                                                                    'Collection')
                                                              arrow = '\u2190';

                                                            return Text(
                                                                '$sourceAccountName $arrow $accountName');
                                                          } else {
                                                            return Text(
                                                                'Error5: ${snapshot.error}');
                                                          }
                                                        } else {
                                                          return CircularProgressIndicator();
                                                        }
                                                      },
                                                    ),
                                                    SizedBox(height: 10),
                                                    if (data[
                                                            'transactionDetail'] !=
                                                        "")
                                                      Text(data[
                                                          'transactionDetail']),
                                                    if (data['categoryName'] !=
                                                        "")
                                                      Text(
                                                        '#${data['categoryName']}',
                                                        style: TextStyle(
                                                            color: Colors.blue),
                                                      ),
                                                    if (data['createDate'] ==
                                                        data['updateDate'])
                                                      Text(
                                                          'Created at ${DateFormat('dd-MM-yyyy – kk:mm').format(data['createDate'].toDate().toLocal())}'),
                                                    if (data['createDate'] !=
                                                        data['updateDate'])
                                                      Text(
                                                          'Updated at ${DateFormat('dd-MM-yyyy – kk:mm').format(data['updateDate'].toDate().toLocal())}'),
                                                    SizedBox(height: 10),
                                                    if (data['period'] != 'Now')
                                                      TargetDateBar(
                                                          targetDate:
                                                              data['targetDate']
                                                                  .toDate(),
                                                          period:
                                                              data['period'],
                                                          duration:
                                                              data['duration'],
                                                          isDone:
                                                              data['isDone']),
                                                    SizedBox(height: 10)
                                                  ]),
                                                ),
                                              ));
                                        }
                                      },
                                    );
                                  } else {
                                    return Center(
                                        child: CircularProgressIndicator());
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      )))),
        ],
      ),
    );
  }
}

Future<String> getAccountNameByID(String _accountID) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  CollectionReference accounts = firestore.collection('accounts');

  DocumentSnapshot snapshot = await accounts.doc(_accountID).get();
  if (snapshot.exists) {
    // Get the value of the field by its ID
    dynamic fieldValue = snapshot.get('accountName');
    print('The value of the field is: $fieldValue');
    return fieldValue;
  } else {
    print('The document does not exist');
    return "";
  }
}
