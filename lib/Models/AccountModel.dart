class AccountModel {
  String ledgerID;
  String accountName;
  String accountType;
  String unit;
  DateTime createDate;
  DateTime updateDate;
  bool isActive;

  String get getLedgerID => this.ledgerID;

  set setLedgerID(String ledgerID) => this.ledgerID = ledgerID;

  String get getAccountName => this.accountName;

  set setAccountName(String accountName) => this.accountName = accountName;

  String get getAccountType => this.accountType;

  set setAccountType(String accountType) => this.accountType = accountType;

  String get getUnit => this.unit;

  set setUnit(String unit) => this.unit = unit;

  DateTime get getCreateDate => this.createDate;

  set setCreateDate(DateTime createDate) => this.createDate = createDate;

  DateTime get getUpdateDate => this.updateDate;

  set setUpdateDate(DateTime updateDate) => this.updateDate = updateDate;

  bool get getIsActive => this.isActive;

  set setIsActive(bool isActive) => this.isActive = isActive;

  AccountModel(
      {required this.ledgerID,
      required this.accountName,
      required this.accountType,
      required this.unit,
      required this.createDate,
      required this.updateDate,
      required this.isActive});
}
