class StockModel {
  String ledgerID;
  String stockName;
  String unit;
  DateTime createDate;
  DateTime updateDate;
  bool isActive;

  String get getLedgerID => this.ledgerID;

  set setLedgerID(String ledgerID) => this.ledgerID = ledgerID;

  String get getStockName => this.stockName;

  set setStockName(String stockName) => this.stockName = stockName;

  String get getUnit => this.unit;

  set setUnit(String unit) => this.unit = unit;

  DateTime get getCreateDate => this.createDate;

  set setCreateDate(DateTime createDate) => this.createDate = createDate;

  DateTime get getUpdateDate => this.updateDate;

  set setUpdateDate(DateTime updateDate) => this.updateDate = updateDate;

  bool get getIsActive => this.isActive;

  set setIsActive(bool isActive) => this.isActive = isActive;

  StockModel(
      {required this.ledgerID,
      required this.stockName,
      required this.unit,
      required this.createDate,
      required this.updateDate,
      required this.isActive});
}
