class LedgerModel {
  List<String> users;
  String ledgerName;
  String ledgerDetail;
  String ledgerType;
  DateTime createDate;
  DateTime updateDate;
  bool isActive;

  get getUsers => this.users;

  set setUsers(users) => this.users = users;

  get getLedgerName => this.ledgerName;

  set setLedgerName(ledgerName) => this.ledgerName = ledgerName;

  get getLedgerDetail => this.ledgerDetail;

  set setLedgerDetail(ledgerDetail) => this.ledgerDetail = ledgerDetail;

  get getLedgerType => this.ledgerType;

  set setLedgerType(ledgerType) => this.ledgerType = ledgerType;

  get getCreateDate => this.createDate;

  set setCreateDate(createDate) => this.createDate = createDate;

  get getUpdateDate => this.updateDate;

  set setUpdateDate(updateDate) => this.updateDate = updateDate;

  get getIsActive => this.isActive;

  set setIsActive(isActive) => this.isActive = isActive;

  LedgerModel(
      {required this.users,
      required this.ledgerName,
      required this.ledgerDetail,
      required this.ledgerType,
      required this.createDate,
      required this.updateDate,
      required this.isActive});
}
