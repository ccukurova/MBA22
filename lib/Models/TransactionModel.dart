class TransactionModel {
  List<String> accountID;
  String stockID;
  String transactionType;
  double amount;
  double totalPrice;
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
      required this.stockID,
      required this.transactionType,
      required this.amount,
      required this.totalPrice,
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
