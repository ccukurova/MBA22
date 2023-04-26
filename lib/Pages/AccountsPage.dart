import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:MBA22/Models/AccountModel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Helpers/SharedPreferencesManager.dart';
import 'package:MBA22/Models/LedgerModel.dart';
import 'MainPage.dart';
import 'AccountTransactionPage.dart';

class AccountsPage extends StatefulWidget {
  @override
  _AccountsPage createState() => _AccountsPage();
}

class _AccountsPage extends State<AccountsPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? currentUserID;
  String? currentLedgerID;

  final SharedPreferencesManager prefs = SharedPreferencesManager();

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

  Future<void> setAccountID(DocumentSnapshot document) async {
    final accountID = document.id;
    await prefs.setString("accountID", accountID);
  }

  void showAccountAdderDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: AccountAdder(),
        );
      },
    );
  }

  void showAccountUpdaterDialog(
      BuildContext context, DocumentSnapshot<Object?> document) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: AccountUpdater(document),
        );
      },
    );
  }

  Future<void> setLedgerID(DocumentSnapshot document) async {
    final ledgerID = document.id;
    await prefs.setString("ledgerID", ledgerID);
  }

  @override
  Widget build(BuildContext context) {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference accounts = firestore.collection('accounts');
    CollectionReference transactions = firestore.collection('transactions');

    if (currentUserID == null || currentLedgerID == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    Query userAccounts = accounts
        .where('ledgerID', isEqualTo: currentLedgerID)
        .where('isActive', isEqualTo: true)
        .orderBy('updateDate', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text('Accounts'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: userAccounts.snapshots(),
                    builder: (BuildContext context,
                        AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }

                      if (snapshot.hasData && snapshot.data != null) {
                        return ListView(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          children: snapshot.data!.docs
                              .map((DocumentSnapshot document) {
                            Map<String, dynamic> data =
                                document.data() as Map<String, dynamic>;
                            String documentId =
                                document.id; // Get the document ID
                            return InkWell(
                              onTap: () {
                                // Go to transactions
                              },
                              child: ListTile(
                                title: Text(data['accountName']),
                                subtitle: Text(data['unit']),
                                onTap: () {
                                  setAccountID(document);
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              AccountTransactionPage()));
                                },
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FutureBuilder<double>(
                                      future: getAccountBalance(documentId),
                                      builder: (BuildContext context,
                                          AsyncSnapshot<double> snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          // While the future is not yet complete, show a progress indicator
                                          return Center(
                                              child:
                                                  CircularProgressIndicator());
                                        } else if (snapshot.hasError) {
                                          // If the future encounters an error, show an error message
                                          return Text(
                                              'Error: ${snapshot.error}');
                                        } else {
                                          // If the future completes successfully, display the account balance
                                          return Text('${snapshot.data}');
                                        }
                                      },
                                    ), // Pass the document ID as a parameter
                                    IconButton(
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
                                                        showAccountUpdaterDialog(
                                                            context, document);
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
                                                        await accounts
                                                            .doc(documentId)
                                                            .update({
                                                          'isActive': false
                                                        });
                                                        await accounts
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
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
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
                  showAccountAdderDialog(context);
                },
                child: Icon(Icons.add),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<double> getAccountBalance(String accountID) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference transactions = firestore.collection('transactions');
    CollectionReference accounts = firestore.collection('accounts');
    double balance = 0;
    String accountType = ''; // declare as a string

    Query userAccountTransactions = transactions
        .where('accountID', arrayContains: accountID)
        .where('isActive', isEqualTo: true)
        .orderBy('createDate', descending: true);

    DocumentReference accountRef = accounts.doc(accountID);
    DocumentSnapshot docSnapshot = await accountRef.get();
    if (docSnapshot.exists) {
      accountType = docSnapshot.get('accountType');
    }

    QuerySnapshot querySnapshot = await userAccountTransactions.get();
    querySnapshot.docs.forEach((transactionDoc) {
      Map<String, dynamic>? transactionData =
          transactionDoc.data() as Map<String, dynamic>?;
      if (transactionData!['transactionType'] == 'Collection' &&
          accountType == 'External') {
        balance -= transactionData['totalPrice'];
      } else if (transactionData!['transactionType'] == 'Collection' &&
          accountType == 'Internal') {
        balance += transactionData['totalPrice'];
      } else if (transactionData!['transactionType'] == 'Payment' &&
          accountType == 'External') {
        balance += transactionData['totalPrice'];
      } else if (transactionData!['transactionType'] == 'Payment' &&
          accountType == 'Internal') {
        balance -= transactionData['totalPrice'];
      } else if (transactionData!['transactionType'] == 'Buy' &&
          accountType == 'External') {
        balance += transactionData['totalPrice'];
      } else if (transactionData!['transactionType'] == 'Buy' &&
          accountType == 'Internal') {
        balance -= transactionData['totalPrice'];
      } else if (transactionData!['transactionType'] == 'Sell' &&
          accountType == 'External') {
        balance -= transactionData['totalPrice'];
      } else if (transactionData!['transactionType'] == 'Sell' &&
          accountType == 'Internal') {
        balance += transactionData['totalPrice'];
      } else if (transactionData!['transactionType'] == 'Add') {
        balance += transactionData['totalPrice'];
      } else if (transactionData!['transactionType'] == 'Subtract') {
        balance -= transactionData['totalPrice'];
      }
    });

    return balance;
  }
}

class AccountAdder extends StatefulWidget {
  AccountAdder();
  @override
  _AccountAdder createState() => _AccountAdder();
}

class _AccountAdder extends State<AccountAdder> {
  CollectionReference accounts =
      FirebaseFirestore.instance.collection('accounts');
  final _formKey = GlobalKey<FormState>();
  String accountName = '';
  String unit = 'TRY';
  String accountType = 'Internal';
  final SharedPreferencesManager prefs = SharedPreferencesManager();

  String dropdownValueAccountType = 'Internal';
  String dropDownValueUnit = 'TRY';

  @override
  Widget build(BuildContext context) {
    const List<String> accountTypeList = <String>['Internal', 'External'];
    const List<String> unitList = <String>['TRY', 'USD'];

    return Stack(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Add Account',
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
      Container(
        child: Padding(
          padding: EdgeInsets.only(left: 10, top: 60, right: 10, bottom: 10),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
                child: Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Account Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter a account name.';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      accountName = value!;
                    },
                  ),
                  SizedBox(height: 16.0),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Account type'),
                    SizedBox(width: 20),
                    DropdownButton<String>(
                      value: dropdownValueAccountType,
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
                          dropdownValueAccountType = value!;
                          accountType = dropdownValueAccountType;
                          print(value + dropdownValueAccountType + accountType);
                        });
                      },
                      items: accountTypeList
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    )
                  ]),
                  SizedBox(height: 16.0),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Currency'),
                    SizedBox(width: 20),
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
                    )
                  ]),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        createAccount(accountName, accountType, unit);
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
    ]);
  }

  Future<void> createAccount(
      String _accountName, String _accountType, String _unit) async {
    Future<String?> UserIDValue = prefs.getString("userID");
    String? currentLedgerID = await prefs.getString("ledgerID");

    var newAccount = AccountModel(
        ledgerID: currentLedgerID!,
        accountName: _accountName,
        accountType: _accountType,
        unit: _unit,
        balance: 0,
        createDate: DateTime.now(),
        updateDate: DateTime.now(),
        isActive: true);

    DocumentReference ledgersDoc = await accounts.add({
      'ledgerID': newAccount.ledgerID,
      'accountName': newAccount.accountName,
      'accountType': newAccount.accountType,
      'unit': newAccount.unit,
      'balance': newAccount.balance,
      'createDate': Timestamp.fromDate(newAccount.createDate),
      'updateDate': Timestamp.fromDate(newAccount.updateDate),
      'isActive': newAccount.isActive
    });
  }
}

class AccountUpdater extends StatefulWidget {
  final DocumentSnapshot<Object?> document;

  AccountUpdater(this.document);

  @override
  AccountUpdaterState createState() => AccountUpdaterState();
}

class AccountUpdaterState extends State<AccountUpdater> {
  CollectionReference accounts =
      FirebaseFirestore.instance.collection('accounts');
  final _formKey = GlobalKey<FormState>();
  String accountName = '';
  String unit = '';
  String accountType = '';
  final SharedPreferencesManager prefs = SharedPreferencesManager();

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  String initialAccountType = 'Internal';
  String initialUnit = 'TRY';
  List<String> accountTypeList = <String>['Internal', 'External'];
  List<String> unitList = <String>['TRY', 'USD'];
  String dropdownValueAccountType = 'Internal';
  String dropDownValueUnit = 'TRY';

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Update Account',
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
      Container(
        child: Padding(
          padding: EdgeInsets.only(left: 10, top: 60, right: 10, bottom: 10),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    initialValue: widget.document['accountName'],
                    decoration: InputDecoration(
                      labelText: 'Account Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter a account name.';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      accountName = value!;
                    },
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        updateAccount(accountName, widget.document);
                        Navigator.pop(context);
                      }
                    },
                    child: Text('Update'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  Future<void> updateAccount(
      String _accountName, DocumentSnapshot<Object?> document) async {
    Future<String?> UserIDValue = prefs.getString("userID");
    String? currentLedgerID = await prefs.getString("ledgerID");

    DocumentReference docRef =
        firestore.collection('accounts').doc(document.id);

    docRef.get().then((doc) {
      if (doc.exists) {
        docRef.update(
            {'accountName': _accountName, 'updateDate': DateTime.now()});
      } else {
        print('Document does not exist!');
      }
    }).catchError((error) {
      print('Error getting document: $error');
    });
  }
}
