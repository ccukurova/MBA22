import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Helpers/SharedPreferencesManager.dart';
import 'package:MBA22/Models/LedgerModel.dart';
import 'MainPage.dart';

class LedgerPage extends StatefulWidget {
  @override
  _LedgerPage createState() => _LedgerPage();
}

class _LedgerPage extends State<LedgerPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  CollectionReference ledgers =
      FirebaseFirestore.instance.collection('ledgers');
  String? currentUserID;
  final SharedPreferencesManager prefs = SharedPreferencesManager();

  @override
  void initState() {
    super.initState();
    prefs.getString("userID").then((value) {
      setState(() {
        currentUserID = value;
      });
    });
  }

  Future<void> setLedgerID(DocumentSnapshot document) async {
    final ledgerID = document.id;
    await prefs.setString("ledgerID", ledgerID);
  }

  void _showLedgerAdderDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: LedgerAdder(),
        );
      },
    );
  }

  void showLedgerUpdaterDialog(
      BuildContext context, DocumentSnapshot<Object?> document) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: ledgerUpdater(document),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference ledgers = firestore.collection('ledgers');

    if (currentUserID == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    Query userLedgers = ledgers
        .where('users', arrayContains: currentUserID)
        .where('isActive', isEqualTo: true)
        .orderBy('updateDate', descending: true);

    return Scaffold(
        appBar: AppBar(
          title: Text('Ledgers'),
        ),
        body: Stack(children: [
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: userLedgers.snapshots(),
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
                            return InkWell(
                                onTap: () {
                                  setLedgerID(document);
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              MainPage(document.id)));
                                },
                                child: ListTile(
                                    title: Text(data['ledgerName']),
                                    subtitle: Text(data['ledgerDetail']),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
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
                                                              Icon(Icons.share),
                                                          title: Text('Share'),
                                                          onTap: () {
                                                            // do something
                                                            Navigator.pop(
                                                                context);
                                                            showShareLedger(
                                                                context,
                                                                document);
                                                          },
                                                        ),
                                                        ListTile(
                                                          leading:
                                                              Icon(Icons.edit),
                                                          title: Text('Update'),
                                                          onTap: () {
                                                            // do something
                                                            Navigator.pop(
                                                                context);
                                                            showLedgerUpdaterDialog(
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
                                                            await ledgers
                                                                .doc(documentId)
                                                                .update({
                                                              'isActive': false
                                                            });
                                                            await ledgers
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
                                      ],
                                    )));
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
                  _showLedgerAdderDialog(context);
                },
                child: Icon(Icons.add),
              ),
            ),
          ),
        ]));
  }

  void showShareLedger(
      BuildContext context, DocumentSnapshot<Object?> document) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: shareLedger(document),
        );
      },
    );
  }
}

class LedgerAdder extends StatefulWidget {
  LedgerAdder();
  @override
  _LedgerAdder createState() => _LedgerAdder();
}

class _LedgerAdder extends State<LedgerAdder> {
  CollectionReference ledgers =
      FirebaseFirestore.instance.collection('ledgers');
  final _formKeyCreateLedger = GlobalKey<FormState>();
  final _formKeySubscribeLedger = GlobalKey<FormState>();
  String ledgerName = '';
  String ledgerDetail = '';
  final SharedPreferencesManager prefs = SharedPreferencesManager();
  String? currentUserID;

  String ledgerToSubscribe = '';

  @override
  void initState() {
    super.initState();
    getUserID();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Add Ledger',
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
          padding: EdgeInsets.only(left: 20, top: 80, right: 20, bottom: 40),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Form(
                    key: _formKeyCreateLedger,
                    child: Column(children: [
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Ledger Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter a ledger name.';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          ledgerName = value!;
                        },
                      ),
                      SizedBox(height: 16.0),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Ledger Detail (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        onSaved: (value) {
                          ledgerDetail = value!;
                        },
                      ),
                      SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKeyCreateLedger.currentState!.validate()) {
                            _formKeyCreateLedger.currentState!.save();
                            createLedger(ledgerName, ledgerDetail);
                            Navigator.of(context).pop();
                          }
                        },
                        child: Text('Add'),
                      ),
                    ])),
                SizedBox(height: 16.0),
                Form(
                    key: _formKeySubscribeLedger,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                thickness: 2.0,
                                color: Colors.black,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                "Or subscribe ",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.0,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                thickness: 2.0,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.0),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Ledger ID',
                            border: OutlineInputBorder(),
                          ),
                          onSaved: (value) {
                            ledgerToSubscribe = value!;
                          },
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter a ledger ID.';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.0),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKeySubscribeLedger.currentState!
                                .validate()) {
                              _formKeySubscribeLedger.currentState!.save();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  duration: Duration(seconds: 3),
                                  content: FutureBuilder<String>(
                                    future:
                                        subscribeToLedger(ledgerToSubscribe),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<String> snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.done) {
                                        // Future has completed
                                        if (snapshot.hasData) {
                                          // Display the result of the future in the snackbar
                                          return Text(snapshot.data!);
                                        } else {
                                          // Future completed with an error
                                          return Text(
                                              "Error: ${snapshot.error}");
                                        }
                                      } else {
                                        // Future not yet complete
                                        return Text("Subscribing to ledger...");
                                      }
                                    },
                                  ),
                                ),
                              );
                              Navigator.of(context).pop();
                            }
                          },
                          child: Text('Subscribe'),
                        ),
                      ],
                    ))
              ],
            ),
          ),
        )
      ],
    );
  }

  Future<void> getUserID() async {
    await prefs.getString("userID").then((value) {
      setState(() {
        currentUserID = value;
      });
    });
  }

  Future<void> createLedger(String _ledgerName, String _ledgerDetail) async {
    String? currentUserID = await prefs.getString("userID");
    List<String> users = [currentUserID!];

    var newLedger = LedgerModel(
        users: users,
        ledgerName: _ledgerName,
        ledgerDetail: _ledgerDetail,
        ledgerType: "commercial",
        createDate: DateTime.now(),
        updateDate: DateTime.now(),
        isActive: true);

    DocumentReference ledgersDoc = await ledgers.add({
      'users': newLedger.users,
      'ledgerName': newLedger.ledgerName,
      'ledgerDetail': newLedger.ledgerDetail,
      'ledgerType': newLedger.ledgerType,
      'createDate': Timestamp.fromDate(newLedger.createDate),
      'updateDate': Timestamp.fromDate(newLedger.updateDate),
      'isActive': newLedger.isActive
    });
  }

  Future<String> subscribeToLedger(String ledgerToSubscribe) async {
    DocumentReference subscribedLedgerDoc = ledgers.doc(ledgerToSubscribe);
    return subscribedLedgerDoc.get().then((doc) {
      if (doc.exists) {
        // Add the ledger ID to the users array in the Firestore document
        doc.reference.update({
          "users": FieldValue.arrayUnion([currentUserID])
        });
        return 'Subscribed to the ledger';
      } else {
        return 'Ledger not found';
      }
    }).catchError((error) {
      // Handle any errors that occur during the future execution
      return 'Error subscribing to ledger: $error';
    });
  }
}

class ledgerUpdater extends StatefulWidget {
  final DocumentSnapshot<Object?> document;

  ledgerUpdater(this.document);

  @override
  ledgerUpdaterState createState() => ledgerUpdaterState();
}

class ledgerUpdaterState extends State<ledgerUpdater> {
  CollectionReference ledgers =
      FirebaseFirestore.instance.collection('ledgers');
  final _formKey = GlobalKey<FormState>();
  String ledgerName = '';
  String ledgerDetail = '';
  final SharedPreferencesManager prefs = SharedPreferencesManager();
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Update Ledger',
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
          padding: EdgeInsets.only(left: 20, top: 80, right: 20, bottom: 40),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    initialValue: widget.document['ledgerName'],
                    decoration: InputDecoration(
                      labelText: 'Ledger Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter a ledger name.';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      ledgerName = value!;
                    },
                  ),
                  SizedBox(height: 16.0),
                  TextFormField(
                    initialValue: widget.document['ledgerDetail'],
                    decoration: InputDecoration(
                      labelText: 'Ledger Detail (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    onSaved: (value) {
                      ledgerDetail = value!;
                    },
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        updateLedger(ledgerName, ledgerDetail, widget.document);
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text('Update'),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Future<void> updateLedger(String _ledgerName, String _ledgerDetail,
      DocumentSnapshot<Object?> document) async {
    DocumentReference docRef = firestore.collection('ledgers').doc(document.id);

    docRef.get().then((doc) {
      if (doc.exists) {
        docRef.update({
          'ledgerName': _ledgerName,
          'ledgerDetail': _ledgerDetail,
          'updateDate': DateTime.now()
        });
      } else {
        print('Document does not exist!');
      }
    }).catchError((error) {
      print('Error getting document: $error');
    });
  }
}

class shareLedger extends StatefulWidget {
  final DocumentSnapshot<Object?> document;

  shareLedger(this.document);

  @override
  shareLedgerState createState() => shareLedgerState();
}

class shareLedgerState extends State<shareLedger> {
  String? currentUserID;
  final SharedPreferencesManager prefs = SharedPreferencesManager();

  @override
  void initState() {
    super.initState();
    getUserID();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Share Ledger',
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
          padding: EdgeInsets.only(left: 20, top: 80, right: 20, bottom: 40),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('You can send this ID to share your ledger with others:'),
                SizedBox(height: 16.0),
                Container(
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: Colors.blue, width: 2.0)),
                  child: SelectableText(
                    widget.document.id,
                    style: TextStyle(
                      color: Colors.blue,
                    ),
                  ),
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.document.id));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Copied to clipboard!'),
                    ));
                  },
                  child: Text('Copy'),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Future<void> getUserID() async {
    await prefs.getString("userID").then((value) {
      setState(() {
        currentUserID = value;
      });
    });
  }
}
