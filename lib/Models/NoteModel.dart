class NoteModel {
  String ledgerID;
  String heading;
  String noteDetail;
  String noteType;
  DateTime targetDate;
  String period;
  int duration;
  DateTime createDate;
  DateTime updateDate;
  bool isActive;
  bool isDone;

  String get getLedgerID => this.ledgerID;

  set setLedgerID(String ledgerID) => this.ledgerID = ledgerID;

  String get getHeading => this.heading;

  set setHeading(String heading) => this.heading = heading;

  String get getNoteDetail => this.noteDetail;

  set setNoteDetail(noteDetail) => this.noteDetail = noteDetail;

  DateTime get getTargetDate => this.targetDate;

  String get getNoteType => this.noteType;

  set setNoteType(String noteType) => this.noteType = noteType;

  set setTargetDate(targetDate) => this.targetDate = targetDate;

  String get getPeriod => this.period;

  set setPeriod(period) => this.period = period;

  int get getDuration => this.duration;

  set setDuration(duration) => this.duration = duration;

  DateTime get getCreateDate => this.createDate;

  set setCreateDate(createDate) => this.createDate = createDate;

  DateTime get getUpdateDate => this.updateDate;

  set setUpdateDate(updateDate) => this.updateDate = updateDate;

  bool get getIsActive => this.isActive;

  set setIsActive(isActive) => this.isActive = isActive;

  bool get getIsDone => this.isDone;

  set setIsDone(bool isDone) => this.isDone = isDone;

  NoteModel(
      {required this.ledgerID,
      required this.heading,
      required this.noteDetail,
      required this.noteType,
      required this.targetDate,
      required this.period,
      required this.duration,
      required this.createDate,
      required this.updateDate,
      required this.isActive,
      required this.isDone});
}
