class UserModel {
  String userUID;
  String email;
  String name;
  String surname;
  String phone;
  DateTime createDate;
  DateTime updateDate;
  bool isActive;

  String get getUserUID => this.userUID;

  set setUserUID(String userUID) => this.userUID = userUID;

  String get getEmail => this.email;

  set setEmail(String email) => this.email = email;

  String get getName => this.name;

  set setName(name) => this.name = name;

  String get getSurname => this.surname;

  set setSurname(surname) => this.surname = surname;

  String get getPhone => this.phone;

  set setPhone(phone) => this.phone = phone;

  DateTime get getCreateDate => this.createDate;

  set setCreateDate(createDate) => this.createDate = createDate;

  DateTime get getUpdateDate => this.updateDate;

  set setUpdateDate(updateDate) => this.updateDate = updateDate;

  bool get getIsActive => this.isActive;

  set setIsActive(isActive) => this.isActive = isActive;

  UserModel(
      {required this.userUID,
      required this.email,
      required this.name,
      required this.surname,
      required this.phone,
      required this.createDate,
      required this.updateDate,
      required this.isActive});
}
