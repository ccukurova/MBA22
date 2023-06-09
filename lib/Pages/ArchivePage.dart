import 'package:MBA22/Pages/ArchiveTransactionPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:MBA22/Models/AccountModel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Helpers/SharedPreferencesManager.dart';
import 'package:MBA22/Models/LedgerModel.dart';
import '../Services/ExchangerateRequester.dart';
import 'MainPage.dart';
import 'AccountTransactionPage.dart';

class ArchivePage extends StatefulWidget {
  @override
  ArchivePageState createState() => ArchivePageState();
}

class ArchivePageState extends State<ArchivePage> {
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

  Future<void> setAccountType(DocumentSnapshot document) async {
    final accountType = document.get('accountType');
    await prefs.setString("accountType", accountType);
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
        .where('isActive', isEqualTo: false)
        .orderBy('updateDate', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text('Archive'),
      ),
      body: Stack(
        children: [
          Center(
              child: Padding(
                  padding:
                      EdgeInsets.only(left: 10, top: 0, right: 10, bottom: 0),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: 600,
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Image.asset(
                              'assets/images/archives.png', // Replace with the converted PNG file path
                              width: 200,
                              height: 200,
                            ),
                            SizedBox(height: 20),
                            Text('Select an archived account',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            SizedBox(height: 20),
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
                                      Map<String, dynamic> data = document
                                          .data() as Map<String, dynamic>;
                                      String documentId =
                                          document.id; // Get the document ID
                                      return InkWell(
                                          onTap: () {
                                            // Go to transactions
                                          },
                                          child: Card(
                                            child: ListTile(
                                              title: Text(data['accountName']),
                                              subtitle: Row(children: [
                                                Text('${data['accountType']}/'),
                                                Text(data['unit'])
                                              ]),
                                              onTap: () {
                                                setAccountID(document);
                                                setAccountType(document);
                                                Navigator.pushReplacement(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            ArchiveTransactionPage()));
                                              },
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  BalanceText(documentId),
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
                                                                        'Unarchive'),
                                                                    onTap:
                                                                        () async {
                                                                      // do something
                                                                      String
                                                                          documentId =
                                                                          document
                                                                              .id;

                                                                      Query userAccountTransactions = transactions
                                                                          .where(
                                                                              'accountID',
                                                                              arrayContains:
                                                                                  documentId)
                                                                          .where(
                                                                              'isActive',
                                                                              isEqualTo:
                                                                                  false)
                                                                          .orderBy(
                                                                              'createDate',
                                                                              descending: true);
                                                                      firestore
                                                                          .runTransaction(
                                                                              (transaction) async {
                                                                        QuerySnapshot
                                                                            snapshot =
                                                                            await userAccountTransactions.get();
                                                                        List<DocumentSnapshot>
                                                                            documents =
                                                                            snapshot.docs;
                                                                        for (DocumentSnapshot document
                                                                            in documents) {
                                                                          await transaction.update(
                                                                              document.reference,
                                                                              {
                                                                                'isActive': true
                                                                              });
                                                                        }
                                                                      });

                                                                      await accounts
                                                                          .doc(
                                                                              documentId)
                                                                          .update({
                                                                        'isActive':
                                                                            true
                                                                      });

                                                                      await accounts
                                                                          .doc(
                                                                              documentId)
                                                                          .update({
                                                                        'updateDate':
                                                                            DateTime.now()
                                                                      });
                                                                      Navigator.pop(
                                                                          context);
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

                                                                      Query userAccountTransactions = transactions
                                                                          .where(
                                                                              'accountID',
                                                                              arrayContains:
                                                                                  documentId)
                                                                          .where(
                                                                              'isActive',
                                                                              isEqualTo:
                                                                                  true)
                                                                          .orderBy(
                                                                              'createDate',
                                                                              descending: true);
                                                                      firestore
                                                                          .runTransaction(
                                                                              (transaction) async {
                                                                        QuerySnapshot
                                                                            snapshot =
                                                                            await userAccountTransactions.get();
                                                                        List<DocumentSnapshot>
                                                                            documents =
                                                                            snapshot.docs;
                                                                        for (DocumentSnapshot document
                                                                            in documents) {
                                                                          await transaction
                                                                              .delete(document.reference);
                                                                        }
                                                                      });

                                                                      await accounts
                                                                          .doc(
                                                                              documentId)
                                                                          .delete();
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
                                              ),
                                            ),
                                          ));
                                    }).toList(),
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
                    ),
                  ))),
        ],
      ),
    );
  }
}

class BalanceText extends StatefulWidget {
  final String documentID;

  BalanceText(this.documentID);

  @override
  _BalanceTextState createState() => _BalanceTextState();
}

class _BalanceTextState extends State<BalanceText> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: getAccountBalance(widget.documentID),
      builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // While the future is not yet complete, show a progress indicator
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          // If the future encounters an error, show an error message
          return Text('Error: ${snapshot.error}');
        } else {
          // If the future completes successfully, display the account balance
          return Text('${snapshot.data?.toStringAsFixed(2)}');
        }
      },
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
        .where('isActive', isEqualTo: false)
        .where('isDone', isEqualTo: true);

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
        balance -= transactionData['total'];
      } else if (transactionData!['transactionType'] == 'Collection' &&
          accountType == 'Internal') {
        if (transactionData['currencies'][0] !=
            transactionData['currencies'][1]) {
          balance += transactionData['convertedTotal'];
        } else {
          balance += transactionData['total'];
        }
      } else if (transactionData!['transactionType'] == 'Payment' &&
          accountType == 'External') {
        balance += transactionData['total'];
      } else if (transactionData!['transactionType'] == 'Payment' &&
          accountType == 'Internal') {
        if (transactionData['currencies'][0] !=
            transactionData['currencies'][1]) {
          balance -= transactionData['convertedTotal'];
        } else {
          balance -= transactionData['total'];
        }
      } else if (transactionData!['transactionType'] == 'Buy' &&
          accountType == 'External') {
        balance += transactionData['total'];
      } else if (transactionData!['transactionType'] == 'Buy' &&
          accountType == 'Internal') {
        if (transactionData['currencies'][0] !=
            transactionData['currencies'][1]) {
          balance -= transactionData['convertedTotal'];
        } else {
          balance -= transactionData['total'];
        }
      } else if (transactionData!['transactionType'] == 'Sell' &&
          accountType == 'External') {
        balance -= transactionData['total'];
      } else if (transactionData!['transactionType'] == 'Sell' &&
          accountType == 'Internal') {
        if (transactionData['currencies'][0] !=
            transactionData['currencies'][1]) {
          balance += transactionData['convertedTotal'];
        } else {
          balance += transactionData['total'];
        }
      } else if (transactionData!['transactionType'] == 'Increase') {
        balance += transactionData['total'];
      } else if (transactionData!['transactionType'] == 'Decrease') {
        balance -= transactionData['total'];
      } else if (transactionData!['transactionType'] == 'Income') {
        balance += transactionData['total'];
      } else if (transactionData!['transactionType'] == 'Outcome') {
        balance -= transactionData['total'];
      }
    });

    return balance;
  }
}
