import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:MBA22/Models/AccountModel.dart';
import 'package:MBA22/Pages/StockTransactionPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Helpers/SharedPreferencesManager.dart';
import 'package:MBA22/Models/LedgerModel.dart';
import '../Models/StockModel.dart';
import 'MainPage.dart';

class StockPage extends StatefulWidget {
  @override
  StockPageState createState() => StockPageState();
}

class StockPageState extends State<StockPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? currentLedgerID;

  final SharedPreferencesManager prefs = SharedPreferencesManager();

  @override
  void initState() {
    super.initState();

    prefs.getString("ledgerID").then((value) {
      setState(() {
        currentLedgerID = value;
      });
    });
  }

  Future<void> setStockID(DocumentSnapshot document) async {
    final stockID = document.id;
    await prefs.setString("stockID", stockID);
  }

  void showStockAdderDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: StockAdder(),
        );
      },
    );
  }

  void showStockUpdaterDialog(
      BuildContext context, DocumentSnapshot<Object?> document) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: StockUpdater(document),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference stocks = firestore.collection('stocks');

    if (currentLedgerID == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    Query userStocks = stocks
        .where('ledgerID', isEqualTo: currentLedgerID)
        .where('isActive', isEqualTo: true)
        .orderBy('updateDate', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text('Stocks'),
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
                    stream: userStocks.snapshots(),
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
                            return InkWell(
                              onTap: () {
                                setStockID(document);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            StockTransactionPage()));
                              },
                              child: ListTile(
                                title: Text(data['stockName']),
                                subtitle: Text(data['unit']),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(data['balance'].toString()),
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
                                                        showStockUpdaterDialog(
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
                                                        await stocks
                                                            .doc(documentId)
                                                            .update({
                                                          'isActive': false
                                                        });
                                                        await stocks
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
                  showStockAdderDialog(context);
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

class StockAdder extends StatefulWidget {
  StockAdder();
  @override
  StockAdderState createState() => StockAdderState();
}

class StockAdderState extends State<StockAdder> {
  CollectionReference stocks = FirebaseFirestore.instance.collection('stocks');
  final _formKey = GlobalKey<FormState>();
  String stockName = '';
  String unit = 'Piece';
  final SharedPreferencesManager prefs = SharedPreferencesManager();

  String dropDownValueUnit = 'Piece';

  @override
  Widget build(BuildContext context) {
    const List<String> unitList = <String>['Piece', 'kilogram'];

    return Stack(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Add Stock',
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
                      labelText: 'Stock Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter a stock name.';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      stockName = value!;
                    },
                  ),
                  SizedBox(height: 16.0),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Unit'),
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
                        createStock(stockName, unit);
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

  Future<void> createStock(String _stockName, String _unit) async {
    String? currentLedgerID = await prefs.getString("ledgerID");

    var newStock = StockModel(
        ledgerID: currentLedgerID!,
        stockName: _stockName,
        unit: _unit,
        balance: 0.0,
        createDate: DateTime.now(),
        updateDate: DateTime.now(),
        isActive: true);

    DocumentReference stocksDoc = await stocks.add({
      'ledgerID': newStock.ledgerID,
      'stockName': newStock.stockName,
      'unit': newStock.unit,
      'balance': newStock.balance,
      'createDate': Timestamp.fromDate(newStock.createDate),
      'updateDate': Timestamp.fromDate(newStock.updateDate),
      'isActive': newStock.isActive
    });
  }
}

class StockUpdater extends StatefulWidget {
  final DocumentSnapshot<Object?> document;

  StockUpdater(this.document);

  @override
  StockUpdaterState createState() => StockUpdaterState();
}

class StockUpdaterState extends State<StockUpdater> {
  CollectionReference stocks = FirebaseFirestore.instance.collection('stocks');
  final _formKey = GlobalKey<FormState>();
  String stockName = '';
  String unit = '';
  final SharedPreferencesManager prefs = SharedPreferencesManager();

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  String initialUnit = '';
  List<String> unitList = <String>['Piece', 'kilogram'];
  String dropDownValueUnit = 'Piece';

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Update Stock',
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
                    initialValue: widget.document['stockName'],
                    decoration: InputDecoration(
                      labelText: 'Stock Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter a stock name.';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      stockName = value!;
                    },
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        updateStock(stockName, widget.document);
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

  Future<void> updateStock(
      String _stockName, DocumentSnapshot<Object?> document) async {
    String? currentLedgerID = await prefs.getString("ledgerID");

    DocumentReference docRef = firestore.collection('stocks').doc(document.id);

    docRef.get().then((doc) {
      if (doc.exists) {
        docRef
            .update({'accountName': _stockName, 'updateDate': DateTime.now()});
      } else {
        print('Document does not exist!');
      }
    }).catchError((error) {
      print('Error getting document: $error');
    });
  }
}
