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
}
