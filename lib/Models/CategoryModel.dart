class CategoryModel {
  String ledgerID;
  String categoryName;
  String categoryType;
  DateTime createDate;
  DateTime updateDate;
  bool isActive;

  String get getUserID => this.ledgerID;

  set setUserID(String userID) => this.ledgerID = userID;

  String get getCategoryName => this.categoryName;

  set setCategoryName(String categoryName) => this.categoryName = categoryName;

  String get getCategoryType => this.categoryType;

  set setCategoryType(String categoryType) => this.categoryType = categoryType;

  DateTime get getCreateDate => this.createDate;

  set setCreateDate(DateTime createDate) => this.createDate = createDate;

  DateTime get getUpdateDate => this.updateDate;

  set setUpdateDate(DateTime updateDate) => this.updateDate = updateDate;

  bool get getIsActive => this.isActive;

  set setIsActive(bool isActive) => this.isActive = isActive;

  CategoryModel(
      {required this.ledgerID,
      required this.categoryName,
      required this.categoryType,
      required this.createDate,
      required this.updateDate,
      required this.isActive});
}
