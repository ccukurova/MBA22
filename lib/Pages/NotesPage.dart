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

  void showNoteAdderDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: NoteAdder(),
        );
      },
    );
  }

  void showNoteUpdaterDialog(
      BuildContext context, DocumentSnapshot<Object?> document) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            //content: NoteUpdater(document),
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
          SingleChildScrollView(
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
                          itemBuilder: (BuildContext context, int index) {
                            DocumentSnapshot document =
                                snapshot.data!.docs[index];
                            Map<String, dynamic> data =
                                document.data() as Map<String, dynamic>;
                            bool showIcons = false;
                            if (data['noteType'] == 'Note')
                              return InkWell(
                                  onTap: () {},
                                  child: ListTile(
                                      title: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(data['noteType']),
                                          Text(data['heading']),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.more_vert),
                                                onPressed: () {
                                                  setState(() {
                                                    showModalBottomSheet(
                                                      context: context,
                                                      builder: (BuildContext
                                                          context) {
                                                        return Container(
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: <Widget>[
                                                              ListTile(
                                                                leading: Icon(
                                                                    Icons.edit),
                                                                title: Text(
                                                                    'Update'),
                                                                onTap: () {
                                                                  // do something
                                                                  Navigator.pop(
                                                                      context);
                                                                  showNoteUpdaterDialog(
                                                                      context,
                                                                      document);
                                                                },
                                                              ),
                                                              ListTile(
                                                                leading: Icon(
                                                                    Icons
                                                                        .delete),
                                                                title: Text(
                                                                    'Delete'),
                                                                onTap:
                                                                    () async {
                                                                  // do something
                                                                  String
                                                                      documentId =
                                                                      document
                                                                          .id;
                                                                  await notes
                                                                      .doc(
                                                                          documentId)
                                                                      .update({
                                                                    'isActive':
                                                                        false
                                                                  });
                                                                  await notes
                                                                      .doc(
                                                                          documentId)
                                                                      .update({
                                                                    'updateDate':
                                                                        DateTime
                                                                            .now()
                                                                  });
                                                                  Navigator.pop(
                                                                      context);
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
                                        Text(DateFormat('dd-MM-yyyy – kk:mm')
                                            .format(data['createDate']
                                                .toDate()
                                                .toLocal())),
                                        SizedBox(height: 25)
                                      ])));
                            if (data['noteType'] == 'To do')
                              return InkWell(
                                onTap: () {},
                                child: ListTile(
                                    title: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(data['noteType']),
                                          Text(data['heading']),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.more_vert),
                                                onPressed: () {
                                                  setState(() {
                                                    showModalBottomSheet(
                                                      context: context,
                                                      builder: (BuildContext
                                                          context) {
                                                        return Container(
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: <Widget>[
                                                              ListTile(
                                                                leading: Icon(
                                                                    Icons.edit),
                                                                title: Text(
                                                                    'Update'),
                                                                onTap: () {
                                                                  // do something
                                                                  Navigator.pop(
                                                                      context);
                                                                  showNoteUpdaterDialog(
                                                                      context,
                                                                      document);
                                                                },
                                                              ),
                                                              ListTile(
                                                                leading: Icon(
                                                                    Icons
                                                                        .delete),
                                                                title: Text(
                                                                    'Delete'),
                                                                onTap:
                                                                    () async {
                                                                  // do something
                                                                  String
                                                                      documentId =
                                                                      document
                                                                          .id;
                                                                  await notes
                                                                      .doc(
                                                                          documentId)
                                                                      .update({
                                                                    'isActive':
                                                                        false
                                                                  });
                                                                  await notes
                                                                      .doc(
                                                                          documentId)
                                                                      .update({
                                                                    'updateDate':
                                                                        DateTime
                                                                            .now()
                                                                  });
                                                                  Navigator.pop(
                                                                      context);
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
                                      Row(children: [
                                        if (data['targetDate'] == DateTime(0))
                                          Text(DateFormat('dd-MM-yyyy – kk:mm')
                                              .format(data['createDate']
                                                  .toDate()
                                                  .toLocal())),
                                        if (data['targetDate'] != DateTime(0))
                                          Text(DateFormat('dd-MM-yyyy – kk:mm')
                                              .format(data['targetDate']
                                                  .toDate()
                                                  .toLocal())),
                                      ]),
                                      SizedBox(height: 25)
                                    ])),
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
  NoteAdder();
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
  int selectedDuration = 1;

  String dropDownValueNoteType = 'Note';

  List<String> periodList = <String>[
    'For once',
    'Every week',
    'Every month',
    'Every year'
  ];
  String selectedPeriod = 'For once';
  String dropDownValuePeriod = 'For once';
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
    duration.text = selectedDurationText;

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
                  SizedBox(height: 16.0),
                  if (selectedNoteType == 'To do')
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 20),
                        Row(
                          children: [
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
                                  firstDate: DateTime(1900),
                                  lastDate:
                                      DateTime.now().add(Duration(days: 365)),
                                );
                                if (selected != null) {
                                  _onDateSelected(selected);
                                }
                              },
                            ),
                            GestureDetector(
                              child: Text(
                                '  ${timeFormatter.format(DateTime(0, 0, 0, _selectedTime.hour, _selectedTime.minute))}',
                                style: TextStyle(fontSize: 16),
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
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        DropdownButton<String>(
                          value: dropDownValuePeriod,
                          icon: const Icon(Icons.arrow_downward),
                          elevation: 16,
                          style: const TextStyle(color: Colors.deepPurple),
                          underline: Container(
                            height: 2,
                            color: Colors.deepPurpleAccent,
                          ),
                          onChanged: (String? value) {
                            // This is called when the user selects an item.
                            setState(() {
                              dropDownValuePeriod = value!;
                              selectedPeriod = value;
                            });
                          },
                          items: periodList
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 25.0),
                        if (dropDownValuePeriod != 'For once')
                          Container(
                            child: Row(
                              children: [
                                Text('Duration'),
                                TextButton(
                                  onPressed: () => {
                                    if (selectedDuration > 1)
                                      {
                                        selectedDuration--,
                                        duration.text =
                                            selectedDuration.toString()
                                      }
                                    else if (selectedDuration == 1)
                                      {duration.text = '∞'}
                                  },
                                  child: Text('<'),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    controller: duration,
                                  ),
                                ),
                                TextButton(
                                    onPressed: () => {
                                          if (selectedDuration >= 1)
                                            {
                                              selectedDuration++,
                                              duration.text =
                                                  selectedDuration.toString()
                                            }
                                        },
                                    child: Text('>')),
                              ],
                            ),
                          ),
                      ],
                    ),
                  SizedBox(height: 25.0),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        targetDate = DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                          _selectedDate.day,
                          _selectedTime.hour,
                          _selectedTime.minute,
                        );
                        createNote();
                        Navigator.pop(context);
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

  Future<void> createNote() async {
    String? currentLedgerID = await prefs.getString("ledgerID");

    var newNote = NoteModel(
        ledgerID: currentLedgerID!,
        heading: heading,
        noteDetail: noteDetail,
        noteType: selectedNoteType,
        targetDate: targetDate,
        period: selectedPeriod,
        duration: 0,
        createDate: DateTime.now(),
        updateDate: DateTime.now(),
        isActive: true);

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
      'isActive': newNote.isActive
    });
  }
}

// class StockUpdater extends StatefulWidget {
//   final DocumentSnapshot<Object?> document;

//   StockUpdater(this.document);

//   @override
//   StockUpdaterState createState() => StockUpdaterState();
// }

// class StockUpdaterState extends State<StockUpdater> {
//   CollectionReference stocks = FirebaseFirestore.instance.collection('stocks');
//   final _formKey = GlobalKey<FormState>();
//   String stockName = '';
//   String unit = '';
//   final SharedPreferencesManager prefs = SharedPreferencesManager();

//   FirebaseFirestore firestore = FirebaseFirestore.instance;

//   String initialUnit = '';
//   List<String> unitList = <String>['Piece', 'kilogram'];
//   String dropDownValueUnit = 'Piece';

//   @override
//   Widget build(BuildContext context) {
//     return Stack(children: [
//       Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             'Update Stock',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           IconButton(
//             icon: Icon(Icons.close),
//             onPressed: () {
//               Navigator.of(context).pop();
//             },
//           )
//         ],
//       ),
//       Container(
//         child: Padding(
//           padding: EdgeInsets.only(left: 10, top: 60, right: 10, bottom: 10),
//           child: Form(
//             key: _formKey,
//             child: SingleChildScrollView(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   TextFormField(
//                     initialValue: widget.document['stockName'],
//                     decoration: InputDecoration(
//                       labelText: 'Stock Name',
//                       border: OutlineInputBorder(),
//                     ),
//                     validator: (value) {
//                       if (value!.isEmpty) {
//                         return 'Please enter a stock name.';
//                       }
//                       return null;
//                     },
//                     onSaved: (value) {
//                       stockName = value!;
//                     },
//                   ),
//                   SizedBox(height: 16.0),
//                   ElevatedButton(
//                     onPressed: () {
//                       if (_formKey.currentState!.validate()) {
//                         _formKey.currentState!.save();
//                         updateStock(stockName, widget.document);
//                         Navigator.pop(context);
//                       }
//                     },
//                     child: Text('Update'),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     ]);
//   }

//   Future<void> updateStock(
//       String _stockName, DocumentSnapshot<Object?> document) async {
//     String? currentLedgerID = await prefs.getString("ledgerID");

//     DocumentReference docRef = firestore.collection('stocks').doc(document.id);

//     docRef.get().then((doc) {
//       if (doc.exists) {
//         docRef
//             .update({'accountName': _stockName, 'updateDate': DateTime.now()});
//       } else {
//         print('Document does not exist!');
//       }
//     }).catchError((error) {
//       print('Error getting document: $error');
//     });
//   }
// }
