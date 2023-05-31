import 'package:MBA22/Pages/Widgets/targetDateBar.dart';
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

class AccountTransactionPage extends StatefulWidget {
  @override
  AccountTransactionPageState createState() => AccountTransactionPageState();
}

class AccountTransactionPageState extends State<AccountTransactionPage> {
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

  void showAccountTransactionAdderDialog(BuildContext context,
      {DocumentSnapshot<Object?>? document}) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            content: AccountTransactionAdder(document: document));
      },
    );
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
        .where('isActive', isEqualTo: true)
        .orderBy('createDate', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text('Account Transactions'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
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
                                                        .toStringAsFixed(2),
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
                                                            leading: Icon(
                                                                Icons.edit),
                                                            title:
                                                                Text('Update'),
                                                            onTap: () {
                                                              // do something
                                                              Navigator.pop(
                                                                  context);
                                                              showAccountTransactionAdderDialog(
                                                                  context,
                                                                  document:
                                                                      document);
                                                            },
                                                          ),
                                                          ListTile(
                                                            leading: Icon(
                                                                Icons.delete),
                                                            title:
                                                                Text('Delete'),
                                                            onTap: () async {
                                                              // do something
                                                              String
                                                                  documentId =
                                                                  document.id;
                                                              await transactions
                                                                  .doc(
                                                                      documentId)
                                                                  .update({
                                                                'isActive':
                                                                    false
                                                              });
                                                              await transactions
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
                                          flex: 2),
                                    ],
                                  ),
                                  subtitle: Column(
                                    children: [
                                      Text(
                                          '${DateFormat('dd-MM-yyyy – kk:mm').format(data['createDate'].toDate().toLocal())}'),
                                      SizedBox(height: 10),
                                      if (data['period'] != 'Now')
                                        TargetDateBar(
                                            targetDate:
                                                data['targetDate'].toDate(),
                                            period: data['period'],
                                            duration: data['duration'],
                                            isDone: data['isDone']),
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
                                    FutureBuilder<DocumentSnapshot>(
                                      future: getCurrentAccount(),
                                      builder: (BuildContext context,
                                          AsyncSnapshot<DocumentSnapshot>
                                              snapshot) {
                                        if (snapshot.hasData) {
                                          final accountData = snapshot.data!;

                                          return Expanded(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                if (data['transactionType'] ==
                                                        'Collection' &&
                                                    accountData[
                                                            'accountType'] ==
                                                        'External')
                                                  Text(
                                                    '-${data['total'].toStringAsFixed(2)} ',
                                                    style: TextStyle(
                                                      color: Colors.red,
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
                                                    style: TextStyle(
                                                      color: Colors.green,
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
                                                    style: TextStyle(
                                                      color: Colors.green,
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
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 20,
                                                    ),
                                                  ),
                                                if (data['total'] == 0)
                                                  Text(
                                                    data['total']
                                                        .toStringAsFixed(2),
                                                    style:
                                                        TextStyle(fontSize: 20),
                                                  ),
                                              ],
                                            ),
                                            flex: 6,
                                          );
                                        } else if (snapshot.hasError) {
                                          return Text(
                                              'Error2: ${snapshot.error}');
                                        } else {
                                          return CircularProgressIndicator();
                                        }
                                      },
                                    ),
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
                                                            showAccountTransactionAdderDialog(
                                                                context,
                                                                document:
                                                                    document);
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
                                  ]),
                                  subtitle: Column(children: [
                                    FutureBuilder<List<String>>(
                                      future: Future.wait([
                                        getAccountNameByID(
                                            data['accountID'][0]),
                                        getAccountNameByID(
                                            data['accountID'][1]),
                                      ]),
                                      builder: (BuildContext context,
                                          AsyncSnapshot<List<String>>
                                              snapshot) {
                                        if (snapshot.connectionState ==
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
                                                'Error3: ${snapshot.error}');
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
                                      TargetDateBar(
                                          targetDate:
                                              data['targetDate'].toDate(),
                                          period: data['period'],
                                          duration: data['duration'],
                                          isDone: data['isDone']),
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
                                    FutureBuilder<DocumentSnapshot>(
                                      future: getCurrentAccount(),
                                      builder: (BuildContext context,
                                          AsyncSnapshot<DocumentSnapshot>
                                              snapshot) {
                                        if (snapshot.hasData) {
                                          final accountData = snapshot.data!;
                                          return Expanded(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                if (data['transactionType'] ==
                                                        'Buy' &&
                                                    accountData[
                                                            'accountType'] ==
                                                        'External')
                                                  Text(
                                                    '+${data['total'].toStringAsFixed(2)} ',
                                                    style: TextStyle(
                                                      color: Colors.green,
                                                      fontSize: 20,
                                                    ),
                                                  ),
                                                if (data['transactionType'] ==
                                                        'Buy' &&
                                                    accountData[
                                                            'accountType'] ==
                                                        'Internal')
                                                  Text(
                                                    '-${data['convertedTotal'].toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 20,
                                                    ),
                                                  ),
                                                if (data['transactionType'] ==
                                                        'Sell' &&
                                                    accountData[
                                                            'accountType'] ==
                                                        'External')
                                                  Text(
                                                    '-${data['total'].toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 20,
                                                    ),
                                                  ),
                                                if (data['transactionType'] ==
                                                        'Sell' &&
                                                    accountData[
                                                            'accountType'] ==
                                                        'Internal')
                                                  Text(
                                                    '+${data['convertedTotal'].toStringAsFixed(2)} ',
                                                    style: TextStyle(
                                                      color: Colors.green,
                                                      fontSize: 20,
                                                    ),
                                                  ),
                                                if (data['total'] == 0)
                                                  Text(
                                                    data['total']
                                                        .toStringAsFixed(2),
                                                    style:
                                                        TextStyle(fontSize: 20),
                                                  ),
                                              ],
                                            ),
                                            flex: 6,
                                          );
                                        } else if (snapshot.hasError) {
                                          return Text(
                                              'Error4: ${snapshot.error}');
                                        } else {
                                          return CircularProgressIndicator();
                                        }
                                      },
                                    ),
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
                                                            // showStockTransactionUpdaterDialog(
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
                                                            await stockTransactions
                                                                .doc(documentId)
                                                                .update({
                                                              'isActive': false
                                                            });
                                                            await stockTransactions
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
                                    if (data['currencies'][0] !=
                                        data['currencies'][1])
                                      Text(
                                        '${data['amount']}x${data['price'].toStringAsFixed(2)}=${data['total'].toStringAsFixed(2)} ${data['currencies'][0]} (${data['convertedTotal'].toStringAsFixed(2)} ${data['currencies'][1]})',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    if (data['currencies'][0] ==
                                        data['currencies'][1])
                                      Text(
                                        '${data['amount']}x${data['price'].toStringAsFixed(2)}=${data['total'].toStringAsFixed(2)} ${data['currencies'][0]}',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    FutureBuilder<List<String>>(
                                      future: Future.wait([
                                        getAccountNameByID(
                                            data['accountID'][1]),
                                        getAccountNameByID(
                                            data['accountID'][0]),
                                      ]),
                                      builder: (BuildContext context,
                                          AsyncSnapshot<List<String>>
                                              snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.done) {
                                          if (snapshot.hasData) {
                                            final sourceAccountName =
                                                snapshot.data![0];
                                            final accountName =
                                                snapshot.data![1];
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
                                                'Error5: ${snapshot.error}');
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
                                      TargetDateBar(
                                          targetDate:
                                              data['targetDate'].toDate(),
                                          period: data['period'],
                                          duration: data['duration'],
                                          isDone: data['isDone']),
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
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: FloatingActionButton(
                onPressed: () {
                  showAccountTransactionAdderDialog(context);
                },
                child: Icon(Icons.add),
              ),
            ),
          ),
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

class AccountTransactionAdder extends StatefulWidget {
  final DocumentSnapshot<Object?>? document;
  const AccountTransactionAdder({Key? key, this.document}) : super(key: key);
  @override
  AccountTransactionAdderState createState() => AccountTransactionAdderState();
}

class AccountTransactionAdderState extends State<AccountTransactionAdder> {
  CollectionReference transactions =
      FirebaseFirestore.instance.collection('transactions');
  final _formKey = GlobalKey<FormState>();
  TextEditingController amountTextController = new TextEditingController();
  TextEditingController detailsTextController = new TextEditingController();
  String period = 'Now';
  String transactionDetail = '';
  double total = 0.0;
  final SharedPreferencesManager prefs = SharedPreferencesManager();

  String dropDownValuePeriod = 'Now';
  String selectedTransactionType = 'Increase';

  String? currentLedgerID;

  String sourceAccountValidator = "";
  String selectedCategory = "Choose a category";

  DateTime _selectedDate = DateTime.now(); // Default selected date
  TimeOfDay _selectedTime =
      TimeOfDay.fromDateTime(DateTime.now()); // Default selected time

  String? currentAccountID;
  String? accountType;
  TextEditingController duration = TextEditingController();

  String selectedDurationText = "∞";
  int selectedDuration = -1;
  String selectedSourceAccount = 'Select an internal account';
  @override
  void initState() {
    super.initState();

    prefs.getString("accountID").then((value) {
      setState(() {
        currentAccountID = value;
      });
    });

    prefs.getString("accountType").then((value) {
      setState(() {
        accountType = value;
        if (accountType == "Internal") {
          selectedTransactionType = 'Income';
        }
      });
    });
  }

  // On date selected function
  void _onDateSelected(DateTime selected) {
    setState(() {
      _selectedDate = selected;
    });
  }

  // On time selected function
  void _onTimeSelected(TimeOfDay selected) {
    setState(() {
      _selectedTime = selected;
    });
  }

  Future<List<String>> getInternalAccountNames() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference accounts = firestore.collection('accounts');
    String? currentLedgerID = await prefs.getString("ledgerID");

    QuerySnapshot querySnapshot = await accounts
        .where('ledgerID', isEqualTo: currentLedgerID)
        .where('isActive', isEqualTo: true)
        .where('accountType', isEqualTo: 'Internal')
        .orderBy('updateDate', descending: true)
        .get();

    List<String> accountNames = [];
    for (DocumentSnapshot documentSnapshot in querySnapshot.docs) {
      Map<String, dynamic>? data =
          documentSnapshot.data() as Map<String, dynamic>?;
      if (data != null) {
        String accountName = data['accountName'];
        accountNames.add(accountName);
      }
    }

    return accountNames;
  }

  @override
  Widget build(BuildContext context) {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference accounts = firestore.collection('accounts');
    // Date formatter for displaying the selected date
    final dateFormatter = DateFormat('dd/MM/yyyy');
    // Time formatter for displaying the selected time
    final timeFormatter = DateFormat('HH:mm');
    const List<String> periodList = <String>[
      'Now',
      'Past',
      'For once',
      'Every day',
      'Every week',
      'Every month',
      'Every year'
    ];
    duration.text = '∞';

    if (widget.document != null && widget.document!.exists) {
      setFieldValuesToUpdate();
    }

    return Stack(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Create transaction',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop();
            },
          )
        ],
      ),
      Padding(
        padding: EdgeInsets.only(left: 10, top: 60, right: 10, bottom: 10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (accountType == 'External')
                TextButton(
                  onPressed: () {},
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        // Change the text style when clicked
                        selectedTransactionType = 'Increase';
                      });
                    },
                    child: Text(
                      'Increase',
                      style: TextStyle(
                        decoration: selectedTransactionType == 'Increase'
                            ? TextDecoration.underline
                            : TextDecoration.none,
                        color: selectedTransactionType == 'Increase'
                            ? Color.fromARGB(255, 33, 236, 243)
                            : Colors.blue, // Change color when selected
                        fontSize:
                            selectedTransactionType == 'Increase' ? 22.0 : 18.0,
                      ),
                    ),
                  ),
                ),
              if (accountType == 'External')
                TextButton(
                  onPressed: () {},
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        // Change the text style when clicked
                        selectedTransactionType = 'Decrease';
                      });
                    },
                    child: Text(
                      'Decrease',
                      style: TextStyle(
                        decoration: selectedTransactionType == 'Decrease'
                            ? TextDecoration.underline
                            : TextDecoration.none, // Add underline
                        color: selectedTransactionType == 'Decrease'
                            ? Color.fromARGB(255, 33, 236, 243)
                            : Colors.blue, // Change color when selected
                        fontSize:
                            selectedTransactionType == 'Decrease' ? 22.0 : 18.0,
                      ),
                    ),
                  ),
                ),
              if (accountType == 'Internal')
                TextButton(
                  onPressed: () {},
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        // Change the text style when clicked
                        selectedTransactionType = 'Income';
                      });
                    },
                    child: Text(
                      'Income',
                      style: TextStyle(
                        decoration: selectedTransactionType == 'Income'
                            ? TextDecoration.underline
                            : TextDecoration.none, // Add underline
                        color: selectedTransactionType == 'Income'
                            ? Color.fromARGB(255, 33, 236, 243)
                            : Colors.blue, // Change color when selected
                        fontSize:
                            selectedTransactionType == 'Income' ? 22.0 : 18.0,
                      ),
                    ),
                  ),
                ),
              if (accountType == 'Internal')
                TextButton(
                  onPressed: () {},
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        // Change the text style when clicked
                        selectedTransactionType = 'Outcome';
                      });
                    },
                    child: Text(
                      'Outcome',
                      style: TextStyle(
                        decoration: selectedTransactionType == 'Outcome'
                            ? TextDecoration.underline
                            : TextDecoration.none, // Add underline
                        color: selectedTransactionType == 'Outcome'
                            ? Color.fromARGB(255, 33, 236, 243)
                            : Colors.blue, // Change color when selected
                        fontSize:
                            selectedTransactionType == 'Outcome' ? 22.0 : 18.0,
                      ),
                    ),
                  ),
                ),
              if (accountType == 'External')
                TextButton(
                  onPressed: () {},
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        // Change the text style when clicked
                        selectedTransactionType = 'Collection';
                      });
                    },
                    child: Text(
                      'Collection',
                      style: TextStyle(
                        decoration: selectedTransactionType == 'Collection'
                            ? TextDecoration.underline
                            : TextDecoration.none, // Add underline
                        color: selectedTransactionType == 'Collection'
                            ? Color.fromARGB(255, 33, 236, 243)
                            : Colors.blue, // Change color when selected
                        fontSize: selectedTransactionType == 'Collection'
                            ? 22.0
                            : 18.0,
                      ),
                    ),
                  ),
                ),
              if (accountType == 'External')
                TextButton(
                  onPressed: () {},
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        // Change the text style when clicked
                        selectedTransactionType = 'Payment';
                      });
                    },
                    child: Text(
                      'Payment',
                      style: TextStyle(
                        decoration: selectedTransactionType == 'Payment'
                            ? TextDecoration.underline
                            : TextDecoration.none, // Add underline
                        color: selectedTransactionType == 'Payment'
                            ? Color.fromARGB(255, 33, 236, 243)
                            : Colors.blue, // Change color when selected
                        fontSize:
                            selectedTransactionType == 'Payment' ? 22.0 : 18.0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      SizedBox(height: 16.0),
      if (selectedTransactionType == 'Increase' ||
          selectedTransactionType == 'Decrease' ||
          selectedTransactionType == 'Income' ||
          selectedTransactionType == 'Outcome')
        Container(
          child: Padding(
            padding: EdgeInsets.only(left: 10, top: 120, right: 10, bottom: 10),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                  child: Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    TextFormField(
                      controller: amountTextController,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter an amount.';
                        } else if (double.tryParse(value) == null) {
                          return 'Please enter a valid number.';
                        } else if (double.tryParse(value) == 0) {
                          return 'Amount cannot be zero.';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        try {
                          total = double.parse(value!);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("Please enter a valid amount."),
                          ));
                        }
                      },
                    ),
                    SizedBox(height: 16.0),
                    TextFormField(
                      controller: detailsTextController,
                      decoration: InputDecoration(
                        labelText: 'Details',
                        border: OutlineInputBorder(),
                      ),
                      onSaved: (value) {
                        try {
                          transactionDetail = value!;
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("Please enter a valid detail text."),
                          ));
                        }
                      },
                    ),
                    SizedBox(height: 25),
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            print('Tabbed to category.');
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => CategoriesPage(
                                        onUpdate: updateSelectedCategory)));
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.tag,
                                size: 30.0,
                                color: Colors.blue,
                              ),
                              Text(selectedCategory)
                            ],
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month,
                              size: 30.0,
                              color: Colors.blue,
                            ),
                            DropdownButton<String>(
                              style: const TextStyle(fontSize: 14),
                              value: dropDownValuePeriod,
                              icon: const Icon(Icons.arrow_downward),
                              elevation: 16,
                              onChanged: (String? value) {
                                // This is called when the user selects an item.
                                setState(() {
                                  dropDownValuePeriod = value!;
                                  period = value;
                                });
                              },
                              items: periodList.map<DropdownMenuItem<String>>(
                                  (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: TextStyle(color: Colors.black),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            if (period != 'Now')
                              Icon(
                                Icons.access_time,
                                size: 30.0,
                                color: Colors.blue,
                              ),
                            if (period != 'Now' && period != 'Past')
                              GestureDetector(
                                child: Text(
                                    ' ${dateFormatter.format(_selectedDate)}', // Display selected date
                                    style: TextStyle(fontSize: 16)),
                                onTap: () async {
                                  final DateTime? selected =
                                      await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate,
                                    firstDate: DateTime.now(),
                                    lastDate:
                                        DateTime.now().add(Duration(days: 365)),
                                  );
                                  if (selected != null) {
                                    _onDateSelected(selected);
                                  }
                                },
                              ),
                            if (period == 'Past')
                              Builder(
                                builder: (BuildContext context) {
                                  return GestureDetector(
                                    child: Text(
                                      ' ${dateFormatter.format(_selectedDate)}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    onTap: () async {
                                      final DateTime? selected =
                                          await showDatePicker(
                                        context: context,
                                        initialDate: _selectedDate,
                                        firstDate: DateTime(1900),
                                        lastDate: DateTime.now(),
                                      );
                                      if (selected != null) {
                                        _onDateSelected(selected);
                                      }
                                    },
                                  );
                                },
                              ),
                            if (period != 'Now')
                              GestureDetector(
                                child: Text(
                                  '  ${timeFormatter.format(DateTime(0, 0, 0, _selectedTime.hour, _selectedTime.minute))}',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.black),
                                ),
                                onTap: () async {
                                  final TimeOfDay? selected =
                                      await showTimePicker(
                                    context: context,
                                    initialTime: _selectedTime,
                                  );
                                  if (selected != null) {
                                    _onTimeSelected(selected);
                                  }
                                },
                              ),
                          ],
                        ),
                        SizedBox(height: 10),
                        if (period != 'Now' &&
                            period != 'For once' &&
                            period != 'Past')
                          Row(
                            children: [
                              Icon(
                                Icons.refresh,
                                size: 30.0,
                                color: Colors.blue,
                              ),
                              Text('Repeat'),
                              TextButton(
                                onPressed: () => {
                                  if (selectedDuration == 2)
                                    {selectedDuration = -1, duration.text = '∞'}
                                  else if (selectedDuration <= -1)
                                    {}
                                  else
                                    {
                                      selectedDuration--,
                                      duration.text =
                                          selectedDuration.toString()
                                    }
                                },
                                child: Text('<'),
                              ),
                              Container(
                                width: 20,
                                child: TextFormField(
                                  controller: duration,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              TextButton(
                                  onPressed: () => {
                                        if (selectedDuration <= -1)
                                          {
                                            selectedDuration = 2,
                                            duration.text =
                                                selectedDuration.toString()
                                          }
                                        else
                                          {
                                            selectedDuration++,
                                            duration.text =
                                                selectedDuration.toString()
                                          }
                                      },
                                  child: Text('>')),
                            ],
                          ),
                      ],
                    ),
                    SizedBox(height: 25.0),
                    ElevatedButton(
                      onPressed: () async {
                        String baseCurrency;
                        DocumentSnapshot currentAccount =
                            await accounts.doc(currentAccountID).get();
                        baseCurrency = currentAccount['unit'];
                        List<String> currencies = [baseCurrency, baseCurrency];
                        DateTime targetDate;
                        if (period != "Now") {
                          targetDate = DateTime(
                            _selectedDate.year,
                            _selectedDate.month,
                            _selectedDate.day,
                            _selectedTime.hour,
                            _selectedTime.minute,
                          );
                        } else {
                          targetDate = DateTime.fromMillisecondsSinceEpoch(0,
                              isUtc: true);
                        }
                        if (_formKey.currentState!.validate() &&
                            selectedDurationText != "0" &&
                            selectedDurationText != "1") {
                          _formKey.currentState!.save();
                          if (period == "Now" || period == "Past") {
                            selectedDuration = 0;
                          } else if (period == "For once") {
                            selectedDuration = 1;
                          }
                          if (period == "Past" &&
                              targetDate.compareTo(DateTime.now()) >= 0) {
                            final snackBar = SnackBar(
                              content: Text(
                                  'Past target date cannot be greater than current date'),
                              duration: Duration(seconds: 2),
                            );
                            ScaffoldMessenger.of(context)
                                .showSnackBar(snackBar);
                          } else if (period == "For once" &&
                              targetDate.compareTo(DateTime.now()) <= 0) {
                            final snackBar = SnackBar(
                              content: Text(
                                  'Future target date cannot be less than current date'),
                              duration: Duration(seconds: 2),
                            );
                            ScaffoldMessenger.of(context)
                                .showSnackBar(snackBar);
                          } else {
                            createAccountTransaction(
                                selectedTransactionType,
                                total,
                                total,
                                currencies,
                                transactionDetail,
                                "",
                                targetDate,
                                selectedDuration,
                                period);
                            Navigator.pop(context);
                          }
                        }
                      },
                      child: Text('Add'),
                    ),
                  ],
                ),
              )),
            ),
          ),
        ),
      if (selectedTransactionType == 'Collection' ||
          selectedTransactionType == 'Payment')
        Container(
          child: Padding(
            padding: EdgeInsets.only(left: 10, top: 120, right: 10, bottom: 10),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                  child: Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 25.0,
                      child: Text(
                        sourceAccountValidator,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    FutureBuilder<List<String>>(
                      future: getInternalAccountNames(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          // While the future is loading
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          // If an error occurred
                          return Text('Error: ${snapshot.error}');
                        } else {
                          // When the future completes successfully
                          List<String> accountNames = snapshot.data!;
                          accountNames.insert(0, 'Select an internal account');

                          return DropdownButton<String>(
                            value: selectedSourceAccount,
                            elevation: 16,
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedSourceAccount = newValue;
                                });
                              }
                            },
                            items: accountNames
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            hint: Text('Internal account (source)'),
                          );
                        }
                      },
                    ),
                    SizedBox(height: 25.0),
                    TextFormField(
                        controller: amountTextController,
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value!.isEmpty && value == '0') {
                            return 'Please enter an amount.';
                          } else if (double.tryParse(value) == null) {
                            return 'Please enter a valid number.';
                          } else if (double.tryParse(value) == 0) {
                            return 'Amount cannot be zero.';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          try {
                            total = double.parse(value!);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text("Please enter a valid amount."),
                            ));
                          }
                        }),
                    SizedBox(height: 25.0),
                    TextFormField(
                      controller: detailsTextController,
                      decoration: InputDecoration(
                        labelText: 'Details',
                        border: OutlineInputBorder(),
                      ),
                      onSaved: (value) {
                        try {
                          transactionDetail = value!;
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("Please enter a valid detail text."),
                          ));
                        }
                      },
                    ),
                    SizedBox(height: 25.0),
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            print('Tabbed to category.');
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => CategoriesPage(
                                        onUpdate: updateSelectedCategory)));
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.tag,
                                size: 30.0,
                                color: Colors.blue,
                              ),
                              Text(selectedCategory)
                            ],
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month,
                              size: 30.0,
                              color: Colors.blue,
                            ),
                            DropdownButton<String>(
                              style: const TextStyle(fontSize: 14),
                              value: dropDownValuePeriod,
                              icon: const Icon(Icons.arrow_downward),
                              elevation: 16,
                              onChanged: (String? value) {
                                // This is called when the user selects an item.
                                setState(() {
                                  dropDownValuePeriod = value!;
                                  period = value;
                                });
                              },
                              items: periodList.map<DropdownMenuItem<String>>(
                                  (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: TextStyle(color: Colors.black),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            if (period != 'Now')
                              Icon(
                                Icons.access_time,
                                size: 30.0,
                                color: Colors.blue,
                              ),
                            if (period != 'Now' && period != 'Past')
                              GestureDetector(
                                child: Text(
                                    ' ${dateFormatter.format(_selectedDate)}', // Display selected date
                                    style: TextStyle(fontSize: 16)),
                                onTap: () async {
                                  final DateTime? selected =
                                      await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate,
                                    firstDate: DateTime.now(),
                                    lastDate:
                                        DateTime.now().add(Duration(days: 365)),
                                  );
                                  if (selected != null) {
                                    _onDateSelected(selected);
                                  }
                                },
                              ),
                            if (period == 'Past')
                              Builder(
                                builder: (BuildContext context) {
                                  return GestureDetector(
                                    child: Text(
                                      ' ${dateFormatter.format(_selectedDate)}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    onTap: () async {
                                      final DateTime? selected =
                                          await showDatePicker(
                                        context: context,
                                        initialDate: _selectedDate,
                                        firstDate: DateTime(1900),
                                        lastDate: DateTime.now(),
                                      );
                                      if (selected != null) {
                                        _onDateSelected(selected);
                                      }
                                    },
                                  );
                                },
                              ),
                            if (period != 'Now')
                              GestureDetector(
                                child: Text(
                                  '  ${timeFormatter.format(DateTime(0, 0, 0, _selectedTime.hour, _selectedTime.minute))}',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.black),
                                ),
                                onTap: () async {
                                  final TimeOfDay? selected =
                                      await showTimePicker(
                                    context: context,
                                    initialTime: _selectedTime,
                                  );
                                  if (selected != null) {
                                    _onTimeSelected(selected);
                                  }
                                },
                              ),
                          ],
                        ),
                        SizedBox(height: 10),
                        if (period != 'Now' &&
                            period != 'For once' &&
                            period != 'Past')
                          Row(
                            children: [
                              Icon(
                                Icons.refresh,
                                size: 30.0,
                                color: Colors.blue,
                              ),
                              Text('Repeat'),
                              TextButton(
                                onPressed: () => {
                                  if (selectedDuration == 2)
                                    {selectedDuration = -1, duration.text = '∞'}
                                  else if (selectedDuration <= -1)
                                    {}
                                  else
                                    {
                                      selectedDuration--,
                                      duration.text =
                                          selectedDuration.toString()
                                    }
                                },
                                child: Text('<'),
                              ),
                              Container(
                                width: 20,
                                child: TextFormField(
                                  controller: duration,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              TextButton(
                                  onPressed: () => {
                                        if (selectedDuration <= -1)
                                          {
                                            selectedDuration = 2,
                                            duration.text =
                                                selectedDuration.toString()
                                          }
                                        else
                                          {
                                            selectedDuration++,
                                            duration.text =
                                                selectedDuration.toString()
                                          }
                                      },
                                  child: Text('>')),
                            ],
                          ),
                      ],
                    ),
                    SizedBox(height: 25.0),
                    ElevatedButton(
                      onPressed: () async {
                        String baseCurrency;
                        DocumentSnapshot currentAccount =
                            await accounts.doc(currentAccountID).get();
                        baseCurrency = currentAccount['unit'];
                        List<String> currencies = [baseCurrency, baseCurrency];
                        DateTime targetDate;
                        if (period != "Now") {
                          targetDate = DateTime(
                            _selectedDate.year,
                            _selectedDate.month,
                            _selectedDate.day,
                            _selectedTime.hour,
                            _selectedTime.minute,
                          );
                        } else {
                          targetDate = DateTime.fromMillisecondsSinceEpoch(0,
                              isUtc: true);
                        }
                        if (_formKey.currentState!.validate() &&
                            selectedDurationText != "0" &&
                            selectedDurationText != "1") {
                          _formKey.currentState!.save();
                          if (period == "Now" || period == "Past") {
                            selectedDuration = 0;
                          } else if (period == "For once") {
                            selectedDuration = 1;
                          }
                          if (period == "Past" &&
                              targetDate.compareTo(DateTime.now()) >= 0) {
                            final snackBar = SnackBar(
                              content: Text(
                                  'Past target date cannot be greater than current date'),
                              duration: Duration(seconds: 2),
                            );
                            ScaffoldMessenger.of(context)
                                .showSnackBar(snackBar);
                          } else if (period == "For once" &&
                              targetDate.compareTo(DateTime.now()) <= 0) {
                            final snackBar = SnackBar(
                              content: Text(
                                  'Future target date cannot be less than current date'),
                              duration: Duration(seconds: 2),
                            );
                            ScaffoldMessenger.of(context)
                                .showSnackBar(snackBar);
                          } else {
                            setState(() {
                              sourceAccountValidator = '';
                            });

                            if (selectedSourceAccount == null ||
                                selectedSourceAccount == '') {
                              setState(() {
                                sourceAccountValidator =
                                    'Please enter a valid internal (source) account.';
                              });
                            } else {
                              if (_formKey.currentState!.validate()) {
                                _formKey.currentState!.save();

                                late String baseCurrency;
                                late String targetCurrency;
                                late List<String> currencies;

                                DocumentSnapshot currentAccount =
                                    await accounts.doc(currentAccountID).get();
                                baseCurrency = currentAccount['unit'];
                                Query _selectedSourceAccountQuery = accounts
                                    .where('accountName',
                                        isEqualTo: selectedSourceAccount)
                                    .limit(1);
                                QuerySnapshot selectedSourceAccountSnapshot =
                                    await _selectedSourceAccountQuery.get();

                                selectedSourceAccountSnapshot.docs
                                    .forEach((element) {
                                  targetCurrency = element['unit'];
                                });

                                double convertedTotal = await calculateCurrency(
                                    total, baseCurrency, targetCurrency);

                                currencies = [baseCurrency, targetCurrency];

                                bool isDone;

                                createAccountTransaction(
                                  selectedTransactionType,
                                  total,
                                  convertedTotal,
                                  currencies,
                                  transactionDetail,
                                  selectedSourceAccount,
                                  targetDate,
                                  selectedDuration,
                                  period,
                                );
                                Navigator.pop(context);
                              } else {
                                setState(() {
                                  sourceAccountValidator =
                                      'Please be sure all of your input values are valid.';
                                });
                              }
                            }
                          }
                        }
                      },
                      child: Text('Add'),
                    ),
                  ],
                ),
              )),
            ),
          ),
        ),
    ]);
  }

  Future<void> setFieldValuesToUpdate() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference accounts = firestore.collection('accounts');

    DocumentSnapshot<Map<String, dynamic>>? document =
        widget.document as DocumentSnapshot<Map<String, dynamic>>;

    selectedTransactionType = document['transactionType'];

    // await accounts
    //     .doc(document['accountID'][1])
    //     .get()
    //     .then((value) => selectedSourceAccount = value['accountName']);

    amountTextController.text = document['total'].toString();
    detailsTextController.text = document['transactionDetail'];
    updateSelectedCategory(document['categoryName']);
    period = document['period'];
    DateTime targetDate = document['targetDate'].toDate();
    _selectedDate = targetDate;
    _selectedTime = TimeOfDay(hour: targetDate.hour, minute: targetDate.minute);
    dropDownValuePeriod = period;
    if (document['duration'] > 1) {
      selectedDurationText = document['duration'].toString();
      duration.text = selectedDurationText;
      selectedDuration = document['duration'];
    } else if (document['duration'] <= -1) {
      selectedDurationText = '∞';
      duration.text = selectedDurationText;
      selectedDuration = document['duration'];
    }
  }

  Future<void> createAccountTransaction(
      String _selectedTransactionType,
      double total,
      double convertedTotal,
      List<String> _currencies,
      String _transactionDetail,
      String _selectedSourceAccount,
      DateTime _targetDate,
      int _selectedDuration,
      String _period) async {
    String? currentAccountID = await prefs.getString("accountID");
    String? currentLedgerID = await prefs.getString("ledgerID");
    var newAccountTransaction;
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference accounts = firestore.collection('accounts');
    String sourceAccountID = "";
    String? choosenCategory = await prefs.getString("choosenCategory");
    choosenCategory = choosenCategory ?? "";
    bool isDone;
    if (_selectedDuration == 0) {
      isDone = true;
    } else {
      isDone = false;
    }
    if (_selectedTransactionType == 'Collection' ||
        _selectedTransactionType == 'Payment') {
      final QuerySnapshot sourceAccountQuerySnapshot = await accounts
          .where('accountName', isEqualTo: _selectedSourceAccount)
          .where('isActive', isEqualTo: true)
          .limit(1) // Use limit(1) if you expect only one result
          .get();

      if (sourceAccountQuerySnapshot.docs.isNotEmpty) {
        final sourceAccountDocumentSnapshot =
            sourceAccountQuerySnapshot.docs[0];
        sourceAccountID = sourceAccountDocumentSnapshot.id;
        print('source account ID: $sourceAccountID');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No source account found with given name.'),
          ),
        );
      }
    }

    try {
      newAccountTransaction = TransactionModel(
          accountID: [currentAccountID!, sourceAccountID],
          ledgerID: currentLedgerID!,
          stockID: "",
          transactionType: _selectedTransactionType,
          amount: 0,
          total: total,
          convertedTotal: convertedTotal,
          currencies: _currencies,
          price: 0,
          transactionDetail: _transactionDetail,
          categoryName: choosenCategory!,
          period: _period,
          duration: _selectedDuration,
          targetDate: _targetDate,
          isDone: isDone,
          createDate: DateTime.now(),
          updateDate: DateTime.now(),
          isActive: true);

      DocumentReference transactionsDoc = await transactions.add({
        'accountID': newAccountTransaction.accountID,
        'ledgerID': newAccountTransaction.ledgerID,
        'stockID': newAccountTransaction.stockID,
        'transactionType': newAccountTransaction.transactionType,
        'amount': newAccountTransaction.amount,
        'total': newAccountTransaction.total,
        'convertedTotal': newAccountTransaction.convertedTotal,
        'currencies': newAccountTransaction.currencies,
        'price': newAccountTransaction.price,
        'transactionDetail': newAccountTransaction.transactionDetail,
        'categoryName': newAccountTransaction.categoryName,
        'period': newAccountTransaction.period,
        'duration': newAccountTransaction.duration,
        'targetDate': newAccountTransaction.targetDate,
        'isDone': newAccountTransaction.isDone,
        'createDate': Timestamp.fromDate(newAccountTransaction.createDate),
        'updateDate': Timestamp.fromDate(newAccountTransaction.updateDate),
        'isActive': newAccountTransaction.isActive
      });
    } catch (e) {
      print('Error caught: $e');
    }
  }

  void updateSelectedCategory(String _selectedCategory) {
    setState(() {
      selectedCategory = _selectedCategory;
    });
  }

  Future<double> calculateCurrency(
      double total, String baseCurrency, String targetCurrency) async {
    ExchangerateRequester requester = new ExchangerateRequester();
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference accounts = firestore.collection('accounts');

    if (baseCurrency != targetCurrency) {
      return await requester.getRate(baseCurrency, targetCurrency, total);
    }
    return total;
  }
}
