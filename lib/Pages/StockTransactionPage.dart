import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:MBA22/Models/AccountModel.dart';
import 'package:MBA22/Models/TransactionModel.dart';
import 'package:MBA22/Pages/CategoriesPage.dart';
import 'package:MBA22/Pages/SelectDatePage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Helpers/SharedPreferencesManager.dart';
import 'package:MBA22/Models/LedgerModel.dart';
import '../Models/TransactionModel.dart';
import '../Services/ExchangerateRequester.dart';
import 'MainPage.dart';
import 'package:intl/intl.dart';
import 'package:textfield_search/textfield_search.dart';

import 'Widgets/TargetDateBar.dart';

class StockTransactionPage extends StatefulWidget {
  @override
  StockTransactionPageState createState() => StockTransactionPageState();
}

class StockTransactionPageState extends State<StockTransactionPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? currentStockID;
  String? currentLedgerID;
  final SharedPreferencesManager prefs = SharedPreferencesManager();

  @override
  void initState() {
    super.initState();

    prefs.getString("stockID").then((value) {
      setState(() {
        currentStockID = value;
      });
    });
    prefs.getString("ledgerID").then((value) {
      setState(() {
        currentLedgerID = value;
      });
    });
  }

  void showStockTransactionAdderDialog(BuildContext context,
      {DocumentSnapshot<Object?>? document}) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(content: StockTransactionAdder(document: document));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference stockTransactions =
        firestore.collection('transactions');

    print('BUILD WORKED');

    if (currentStockID == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    Query userStockTransactions = stockTransactions
        .where('stockID', isEqualTo: currentStockID)
        .where('isActive', isEqualTo: true)
        .orderBy('createDate', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text('Stock Transactions'),
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
                    stream: userStockTransactions.snapshots(),
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
                            if (data['transactionType'] == 'Add' ||
                                data['transactionType'] == 'Subtract') {
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
                                                    'Add')
                                                  Text(
                                                    '+${data['amount'].toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                        color: Colors.green,
                                                        fontSize: 20),
                                                  ),
                                                if (data['transactionType'] ==
                                                    'Subtract')
                                                  Text(
                                                    '-${data['amount'].toStringAsFixed(2)}',
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
                                        flex: 2,
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
                                                            showStockTransactionAdderDialog(
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
                                      )
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
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        flex: 2),
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          if (data['transactionType'] == 'Buy')
                                            Text(
                                              '+${data['amount'].toString()} ',
                                              style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 20),
                                            ),
                                          if (data['transactionType'] == 'Sell')
                                            Text(
                                              '-${data['amount'].toString()}',
                                              style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 20),
                                            ),
                                          if (data['amount'] == 0)
                                            Text(
                                              data['amount'].toString(),
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
                                                            showStockTransactionAdderDialog(
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
                                        '${data['amount']}x${data['price'].toStringAsFixed(2)}=${data['total'].toStringAsFixed(2)} ${data['currencies'][0]} (${data['convertedTotal']} ${data['currencies'][1]})',
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
                                                'Error: ${snapshot.error}');
                                          }
                                        } else {
                                          return CircularProgressIndicator();
                                        }
                                      },
                                    ),
                                    if (data['period'] != 'Now')
                                      Column(
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
                  showStockTransactionAdderDialog(context);
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

class StockTransactionAdder extends StatefulWidget {
  final DocumentSnapshot<Object?>? document;
  const StockTransactionAdder({Key? key, this.document}) : super(key: key);
  @override
  StockTransactionAdderState createState() => StockTransactionAdderState();
}

class StockTransactionAdderState extends State<StockTransactionAdder> {
  CollectionReference stockTransactions =
      FirebaseFirestore.instance.collection('transactions');
  final _formKey = GlobalKey<FormState>();
  String selectedDurationText = "∞";
  int selectedDuration = -1;
  TextEditingController duration = TextEditingController();
  TextEditingController amountTextController = new TextEditingController();
  TextEditingController priceTextController = new TextEditingController();
  TextEditingController detailsTextController = new TextEditingController();

  String period = 'Now';
  String transactionDetail = '';
  double amount = 0.0;
  double total = 0.0;
  double price = 0.0;
  final SharedPreferencesManager prefs = SharedPreferencesManager();

  String dropDownValuePeriod = 'Now';
  String selectedTransactionType = 'Add';

  String totalOutput = "Total price";
  String sourceAccountValidator = "";
  String externalAccountValidator = "";
  String selectedCategory = "Choose a category";
  String selectedSourceAccount = 'Select an internal account';
  String selectedExternalAccount = 'Select an external account';

  DateTime _selectedDate = DateTime.now(); // Default selected date
  TimeOfDay _selectedTime =
      TimeOfDay.fromDateTime(DateTime.now()); // Default selected time

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

  @override
  void initState() {
    super.initState();
    prefs.getString("accountType").then((value) {
      setState(() {
        if (widget.document != null) {
          selectedTransactionType = widget.document!['transactionType'];
          setFieldValuesToUpdate();
        }
      });
    });
  }

  Future<List<String>>? getInternalAccountNames() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference accounts = firestore.collection('accounts');
    String? currentLedgerID = await prefs.getString("ledgerID");
    Query userAccountsQuery = accounts
        .where('ledgerID', isEqualTo: currentLedgerID)
        .where('isActive', isEqualTo: true)
        .where('accountType', isEqualTo: 'Internal')
        .orderBy('updateDate', descending: true);

    List<String> accountNames = [];
    QuerySnapshot querySnapshot = await userAccountsQuery.get();
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

  Future<List<String>>? getExternalAccountNames() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference accounts = firestore.collection('accounts');
    String? currentLedgerID = await prefs.getString("ledgerID");
    Query userAccountsQuery = accounts
        .where('ledgerID', isEqualTo: currentLedgerID)
        .where('isActive', isEqualTo: true)
        .where('accountType', isEqualTo: 'External')
        .orderBy('updateDate', descending: true);

    List<String> accountNames = [];
    QuerySnapshot querySnapshot = await userAccountsQuery.get();
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
      'Every week',
      'Every month',
      'Every year'
    ];
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
              TextButton(
                onPressed: () {},
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      // Change the text style when clicked
                      selectedTransactionType = 'Add';
                    });
                  },
                  child: Text(
                    'Add',
                    style: TextStyle(
                      decoration: selectedTransactionType == 'Add'
                          ? TextDecoration.underline
                          : TextDecoration.none, // Add underline
                      color: selectedTransactionType == 'Add'
                          ? Color.fromARGB(255, 33, 236, 243)
                          : Colors.blue, // Change color when selected
                      fontSize: selectedTransactionType == 'Add' ? 22.0 : 18.0,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      // Change the text style when clicked
                      selectedTransactionType = 'Subtract';
                    });
                  },
                  child: Text(
                    'Subtract',
                    style: TextStyle(
                      decoration: selectedTransactionType == 'Subtract'
                          ? TextDecoration.underline
                          : TextDecoration.none, // Add underline
                      color: selectedTransactionType == 'Subtract'
                          ? Color.fromARGB(255, 33, 236, 243)
                          : Colors.blue, // Change color when selected
                      fontSize:
                          selectedTransactionType == 'Subtract' ? 22.0 : 18.0,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      // Change the text style when clicked
                      selectedTransactionType = 'Buy';
                    });
                  },
                  child: Text(
                    'Buy',
                    style: TextStyle(
                      decoration: selectedTransactionType == 'Buy'
                          ? TextDecoration.underline
                          : TextDecoration.none, // Add underline
                      color: selectedTransactionType == 'Buy'
                          ? Color.fromARGB(255, 33, 236, 243)
                          : Colors.blue, // Change color when selected
                      fontSize: selectedTransactionType == 'Buy' ? 22.0 : 18.0,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      // Change the text style when clicked
                      selectedTransactionType = 'Sell';
                    });
                  },
                  child: Text(
                    'Sell',
                    style: TextStyle(
                      decoration: selectedTransactionType == 'Sell'
                          ? TextDecoration.underline
                          : TextDecoration.none, // Add underline
                      color: selectedTransactionType == 'Sell'
                          ? Color.fromARGB(255, 33, 236, 243)
                          : Colors.blue, // Change color when selected
                      fontSize: selectedTransactionType == 'Sell' ? 22.0 : 18.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      SizedBox(height: 16.0),
      if (selectedTransactionType == 'Add' ||
          selectedTransactionType == 'Subtract')
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
                          amount = double.parse(value!);
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
                    SizedBox(height: 16.0),
                    Column(
                      children: [
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
                        DocumentSnapshot currentStock =
                            await accounts.doc().get();
                        List<String> currencies = ['stock', 'stock'];
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
                          targetDate = DateTime.now();
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
                            createStockTransaction(
                                selectedTransactionType,
                                amount,
                                price,
                                total,
                                total,
                                currencies,
                                transactionDetail,
                                selectedSourceAccount,
                                selectedExternalAccount,
                                selectedDuration,
                                targetDate,
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
      if (selectedTransactionType == 'Buy' || selectedTransactionType == 'Sell')
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
                    SizedBox(
                      height: 25.0,
                      child: Text(
                        externalAccountValidator,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    FutureBuilder<List<String>>(
                      future: getExternalAccountNames(),
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
                          accountNames.insert(0, 'Select an external account');

                          return DropdownButton<String>(
                            value: selectedExternalAccount,
                            elevation: 16,
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedExternalAccount = newValue;
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
                          amount = double.parse(value!);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("Please enter a valid amount."),
                          ));
                        }
                      },
                      onChanged: (value) {
                        setState(() {
                          try {
                            amount = double.tryParse(value)!;
                            total = amount * price;
                            totalOutput = total.toString();
                            print(
                                'amount = ${amount.toString()} price= ${price.toStringAsFixed(2)} total= ${total.toStringAsFixed(2)}');
                          } catch (e) {
                            print(e);
                          }
                        });
                      },
                    ),
                    Text(
                      '\u00D7', // Unicode for multiplication symbol
                      style: TextStyle(
                        fontSize: 25.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextFormField(
                      controller: priceTextController,
                      decoration: InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value!.isEmpty && value == '0') {
                          return 'Please enter a price.';
                        } else if (double.tryParse(value) == null) {
                          return 'Please enter a valid number.';
                        } else if (double.tryParse(value) == 0) {
                          return 'Price cannot be zero.';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        try {
                          price = double.parse(value!);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("Please enter a valid price."),
                          ));
                        }
                      },
                      onChanged: (value) {
                        setState(() {
                          try {
                            price = double.tryParse(value)!;
                            total = amount * price;
                            totalOutput = total.toString();
                            print(
                                'amount = ${amount.toString()} price= ${price.toStringAsFixed(2)} total= ${total.toStringAsFixed(2)}');
                          } catch (e) {
                            print(e);
                          }
                        });
                      },
                    ),
                    Text(
                      '\u2193', // Unicode for downwards arrow symbol
                      style: TextStyle(
                        fontSize: 25.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      totalOutput,
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                        DocumentSnapshot currentStock =
                            await accounts.doc().get();

                        setState(() {
                          sourceAccountValidator = "";
                          externalAccountValidator = "";
                        });
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
                          targetDate = DateTime.now();
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
                            if (selectedSourceAccount == null ||
                                selectedSourceAccount == "") {
                              setState(() {
                                sourceAccountValidator =
                                    'Please enter a valid internal (source) account.';
                              });
                            } else if (selectedExternalAccount == null ||
                                selectedExternalAccount == "") {
                              setState(() {
                                externalAccountValidator =
                                    'Please enter a valid external account.';
                              });
                            } else if (selectedSourceAccount == null ||
                                selectedSourceAccount == "") {
                              setState(() {
                                sourceAccountValidator =
                                    'Please enter a valid internal (source) account.';
                              });
                            } else {
                              late String baseCurrency = '';
                              late String targetCurrency = '';

                              Query _selectedExternalAccountQuery = accounts
                                  .where('accountName',
                                      isEqualTo: selectedExternalAccount)
                                  .limit(1);
                              QuerySnapshot selectedExternalAccountSnapshot =
                                  await _selectedExternalAccountQuery.get();

                              selectedExternalAccountSnapshot.docs
                                  .forEach((element) {
                                baseCurrency = element['unit'];
                              });

                              Query _selectedSourceAccountQuery = accounts
                                  .where('accountName',
                                      isEqualTo: selectedExternalAccount)
                                  .limit(1);
                              QuerySnapshot selectedSourceAccountSnapshot =
                                  await _selectedSourceAccountQuery.get();

                              selectedSourceAccountSnapshot.docs
                                  .forEach((element) {
                                targetCurrency = element['unit'];
                              });

                              List<String> currencies = [
                                baseCurrency,
                                targetCurrency
                              ];

                              double convertedTotal = await calculateCurrency(
                                  total, baseCurrency, targetCurrency);

                              createStockTransaction(
                                  selectedTransactionType,
                                  amount,
                                  price,
                                  total,
                                  convertedTotal,
                                  currencies,
                                  transactionDetail,
                                  selectedSourceAccount,
                                  selectedExternalAccount,
                                  selectedDuration,
                                  targetDate,
                                  period);
                              Navigator.pop(context);
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

    if (selectedTransactionType == 'Buy' || selectedTransactionType == 'Sell') {
      await accounts
          .doc(document['accountID'][1])
          .get()
          .then((value) => selectedSourceAccount = value['accountName']);
      await accounts
          .doc(document['accountID'][0])
          .get()
          .then((value) => selectedExternalAccount = value['accountName']);
    }

    amountTextController.text = document['total'].toString();
    priceTextController.text = document['price'].toString();
    total = document['total'];
    totalOutput = total.toString();
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

  Future<void> createStockTransaction(
      String _selectedTransactionType,
      double _amount,
      double _price,
      double _total,
      double _convertedTotal,
      List<String> _currencies,
      String _transactionDetail,
      String _selectedSourceAccount,
      String _selectedExternalAccount,
      int _selectedDuration,
      DateTime _targetDate,
      String _period) async {
    String? currentLedgerID = await prefs.getString("ledgerID");
    String? currentStockID = await prefs.getString("stockID");
    var newAddStockTransaction;
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference stocks = firestore.collection('stocks');
    CollectionReference accounts = firestore.collection('accounts');
    String sourceAccountID = "";
    String externalAccountID = "";
    String? choosenCategory = await prefs.getString("choosenCategory");
    choosenCategory = choosenCategory ?? "";
    bool isDone;
    if (_selectedDuration == 0) {
      isDone = true;
    } else {
      isDone = false;
    }

    if (_selectedTransactionType == 'Buy' ||
        _selectedTransactionType == 'Sell') {
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

      final QuerySnapshot externalAccountQuerySnapshot = await accounts
          .where('accountName', isEqualTo: _selectedExternalAccount)
          .where('isActive', isEqualTo: true)
          .limit(1) // Use limit(1) if you expect only one result
          .get();

      if (externalAccountQuerySnapshot.docs.isNotEmpty) {
        final externalAccountDocumentSnapshot =
            externalAccountQuerySnapshot.docs[0];
        externalAccountID = externalAccountDocumentSnapshot.id;
        print('external account ID: $externalAccountID');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No external account found with given name.'),
          ),
        );
      }
    }

    try {
      newAddStockTransaction = TransactionModel(
          accountID: [externalAccountID, sourceAccountID],
          ledgerID: currentLedgerID!,
          stockID: currentStockID!,
          transactionType: selectedTransactionType,
          amount: _amount,
          convertedTotal: _convertedTotal,
          currencies: _currencies,
          total: _total,
          price: _price,
          transactionDetail: _transactionDetail,
          categoryName: choosenCategory!,
          period: _period,
          duration: _selectedDuration,
          targetDate: _targetDate,
          isDone: isDone,
          createDate: DateTime.now(),
          updateDate: DateTime.now(),
          isActive: true);

      DocumentReference transactionsDoc = await stockTransactions.add({
        'accountID': newAddStockTransaction.accountID,
        'ledgerID': newAddStockTransaction.ledgerID,
        'stockID': newAddStockTransaction.stockID,
        'transactionType': newAddStockTransaction.transactionType,
        'amount': newAddStockTransaction.amount,
        'total': newAddStockTransaction.total,
        'convertedTotal': newAddStockTransaction.convertedTotal,
        'currencies': newAddStockTransaction.currencies,
        'price': newAddStockTransaction.price,
        'transactionDetail': newAddStockTransaction.transactionDetail,
        'categoryName': newAddStockTransaction.categoryName,
        'period': newAddStockTransaction.period,
        'duration': newAddStockTransaction.duration,
        'targetDate': newAddStockTransaction.targetDate,
        'isDone': newAddStockTransaction.isDone,
        'createDate': Timestamp.fromDate(newAddStockTransaction.createDate),
        'updateDate': Timestamp.fromDate(newAddStockTransaction.updateDate),
        'isActive': newAddStockTransaction.isActive
      });
    } catch (e) {
      print('Error caught: $e');
    }
  }

  Future<String> getChoosenCategory() async {
    return await prefs.getString("choosenCategory") ?? "Choose a category";
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
