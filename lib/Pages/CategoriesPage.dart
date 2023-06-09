import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Helpers/SharedPreferencesManager.dart';
import 'package:MBA22/Models/CategoryModel.dart';
import 'MainPage.dart';

class CategoriesPage extends StatefulWidget {
  final Function(String)? onUpdate;

  CategoriesPage({this.onUpdate});

  @override
  CategoriesPageState createState() => CategoriesPageState();
}

class CategoriesPageState extends State<CategoriesPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  CollectionReference ledgers =
      FirebaseFirestore.instance.collection('categories');
  String? currentLedgerID;
  List<String> myStrings = ["Apple", "Banana", "Orange", "Grapes", "Mango"];
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

  Future<void> setChoosenCategory(String choosenCategory) async {
    await prefs.setString("choosenCategory", choosenCategory);
    print('Choosen category ${await prefs.getString('choosenCategory')}');
    Navigator.of(context).pop();
  }

  void showCategoryAdderDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: CategoryAdder(),
        );
      },
    );
  }

  void showCategoryUpdaterDialog(
      BuildContext context, DocumentSnapshot<Object?> document) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: CategoryUpdater(document),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference categories = firestore.collection('categories');

    if (currentLedgerID == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    Query userCategories = categories
        .where('ledgerID', isEqualTo: currentLedgerID)
        .where('isActive', isEqualTo: true)
        .orderBy('updateDate', descending: true);

    return Scaffold(
        appBar: AppBar(
          title: Text('Categories'),
        ),
        body: Stack(children: [
          Center(
              child: Padding(
                  padding:
                      EdgeInsets.only(left: 10, top: 0, right: 10, bottom: 0),
                  child: Container(
                      constraints: BoxConstraints(
                        maxWidth: 600,
                      ),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Image.asset(
                                'assets/images/categories.png', // Replace with the converted PNG file path
                                width: 200,
                                height: 200,
                              ),
                              SizedBox(height: 20),
                              Text('Select a category or create a new one',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 20),
                              StreamBuilder<QuerySnapshot>(
                                stream: userCategories.snapshots(),
                                builder: (BuildContext context,
                                    AsyncSnapshot<QuerySnapshot> snapshot) {
                                  if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}');
                                  }

                                  if (snapshot.hasData &&
                                      snapshot.data != null) {
                                    List<DocumentSnapshot> documents =
                                        snapshot.data!.docs;
                                    List<String> additionalCategories = [
                                      'Dues',
                                      'Rent',
                                      'Salary',
                                      'Health',
                                      'Bills',
                                      'Transportation',
                                      'Tax',
                                      'Food',
                                      'Entertainment'
                                    ];

                                    List<Map<String, dynamic>> data = documents
                                        .map((DocumentSnapshot document) {
                                      return document.data()
                                          as Map<String, dynamic>;
                                    }).toList();

                                    // Add additional categories to the data list
                                    additionalCategories.forEach((category) {
                                      data.add({'categoryName': category});
                                    });

                                    return ListView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: data.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        Map<String, dynamic> category =
                                            data[index];

                                        // Determine if IconButton should be displayed
                                        bool canEdit = documents.isNotEmpty &&
                                            index < documents.length;

                                        return InkWell(
                                          onTap: () {
                                            var previousRoute =
                                                ModalRoute.of(context)!
                                                    .settings;

                                            setChoosenCategory(
                                                category['categoryName']);
                                            widget.onUpdate!(
                                                category['categoryName']);
                                          },
                                          child: Card(
                                              child: ListTile(
                                            title:
                                                Text(category['categoryName']),
                                            trailing: canEdit
                                                ? Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        icon: Icon(Icons.edit),
                                                        onPressed: () {
                                                          showCategoryUpdaterDialog(
                                                              context,
                                                              documents[index]);
                                                        },
                                                      ),
                                                      IconButton(
                                                        icon:
                                                            Icon(Icons.delete),
                                                        onPressed: () async {
                                                          showDialog(
                                                            context: context,
                                                            builder:
                                                                (BuildContext
                                                                    context) {
                                                              return AlertDialog(
                                                                title: Text(
                                                                    'Delete'),
                                                                content: Text(
                                                                    'Are you sure you want to delete?'),
                                                                actions: <
                                                                    Widget>[
                                                                  TextButton(
                                                                    child: Text(
                                                                        'Cancel'),
                                                                    onPressed:
                                                                        () {
                                                                      Navigator.of(
                                                                              context)
                                                                          .pop();
                                                                    },
                                                                  ),
                                                                  TextButton(
                                                                    child: Text(
                                                                        'Delete'),
                                                                    onPressed:
                                                                        () async {
                                                                      String
                                                                          documentId =
                                                                          documents[index]
                                                                              .id;
                                                                      await categories
                                                                          .doc(
                                                                              documentId)
                                                                          .update({
                                                                        'isActive':
                                                                            false
                                                                      });
                                                                      await categories
                                                                          .doc(
                                                                              documentId)
                                                                          .update({
                                                                        'updateDate':
                                                                            DateTime.now()
                                                                      });
                                                                      Navigator.pop(
                                                                          context);
                                                                    },
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  )
                                                : null,
                                          )),
                                        );
                                      },
                                    );
                                  } else {
                                    return Center(
                                        child: CircularProgressIndicator());
                                  }
                                },
                              )
                            ],
                          ),
                        ),
                      )))),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: FloatingActionButton(
                onPressed: () {
                  showCategoryAdderDialog(context);
                },
                child: Icon(Icons.add),
              ),
            ),
          ),
        ]));
  }
}

class CategoryAdder extends StatefulWidget {
  CategoryAdder();
  @override
  CategoryAdderState createState() => CategoryAdderState();
}

class CategoryAdderState extends State<CategoryAdder> {
  CollectionReference categories =
      FirebaseFirestore.instance.collection('categories');
  final _formKey = GlobalKey<FormState>();
  String categoryName = '';
  final SharedPreferencesManager prefs = SharedPreferencesManager();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Add Category',
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
          padding: EdgeInsets.only(left: 20, top: 80, right: 20, bottom: 40),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Category Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter a category name.';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      categoryName = value!;
                    },
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        createCategory(categoryName);
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text('Add'),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Future<void> createCategory(String _categoryName) async {
    String? currentLedgerID = await prefs.getString("ledgerID");

    var newCategory = CategoryModel(
        ledgerID: currentLedgerID!,
        categoryName: _categoryName,
        categoryType: 'generated',
        createDate: DateTime.now(),
        updateDate: DateTime.now(),
        isActive: true);

    DocumentReference categoriesDoc = await categories.add({
      'ledgerID': newCategory.ledgerID,
      'categoryName': newCategory.categoryName,
      'categoryType': newCategory.categoryType,
      'createDate': Timestamp.fromDate(newCategory.createDate),
      'updateDate': Timestamp.fromDate(newCategory.updateDate),
      'isActive': newCategory.isActive
    });
  }
}

class CategoryUpdater extends StatefulWidget {
  final DocumentSnapshot<Object?> document;

  CategoryUpdater(this.document);

  @override
  CategoryUpdaterState createState() => CategoryUpdaterState();
}

class CategoryUpdaterState extends State<CategoryUpdater> {
  CollectionReference categories =
      FirebaseFirestore.instance.collection('categories');
  final _formKey = GlobalKey<FormState>();
  String categoryName = '';
  final SharedPreferencesManager prefs = SharedPreferencesManager();
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Update Category',
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
          padding: EdgeInsets.only(left: 20, top: 80, right: 20, bottom: 40),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    initialValue: widget.document['categoryName'],
                    decoration: InputDecoration(
                      labelText: 'Category Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter a category name.';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      categoryName = value!;
                    },
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        updateCategory(categoryName, widget.document);
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text('Update'),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Future<void> updateCategory(
      String _categoryName, DocumentSnapshot<Object?> document) async {
    DocumentReference docRef =
        firestore.collection('categories').doc(document.id);

    docRef.get().then((doc) {
      if (doc.exists) {
        docRef.update(
            {'categoryName': _categoryName, 'updateDate': DateTime.now()});
      } else {
        print('Document does not exist!');
      }
    }).catchError((error) {
      print('Error getting document: $error');
    });
  }
}
