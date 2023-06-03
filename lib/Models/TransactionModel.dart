import 'dart:js';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../Helpers/SharedPreferencesManager.dart';

class TransactionModel {
  List<String> accountID;
  String ledgerID;
  String stockID;
  String transactionType;
  double amount;
  double total;
  double convertedTotal;
  List<String> currencies;
  double price;
  String transactionDetail;
  String categoryName;
  String period;
  int duration;
  DateTime targetDate;
  bool isDone;
  DateTime createDate;
  DateTime updateDate;
  bool isActive;

  TransactionModel(
      {required this.accountID,
      required this.ledgerID,
      required this.stockID,
      required this.transactionType,
      required this.amount,
      required this.convertedTotal,
      required this.total,
      required this.currencies,
      required this.price,
      required this.transactionDetail,
      required this.categoryName,
      required this.period,
      required this.duration,
      required this.targetDate,
      required this.isDone,
      required this.createDate,
      required this.updateDate,
      required this.isActive});

  Future<void> addTransaction(
      TransactionModel newAccountTransaction, String transactionID) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference transactions = firestore.collection('transactions');
    final SharedPreferencesManager prefs = SharedPreferencesManager();
    String? currentAccountID = await prefs.getString("accountID");
    String? currentLedgerID = await prefs.getString("ledgerID");
    var newAccountTransaction;
    CollectionReference accounts = firestore.collection('accounts');
    String sourceAccountID = "";

    bool isDone;
    if (newAccountTransaction.duration == 0) {
      isDone = true;
    } else {
      isDone = false;
    }
    if (newAccountTransaction.transactionType == 'Collection' ||
        newAccountTransaction.transactionType == 'Payment') {
      final QuerySnapshot sourceAccountQuerySnapshot = await accounts
          .where('accountName',
              isEqualTo: newAccountTransaction.selectedSourceAccount)
          .where('isActive', isEqualTo: true)
          .limit(1) // Use limit(1) if you expect only one result
          .get();

      if (sourceAccountQuerySnapshot.docs.isNotEmpty) {
        final sourceAccountDocumentSnapshot =
            sourceAccountQuerySnapshot.docs[0];
        sourceAccountID = sourceAccountDocumentSnapshot.id;
        print('source account ID: $sourceAccountID');
      } else {
        ScaffoldMessenger.of(context as BuildContext).showSnackBar(
          SnackBar(
            content: Text('No source account found with given name.'),
          ),
        );
      }
    }

    try {
      if (transactionID == "") {
        DocumentReference createdTransactionRef = await transactions.add({
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
      } else {
        await transactions.doc(transactionID).update({
          'accountID': newAccountTransaction.accountID,
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
          'updateDate': Timestamp.fromDate(newAccountTransaction.updateDate),
          'isActive': newAccountTransaction.isActive
        });
      }
    } catch (e) {
      print('Error caught: $e');
    }
  }
}
