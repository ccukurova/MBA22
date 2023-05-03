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
import 'MainPage.dart';
import 'package:intl/intl.dart';
import 'package:textfield_search/textfield_search.dart';

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

  void showStockTransactionAdderDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: StockTransactionAdder(),
        );
      },
    );
  }

  void showStockTransactionUpdaterDialog(
      BuildContext context, DocumentSnapshot<Object?> document) async {
    // await showDialog(
    //   context: context,
    //   builder: (BuildContext context) {
    //     return AlertDialog(
    //       content: StockTransactionUpdater(document),
    //     );
    //   },
    // );
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
                                                    '+${data['amount'].toString()}',
                                                    style: TextStyle(
                                                        color: Colors.green,
                                                        fontSize: 20),
                                                  ),
                                                if (data['transactionType'] ==
                                                    'Subtract')
                                                  Text(
                                                    '-${data['amount'].toString()}',
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
                                                            showStockTransactionUpdaterDialog(
                                                                context,
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
                                      Text(DateFormat('dd-MM-yyyy – kk:mm')
                                          .format(data['createDate']
                                              .toDate()
                                              .toLocal())),
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
                                                            showStockTransactionUpdaterDialog(
                                                                context,
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
                                    Text(
                                      '${data['amount']}x${data['price'].toString()}=${data['totalPrice']}',
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
                                    Text(DateFormat('dd-MM-yyyy – kk:mm')
                                        .format(data['createDate']
                                            .toDate()
                                            .toLocal())),
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
  StockTransactionAdder();
  @override
  StockTransactionAdderState createState() => StockTransactionAdderState();
}

class StockTransactionAdderState extends State<StockTransactionAdder> {
  CollectionReference stockTransactions =
      FirebaseFirestore.instance.collection('transactions');
  final _formKey = GlobalKey<FormState>();
  String selectedDurationText = "∞";
  int selectedDuration = 1;
  TextEditingController duration = TextEditingController();

  String period = 'For once';
  String transactionDetail = '';
  double amount = 0.0;
  double totalPrice = 0.0;
  double price = 0.0;
  final SharedPreferencesManager prefs = SharedPreferencesManager();

  String dropDownValueUnit = 'For once';
  String selectedTransactionType = 'Add';

  String totalPriceOutput = "Total price";
  String sourceAccountValidator = "";
  String externalAccountValidator = "";
  String selectedCategory = "Choose a category";

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
    // Start listening to changes.
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
      'For once',
      'Every week',
      'Every month',
      'Every year'
    ];

    TextEditingController sourceAccountController = TextEditingController();
    TextEditingController externalAccountController = TextEditingController();

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
                        SizedBox(height: 16.0),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: 20),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 30.0,
                                  color: Colors.blue,
                                ),
                                GestureDetector(
                                  child: Text(
                                      ' ${dateFormatter.format(_selectedDate)}', // Display selected date
                                      style: TextStyle(fontSize: 16)),
                                  onTap: () async {
                                    final DateTime? selected =
                                        await showDatePicker(
                                      context: context,
                                      initialDate: _selectedDate,
                                      firstDate: DateTime(1900),
                                      lastDate: DateTime.now()
                                          .add(Duration(days: 365)),
                                    );
                                    if (selected != null) {
                                      _onDateSelected(selected);
                                    }
                                  },
                                ),
                                GestureDetector(
                                  child: Text(
                                    '  ${timeFormatter.format(DateTime(0, 0, 0, _selectedTime.hour, _selectedTime.minute))}',
                                    style: TextStyle(fontSize: 16),
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
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 16), // Spacer

                    DropdownButton<String>(
                      value: dropDownValueUnit,
                      icon: const Icon(Icons.arrow_downward),
                      elevation: 16,
                      style: const TextStyle(color: Colors.deepPurple),
                      underline: Container(
                        height: 2,
                        color: Colors.deepPurpleAccent,
                      ),
                      onChanged: (String? value) {
                        // This is called when the user selects an item.
                        setState(() {
                          dropDownValueUnit = value!;
                          period = value;
                          print(value + dropDownValueUnit + period);
                        });
                      },
                      items: periodList
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 25.0),
                    if (dropDownValueUnit != 'For once')
                      Container(
                        child: Row(
                          children: [
                            Text('Duration'),
                            TextButton(
                              onPressed: () => {
                                if (selectedDuration > 1)
                                  {
                                    selectedDuration--,
                                    duration.text = selectedDuration.toString()
                                  }
                                else if (selectedDuration == 1)
                                  {duration.text = '∞'}
                              },
                              child: Text('<'),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: duration,
                              ),
                            ),
                            TextButton(
                                onPressed: () => {
                                      if (selectedDuration + 1 >= 1)
                                        {
                                          selectedDuration++,
                                          duration.text =
                                              selectedDuration.toString()
                                        }
                                    },
                                child: Text('>')),
                          ],
                        ),
                      ),
                    SizedBox(height: 25.0),
                    ElevatedButton(
                      onPressed: () {
                        DateTime targetDate = DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                          _selectedDate.day,
                          _selectedTime.hour,
                          _selectedTime.minute,
                        );
                        String selectedSourceAccountID =
                            sourceAccountController.text;
                        String selectedExternalAccountID =
                            externalAccountController.text;
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          createStockTransaction(
                              selectedTransactionType,
                              amount,
                              totalPrice,
                              price,
                              transactionDetail,
                              selectedSourceAccountID,
                              selectedExternalAccountID,
                              selectedDuration,
                              targetDate,
                              period);
                          Navigator.pop(context);
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
                        if (snapshot.hasData) {
                          return TextFieldSearch(
                              initialList: snapshot.data,
                              label: 'Internal account(source)',
                              controller: sourceAccountController);
                        } else {
                          return Center(child: CircularProgressIndicator());
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
                        if (snapshot.hasData) {
                          return TextFieldSearch(
                              initialList: snapshot.data,
                              label: 'External account',
                              controller: externalAccountController);
                        } else {
                          return Center(child: CircularProgressIndicator());
                        }
                      },
                    ),
                    SizedBox(height: 25.0),
                    TextFormField(
                      initialValue: '0',
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
                            totalPrice = amount * price;
                            totalPriceOutput = totalPrice.toString();
                            print(
                                'amount = ${amount.toString()} price= ${price.toString()} totalPrice= ${totalPrice.toString()}');
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
                      initialValue: '0',
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
                            totalPrice = amount * price;
                            totalPriceOutput = totalPrice.toString();
                            print(
                                'amount = ${amount.toString()} price= ${price.toString()} totalPrice= ${totalPrice.toString()}');
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
                      totalPriceOutput,
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 25.0),
                    TextFormField(
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
                        SizedBox(height: 16.0),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: 20),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 30.0,
                                  color: Colors.blue,
                                ),
                                GestureDetector(
                                  child: Text(
                                      ' ${dateFormatter.format(_selectedDate)}', // Display selected date
                                      style: TextStyle(fontSize: 16)),
                                  onTap: () async {
                                    final DateTime? selected =
                                        await showDatePicker(
                                      context: context,
                                      initialDate: _selectedDate,
                                      firstDate: DateTime(1900),
                                      lastDate: DateTime.now()
                                          .add(Duration(days: 365)),
                                    );
                                    if (selected != null) {
                                      _onDateSelected(selected);
                                    }
                                  },
                                ),
                                GestureDetector(
                                  child: Text(
                                    '  ${timeFormatter.format(DateTime(0, 0, 0, _selectedTime.hour, _selectedTime.minute))}',
                                    style: TextStyle(fontSize: 16),
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
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 20), // Spacer

                    DropdownButton<String>(
                      value: dropDownValueUnit,
                      icon: const Icon(Icons.arrow_downward),
                      elevation: 16,
                      style: const TextStyle(color: Colors.deepPurple),
                      underline: Container(
                        height: 2,
                        color: Colors.deepPurpleAccent,
                      ),
                      onChanged: (String? value) {
                        // This is called when the user selects an item.
                        setState(() {
                          dropDownValueUnit = value!;
                          period = value;
                          print(value + dropDownValueUnit + period);
                        });
                      },
                      items: periodList
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 25.0),
                    if (dropDownValueUnit != 'For once')
                      Container(
                        child: Row(
                          children: [
                            Text('Duration'),
                            TextButton(
                              onPressed: () => {
                                if (selectedDuration > 1)
                                  {
                                    selectedDuration--,
                                    duration.text = selectedDuration.toString()
                                  }
                                else if (selectedDuration == 1)
                                  {duration.text = '∞'}
                              },
                              child: Text('<'),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: duration,
                              ),
                            ),
                            TextButton(
                                onPressed: () => {
                                      if (selectedDuration + 1 >= 1)
                                        {
                                          selectedDuration++,
                                          duration.text =
                                              selectedDuration.toString()
                                        }
                                    },
                                child: Text('>')),
                          ],
                        ),
                      ),
                    SizedBox(height: 25.0),
                    ElevatedButton(
                      onPressed: () {
                        DateTime targetDate = DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                          _selectedDate.day,
                          _selectedTime.hour,
                          _selectedTime.minute,
                        );
                        String selectedSourceAccount =
                            sourceAccountController.text;
                        String selectedExternalAccount =
                            externalAccountController.text;

                        setState(() {
                          sourceAccountValidator = "";
                          externalAccountValidator = "";
                        });
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
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            createStockTransaction(
                                selectedTransactionType,
                                amount,
                                price,
                                totalPrice,
                                transactionDetail,
                                selectedSourceAccount,
                                selectedExternalAccount,
                                selectedDuration,
                                targetDate,
                                period);
                            Navigator.pop(context);
                          } else {
                            sourceAccountValidator =
                                'Please be sure all of your input values are valid.';
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

  Future<void> createStockTransaction(
      String _selectedTransactionType,
      double _amount,
      double _price,
      double _totalPrice,
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
          totalPrice: _totalPrice,
          price: _price,
          transactionDetail: _transactionDetail,
          categoryName: choosenCategory!,
          period: _period,
          duration: _selectedDuration,
          targetDate: _targetDate,
          isDone: true,
          createDate: DateTime.now(),
          updateDate: DateTime.now(),
          isActive: true);

      DocumentReference transactionsDoc = await stockTransactions.add({
        'accountID': newAddStockTransaction.accountID,
        'ledgerID': newAddStockTransaction.ledgerID,
        'stockID': newAddStockTransaction.stockID,
        'transactionType': newAddStockTransaction.transactionType,
        'amount': newAddStockTransaction.amount,
        'totalPrice': newAddStockTransaction.totalPrice,
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

    try {
      DocumentSnapshot documentSnapshot =
          await stocks.doc(currentStockID).get();

      double stockBalance = await documentSnapshot.get('balance');
      if (newAddStockTransaction.transactionType == 'Buy' ||
          newAddStockTransaction.transactionType == 'Add') {
        await documentSnapshot.reference
            .update({'balance': stockBalance + amount});
      } else if (newAddStockTransaction.transactionType == 'Sell' ||
          newAddStockTransaction.transactionType == 'Subtract') {
        await documentSnapshot.reference
            .update({'balance': stockBalance - amount});
      }

      if (newAddStockTransaction.transactionType == 'Buy' ||
          newAddStockTransaction.transactionType == 'Sell') {
        final sourceAccountDoc = firestore
            .collection('accounts')
            .doc(newAddStockTransaction.accountID[1]);
        final snapshot = await sourceAccountDoc.get();
        double sourceAccountBalance = 0;

        if (snapshot.exists) {
          final dataMap = snapshot.data();
          sourceAccountBalance = dataMap!['balance'];
        } else {
          print('No document exists with ID');
        }

        final externalAccountDoc = firestore
            .collection('accounts')
            .doc(newAddStockTransaction.accountID[0]);
        final externalAccountSnapshot = await externalAccountDoc.get();
        double externalAccountBalance = 0;

        if (externalAccountSnapshot.exists) {
          final externalAccountDataMap = externalAccountSnapshot.data();
          externalAccountBalance = externalAccountDataMap!['balance'];
        } else {
          print('No document exists with ID');
        }

        if (newAddStockTransaction.transactionType == 'Buy') {
          await sourceAccountDoc.update({
            'balance': sourceAccountBalance - newAddStockTransaction.totalPrice
          });
          await externalAccountDoc.update({
            'balance':
                externalAccountBalance + newAddStockTransaction.totalPrice
          });
        } else if (newAddStockTransaction.transactionType == 'Sell') {
          await sourceAccountDoc.update({
            'balance': sourceAccountBalance + newAddStockTransaction.totalPrice
          });
          await externalAccountDoc.update({
            'balance':
                externalAccountBalance - newAddStockTransaction.totalPrice
          });
        }
      }
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
}
