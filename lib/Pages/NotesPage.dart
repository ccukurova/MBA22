import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:MBA22/Models/AccountModel.dart';
import 'package:MBA22/Pages/StockTransactionPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Helpers/SharedPreferencesManager.dart';
import 'package:MBA22/Models/LedgerModel.dart';
import '../Models/NoteModel.dart';
import '../Models/StockModel.dart';
import 'MainPage.dart';
import 'package:intl/intl.dart';

import 'Widgets/TargetDateBar.dart';

class NotePage extends StatefulWidget {
  @override
  NotePageState createState() => NotePageState();
}

class NotePageState extends State<NotePage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? currentLedgerID;

  final SharedPreferencesManager prefs = SharedPreferencesManager();

  @override
  void initState() {
    super.initState();

    prefs.getString("ledgerID").then((value) {
      setState(() {
        currentLedgerID = value;
      });
    });
  }

  void showNoteAdderDialog(BuildContext context,
      {DocumentSnapshot<Object?>? document}) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: NoteAdder(document: document),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference notes = firestore.collection('notes');
    if (currentLedgerID == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    Query userNotes = notes
        .where('ledgerID', isEqualTo: currentLedgerID)
        .where('isActive', isEqualTo: true)
        .orderBy('updateDate', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text('Notes'),
      ),
      body: Stack(
        children: [
          Center(
              child: Padding(
                  padding:
                      EdgeInsets.only(left: 10, top: 0, right: 10, bottom: 0),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: 1000,
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            StreamBuilder<QuerySnapshot>(
                              stream: userNotes.snapshots(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<QuerySnapshot> snapshot) {
                                if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                }

                                if (snapshot.hasData && snapshot.data != null) {
                                  return ListView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: snapshot.data!.docs.length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      DocumentSnapshot document =
                                          snapshot.data!.docs[index];
                                      Map<String, dynamic> data = document
                                          .data() as Map<String, dynamic>;
                                      bool showIcons = false;
                                      if (data['noteType'] == 'Note')
                                        return InkWell(
                                            onTap: () {},
                                            child: Card(
                                                child: ListTile(
                                                    title: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(data['noteType']),
                                                        Text(data['heading']),
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            IconButton(
                                                              icon: Icon(Icons
                                                                  .more_vert),
                                                              onPressed: () {
                                                                setState(() {
                                                                  showModalBottomSheet(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (BuildContext
                                                                            context) {
                                                                      return Container(
                                                                        child:
                                                                            Column(
                                                                          mainAxisSize:
                                                                              MainAxisSize.min,
                                                                          children: <
                                                                              Widget>[
                                                                            ListTile(
                                                                              leading: Icon(Icons.edit),
                                                                              title: Text('Update'),
                                                                              onTap: () {
                                                                                // do something
                                                                                Navigator.pop(context);
                                                                                showNoteAdderDialog(context, document: document);
                                                                              },
                                                                            ),
                                                                            ListTile(
                                                                              leading: Icon(Icons.delete),
                                                                              title: Text('Delete'),
                                                                              onTap: () async {
                                                                                // do something
                                                                                String documentId = document.id;
                                                                                await notes.doc(documentId).update({
                                                                                  'isActive': false
                                                                                });
                                                                                await notes.doc(documentId).update({
                                                                                  'updateDate': DateTime.now()
                                                                                });
                                                                                Navigator.pop(context);
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
                                                      ],
                                                    ),
                                                    subtitle: Column(children: [
                                                      Text(data['noteDetail']),
                                                      SizedBox(height: 10),
                                                      if (data['createDate'] ==
                                                          data['updateDate'])
                                                        Text(
                                                            'Created at ${DateFormat('dd-MM-yyyy – kk:mm').format(data['createDate'].toDate().toLocal())}'),
                                                      if (data['createDate'] !=
                                                          data['updateDate'])
                                                        Text(
                                                            'Updated at ${DateFormat('dd-MM-yyyy – kk:mm').format(data['targetDate'].toDate().toLocal())}'),
                                                      SizedBox(height: 10),
                                                    ]))));
                                      if (data['noteType'] == 'To do')
                                        return InkWell(
                                          onTap: () {},
                                          child: Card(
                                              child: ListTile(
                                                  title: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(data['noteType']),
                                                        Text(data['heading']),
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            IconButton(
                                                              icon: Icon(Icons
                                                                  .more_vert),
                                                              onPressed: () {
                                                                setState(() {
                                                                  showModalBottomSheet(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (BuildContext
                                                                            context) {
                                                                      return Container(
                                                                        child:
                                                                            Column(
                                                                          mainAxisSize:
                                                                              MainAxisSize.min,
                                                                          children: <
                                                                              Widget>[
                                                                            ListTile(
                                                                              leading: Icon(Icons.edit),
                                                                              title: Text('Update'),
                                                                              onTap: () {
                                                                                // do something
                                                                                Navigator.pop(context);
                                                                                showNoteAdderDialog(context, document: document);
                                                                              },
                                                                            ),
                                                                            ListTile(
                                                                              leading: Icon(Icons.delete),
                                                                              title: Text('Delete'),
                                                                              onTap: () async {
                                                                                // do something
                                                                                String documentId = document.id;
                                                                                await notes.doc(documentId).update({
                                                                                  'isActive': false
                                                                                });
                                                                                await notes.doc(documentId).update({
                                                                                  'updateDate': DateTime.now()
                                                                                });
                                                                                Navigator.pop(context);
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
                                                      ]),
                                                  subtitle: Column(children: [
                                                    Text(data['noteDetail']),
                                                    SizedBox(height: 10),
                                                    if (data['createDate'] ==
                                                        data['updateDate'])
                                                      Text(
                                                          'Created at ${DateFormat('dd-MM-yyyy – kk:mm').format(data['createDate'].toDate().toLocal())}'),
                                                    if (data['createDate'] !=
                                                        data['updateDate'])
                                                      Text(
                                                          'Updated at ${DateFormat('dd-MM-yyyy – kk:mm').format(data['targetDate'].toDate().toLocal())}'),
                                                    SizedBox(height: 10),
                                                    TargetDateBar(
                                                        targetDate:
                                                            data['targetDate']
                                                                .toDate(),
                                                        period: data['period'],
                                                        duration:
                                                            data['duration'],
                                                        isDone: data['isDone']),
                                                    SizedBox(height: 10)
                                                  ]))),
                                        );
                                    },
                                  );
                                } else {
                                  return Text('No data available');
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ))),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: FloatingActionButton(
                onPressed: () {
                  showNoteAdderDialog(context);
                },
                child: Icon(Icons.add),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NoteAdder extends StatefulWidget {
  final DocumentSnapshot<Object?>? document;
  const NoteAdder({Key? key, this.document}) : super(key: key);
  @override
  NoteAdderState createState() => NoteAdderState();
}

class NoteAdderState extends State<NoteAdder> {
  CollectionReference stocks = FirebaseFirestore.instance.collection('notes');
  final _formKey = GlobalKey<FormState>();
  String heading = '';
  String noteDetail = '';
  String noteType = '';
  final SharedPreferencesManager prefs = SharedPreferencesManager();
  DateTime _selectedDate = DateTime.now(); // Default selected date
  TimeOfDay _selectedTime = TimeOfDay.fromDateTime(DateTime.now());
  DateTime targetDate = DateTime.now();
  String selectedNoteType = 'Note';
  TextEditingController duration = TextEditingController();

  String selectedDurationText = "∞";
  int selectedDuration = -1;

  String dropDownValueNoteType = 'Note';

  List<String> periodList = <String>[
    'For once',
    'Every week',
    'Every month',
    'Every year'
  ];
  String period = 'For once';
  String dropDownValuePeriod = 'For once';

  TextEditingController headingTextController = new TextEditingController();
  TextEditingController detailsTextController = new TextEditingController();

  @override
  void initState() {
    super.initState();
    prefs.getString("accountType").then((value) {
      setState(() {
        if (widget.document != null) {
          selectedNoteType = widget.document!['noteType'];
          setFieldValuesToUpdate();
        }
      });
    });
  }

  void _onDateSelected(DateTime selected) {
    setState(() {
      _selectedDate = selected;
    });
  }

  // On time selected function
  void _onTimeSelected(TimeOfDay selected) {
    setState(() {
      _selectedTime = selected;
    });
  }

  @override
  Widget build(BuildContext context) {
    const List<String> noteTypeList = <String>['Note', 'To do'];
    // Date formatter for displaying the selected date
    final dateFormatter = DateFormat('dd/MM/yyyy');
    // Time formatter for displaying the selected time
    final timeFormatter = DateFormat('HH:mm');
    duration.text = '∞';
    return Stack(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Add Note',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop();
            },
          )
        ],
      ),
      Padding(
        padding: EdgeInsets.only(left: 10, top: 60, right: 10, bottom: 10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              TextButton(
                onPressed: () {},
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      // Change the text style when clicked
                      selectedNoteType = 'Note';
                    });
                  },
                  child: Text(
                    'Note',
                    style: TextStyle(
                      decoration: selectedNoteType == 'Note'
                          ? TextDecoration.underline
                          : TextDecoration.none, // Add underline
                      color: selectedNoteType == 'Note'
                          ? Color.fromARGB(255, 33, 236, 243)
                          : Colors.blue, // Change color when selected
                      fontSize: selectedNoteType == 'Note' ? 22.0 : 18.0,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      // Change the text style when clicked
                      selectedNoteType = 'To do';
                    });
                  },
                  child: Text(
                    'To do',
                    style: TextStyle(
                      decoration: selectedNoteType == 'To do'
                          ? TextDecoration.underline
                          : TextDecoration.none, // Add underline
                      color: selectedNoteType == 'To do'
                          ? Color.fromARGB(255, 33, 236, 243)
                          : Colors.blue, // Change color when selected
                      fontSize: selectedNoteType == 'To do' ? 22.0 : 18.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      SizedBox(height: 16.0),
      Container(
        child: Padding(
          padding: EdgeInsets.only(left: 10, top: 120, right: 10, bottom: 10),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
                child: Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    controller: headingTextController,
                    decoration: InputDecoration(
                      labelText: 'Heading',
                      border: OutlineInputBorder(),
                    ),
                    onSaved: (value) {
                      heading = value!;
                    },
                  ),
                  SizedBox(height: 16.0),
                  TextFormField(
                    controller: detailsTextController,
                    maxLines: 3,
                    textAlignVertical: TextAlignVertical.bottom,
                    decoration: InputDecoration(
                      labelText: 'Details',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter note details.';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      noteDetail = value!;
                    },
                  ),
                  SizedBox(height: 20.0),
                  if (selectedNoteType == 'To do')
                    Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month,
                              size: 30.0,
                              color: Colors.blue,
                            ),
                            DropdownButton<String>(
                              style: const TextStyle(fontSize: 14),
                              value: dropDownValuePeriod,
                              icon: const Icon(Icons.arrow_downward),
                              elevation: 16,
                              onChanged: (String? value) {
                                // This is called when the user selects an item.
                                setState(() {
                                  dropDownValuePeriod = value!;
                                  period = value;
                                  print(value + dropDownValuePeriod + period);
                                });
                              },
                              items: periodList.map<DropdownMenuItem<String>>(
                                  (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: TextStyle(color: Colors.black),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(children: [
                          Icon(
                            Icons.access_time,
                            size: 30.0,
                            color: Colors.blue,
                          ),
                          GestureDetector(
                            child: Text(
                                ' ${dateFormatter.format(_selectedDate)}', // Display selected date
                                style: TextStyle(fontSize: 16)),
                            onTap: () async {
                              final DateTime? selected = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime.now(),
                                lastDate:
                                    DateTime.now().add(Duration(days: 365)),
                              );
                              if (selected != null) {
                                _onDateSelected(selected);
                              }
                            },
                          ),
                          if (period == 'Past')
                            Builder(
                              builder: (BuildContext context) {
                                return GestureDetector(
                                  child: Text(
                                    ' ${dateFormatter.format(_selectedDate)}',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  onTap: () async {
                                    final DateTime? selected =
                                        await showDatePicker(
                                      context: context,
                                      initialDate: _selectedDate,
                                      firstDate: DateTime(1900),
                                      lastDate: DateTime.now(),
                                    );
                                    if (selected != null) {
                                      _onDateSelected(selected);
                                    }
                                  },
                                );
                              },
                            ),
                          if (period != 'Past')
                            GestureDetector(
                              child: Text(
                                '  ${timeFormatter.format(DateTime(0, 0, 0, _selectedTime.hour, _selectedTime.minute))}',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black),
                              ),
                              onTap: () async {
                                final TimeOfDay? selected =
                                    await showTimePicker(
                                  context: context,
                                  initialTime: _selectedTime,
                                );
                                if (selected != null) {
                                  _onTimeSelected(selected);
                                }
                              },
                            )
                        ]),
                        SizedBox(height: 10),
                        if (period != 'For once')
                          Row(
                            children: [
                              Icon(
                                Icons.refresh,
                                size: 30.0,
                                color: Colors.blue,
                              ),
                              Text('Repeat'),
                              TextButton(
                                onPressed: () => {
                                  if (selectedDuration == 2)
                                    {selectedDuration = -1, duration.text = '∞'}
                                  else if (selectedDuration <= -1)
                                    {}
                                  else
                                    {
                                      selectedDuration--,
                                      duration.text =
                                          selectedDuration.toString()
                                    }
                                },
                                child: Text('<'),
                              ),
                              Container(
                                width: 20,
                                child: TextFormField(
                                  controller: duration,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              TextButton(
                                  onPressed: () => {
                                        if (selectedDuration <= -1)
                                          {
                                            selectedDuration = 2,
                                            duration.text =
                                                selectedDuration.toString()
                                          }
                                        else
                                          {
                                            selectedDuration++,
                                            duration.text =
                                                selectedDuration.toString()
                                          }
                                      },
                                  child: Text('>')),
                            ],
                          ),
                      ],
                    ),
                  SizedBox(height: 20.0),
                  ElevatedButton(
                    onPressed: () async {
                      DateTime targetDate;
                      if (period != "Now") {
                        targetDate = DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                          _selectedDate.day,
                          _selectedTime.hour,
                          _selectedTime.minute,
                        );
                      } else {
                        targetDate =
                            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
                      }
                      if (_formKey.currentState!.validate() &&
                          selectedDurationText != "0" &&
                          selectedDurationText != "1") {
                        _formKey.currentState!.save();
                        if (selectedNoteType == "To do" &&
                            period == "For once") {
                          selectedDuration = 1;
                        }
                        if (selectedNoteType == "To do" &&
                            period == "For once" &&
                            targetDate.compareTo(DateTime.now()) <= 0) {
                          final snackBar = SnackBar(
                            content: Text(
                                'Future target date cannot be less than current date'),
                            duration: Duration(seconds: 2),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        } else {
                          if (widget.document == null) {
                            createNote("");
                          } else {
                            createNote(
                              widget.document!.id,
                            );
                          }

                          Navigator.pop(context);
                        }
                      }
                    },
                    child: Text('Add'),
                  ),
                ],
              ),
            )),
          ),
        ),
      ),
    ]);
  }

  Future<void> createNote(String noteID) async {
    String? currentLedgerID = await prefs.getString("ledgerID");
    CollectionReference notes = FirebaseFirestore.instance.collection('notes');

    var newNote = NoteModel(
        ledgerID: currentLedgerID!,
        heading: heading,
        noteDetail: noteDetail,
        noteType: selectedNoteType,
        targetDate: targetDate,
        period: period,
        duration: selectedDuration,
        createDate: DateTime.now(),
        updateDate: DateTime.now(),
        isActive: true,
        isDone: selectedNoteType == "Note" ? true : false);

    if (noteID == "") {
      DocumentReference noteDoc = await stocks.add({
        'ledgerID': newNote.ledgerID,
        'heading': newNote.heading,
        'noteDetail': newNote.noteDetail,
        'noteType': newNote.noteType,
        'targetDate': Timestamp.fromDate(newNote.targetDate),
        'period': newNote.period,
        'duration': newNote.duration,
        'createDate': Timestamp.fromDate(newNote.createDate),
        'updateDate': Timestamp.fromDate(newNote.updateDate),
        'isActive': newNote.isActive,
        'isDone': newNote.isDone
      });
    } else {
      await notes.doc(noteID).update({
        'ledgerID': newNote.ledgerID,
        'heading': newNote.heading,
        'noteDetail': newNote.noteDetail,
        'noteType': newNote.noteType,
        'targetDate': Timestamp.fromDate(newNote.targetDate),
        'period': newNote.period,
        'duration': newNote.duration,
        'updateDate': Timestamp.fromDate(newNote.updateDate),
        'isActive': newNote.isActive,
        'isDone': newNote.isDone
      });
    }
  }

  Future<void> setFieldValuesToUpdate() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference accounts = firestore.collection('accounts');

    DocumentSnapshot<Map<String, dynamic>>? document =
        widget.document as DocumentSnapshot<Map<String, dynamic>>;

    heading = document['heading'];
    headingTextController.text = heading;

    noteDetail = document['noteDetail'];
    detailsTextController.text = noteDetail;

    selectedDurationText = document['duration'].toString();

    duration.text = selectedDurationText;

    period = document['period'];
    DateTime targetDate = document['targetDate'].toDate();
    DateTime _selectedDate = DateTime.now(); // Default selected date
    TimeOfDay _selectedTime = TimeOfDay.fromDateTime(DateTime.now());
    dropDownValuePeriod = period;
    if (document['duration'] > 1) {
      selectedDurationText = document['duration'].toString();
      duration.text = selectedDurationText;
      selectedDuration = document['duration'];
    } else if (document['duration'] <= -1) {
      selectedDurationText = '∞';
      duration.text = selectedDurationText;
      selectedDuration = document['duration'];
    }
  }
}
