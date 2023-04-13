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

  void showAccountTransactionAdderDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: AccountTransactionAdder(),
        );
      },
    );
  }

  void showAccountTransactionUpdaterDialog(
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
    CollectionReference transactions = firestore.collection('transactions');

    if (currentAccountID == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    Query userAccountTransactions = transactions
        .where('accountID', isEqualTo: currentAccountID)
        .where('isActive', isEqualTo: true)
        .orderBy('createDate', descending: true);

    Query userSourceAccountTransactions = transactions
        .where('sourceAccountID', isEqualTo: currentAccountID)
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
                                          child: Text(data['transactionType']),
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
                                                            showAccountTransactionUpdaterDialog(
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
                            if (data['transactionType'] == 'Collection' ||
                                data['transactionType'] == 'Payment' ||
                                data['transactionType'] == 'Buy' ||
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
                                          if (data['transactionType'] ==
                                              'Collection')
                                            Text(
                                              '-${data['amount'].toString()} ',
                                              style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 20),
                                            ),
                                          if (data['transactionType'] ==
                                              'Payment')
                                            Text(
                                              '+${data['amount'].toString()}',
                                              style: TextStyle(
                                                  color: Colors.green,
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
                                                            showAccountTransactionUpdaterDialog(
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
                                            data['sourceAccountID']),
                                        getAccountNameByID(data['accountID']),
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
                                            return Text(
                                                '$sourceAccountName \u2190 $accountName');
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
  AccountTransactionAdder();
  @override
  AccountTransactionAdderState createState() => AccountTransactionAdderState();
}

class AccountTransactionAdderState extends State<AccountTransactionAdder> {
  CollectionReference transactions =
      FirebaseFirestore.instance.collection('transactions');
  final _formKey = GlobalKey<FormState>();

  String unit = '';
  String transactionDetail = '';
  double amount = 0.0;
  final SharedPreferencesManager prefs = SharedPreferencesManager();

  String dropDownValueUnit = 'For once';
  String selectedTransactionType = 'Add';

  String? currentLedgerID;

  TextEditingController sourceAccountController = TextEditingController();
  TextEditingController externalAccountController = TextEditingController();
  String sourceAccountValidator = "";
  String selectedCategory = "Choose a category";

  DateTime _selectedDate = DateTime.now(); // Default selected date
  TimeOfDay _selectedTime =
      TimeOfDay.fromDateTime(DateTime.now()); // Default selected time

  String? currentAccountID;

  @override
  void initState() {
    super.initState();

    prefs.getString("accountID").then((value) {
      setState(() {
        currentAccountID = value;
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

  @override
  void dispose() {
    sourceAccountController.dispose(); // Dispose the controller properly
    super.dispose();
  }

  Future<List<String>>? getInternalAccountNames() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference accounts = firestore.collection('accounts');

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

  @override
  Widget build(BuildContext context) {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference accounts = firestore.collection('accounts');
    // Date formatter for displaying the selected date
    final dateFormatter = DateFormat('dd/MM/yyyy');
    // Time formatter for displaying the selected time
    final timeFormatter = DateFormat('HH:mm');
    const List<String> unitList = <String>[
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
                      fontSize:
                          selectedTransactionType == 'Collection' ? 22.0 : 18.0,
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
                          unit = value;
                          print(value + dropDownValueUnit + unit);
                        });
                      },
                      items: unitList
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 25.0),
                    ElevatedButton(
                      onPressed: () {
                        String selectedSourceAccountID =
                            sourceAccountController.text;
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          createAccountTransaction(
                            selectedTransactionType,
                            amount,
                            transactionDetail,
                            selectedSourceAccountID,
                          );
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
                        }),
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
                          unit = value;
                          print(value + dropDownValueUnit + unit);
                        });
                      },
                      items: unitList
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 25.0),
                    ElevatedButton(
                      onPressed: () {
                        String selectedSourceAccount =
                            sourceAccountController.text;

                        setState(() {
                          sourceAccountValidator = "";
                        });
                        if (selectedSourceAccount == null ||
                            selectedSourceAccount == "") {
                          setState(() {
                            sourceAccountValidator =
                                'Please enter a valid internal (source) account.';
                          });
                        } else {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            createAccountTransaction(
                                selectedTransactionType,
                                amount,
                                transactionDetail,
                                selectedSourceAccount);
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

  Future<void> createAccountTransaction(
      String _selectedTransactionType,
      double _amount,
      String _transactionDetail,
      String _selectedSourceAccount) async {
    String? currentAccountID = await prefs.getString("accountID");
    var newAccountTransaction;
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference accounts = firestore.collection('accounts');
    String sourceAccountID = "";

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
          accountID: currentAccountID!,
          sourceAccountID: sourceAccountID,
          stockID: "",
          transactionType: selectedTransactionType,
          amount: _amount,
          totalPrice: 0,
          price: 0,
          transactionDetail: _transactionDetail,
          categoryName: '',
          period: '',
          duration: 0,
          targetDate: DateTime.now(),
          isDone: true,
          createDate: DateTime.now(),
          updateDate: DateTime.now(),
          isActive: true);

      DocumentReference transactionsDoc = await transactions.add({
        'accountID': newAccountTransaction.accountID,
        'sourceAccountID': newAccountTransaction.sourceAccountID,
        'stockID': newAccountTransaction.stockID,
        'transactionType': newAccountTransaction.transactionType,
        'amount': newAccountTransaction.amount,
        'totalPrice': newAccountTransaction.totalPrice,
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

    try {
      DocumentSnapshot documentSnapshot =
          await accounts.doc(currentAccountID).get();

      double accountBalance = await documentSnapshot.get('balance');
      if (newAccountTransaction.transactionType == 'Payment' ||
          newAccountTransaction.transactionType == 'Add') {
        await documentSnapshot.reference
            .update({'balance': accountBalance + amount});
      } else if (newAccountTransaction.transactionType == 'Collection' ||
          newAccountTransaction.transactionType == 'Subtract') {
        await documentSnapshot.reference
            .update({'balance': accountBalance - amount});
      }

      if (newAccountTransaction.transactionType == 'Collection' ||
          newAccountTransaction.transactionType == 'Payment') {
        final sourceAccountDoc = firestore
            .collection('accounts')
            .doc(newAccountTransaction.sourceAccountID);
        final snapshot = await sourceAccountDoc.get();
        double sourceAccountBalance = 0;

        if (snapshot.exists) {
          final dataMap = snapshot.data();
          sourceAccountBalance = dataMap!['balance'];
        } else {
          print('No document exists with ID');
        }

        if (newAccountTransaction.transactionType == 'Collection') {
          await sourceAccountDoc.update(
              {'balance': sourceAccountBalance + newAccountTransaction.amount});
        } else if (newAccountTransaction.transactionType == 'Payment') {
          await sourceAccountDoc.update(
              {'balance': sourceAccountBalance - newAccountTransaction.amount});
        }
      }
    } catch (e) {
      print('An error caught: $e');
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
