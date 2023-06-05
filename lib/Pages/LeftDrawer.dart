import 'package:MBA22/Pages/ArchivePage.dart';
import 'package:MBA22/Pages/LoginPage.dart';
import 'package:MBA22/Pages/NotesPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:MBA22/Pages/CategoriesPage.dart';
import 'package:MBA22/Pages/LedgerPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Helpers/SharedPreferencesManager.dart';
import 'AccountsPage.dart';
import 'StockPage.dart';

class LeftDrawer extends StatefulWidget {
  const LeftDrawer({Key? key}) : super(key: key);

  @override
  _LeftDrawerState createState() => _LeftDrawerState();
}

class _LeftDrawerState extends State<LeftDrawer> {
  String? currentUserID;
  final SharedPreferencesManager prefs = SharedPreferencesManager();
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth mAuth = FirebaseAuth.instance;
  @override
  void initState() {
    super.initState();
    prefs.getString("userID").then((value) {
      setState(() {
        currentUserID = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          FutureBuilder<Widget>(
            future: setDrawerHeader(),
            builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                return snapshot.data!;
              } else {
                return DrawerHeader(
                  child: CircularProgressIndicator(),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                  ),
                );
              }
            },
          ),
          ListTile(
            title: Text('My ledgers'),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => LedgerPage()));
            },
          ),
          ListTile(
            title: Text('Accounts'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => AccountsPage()));
            },
          ),
          ListTile(
            title: Text('Stocks'),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => StockPage()));
            },
          ),
          ListTile(
            title: Text('Notes & To-do'),
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => NotePage()));
            },
          ),
          ListTile(
            title: Text('Archive'),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ArchivePage()));
            },
          ),
          ListTile(
            title: Text('Categories'),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => CategoriesPage()));
            },
          ),
          ListTile(
            title: Text('Options'),
            onTap: () {
              // Do something when the user taps on this ListTile
            },
          ),
          ListTile(
              title: Text('Exit'),
              onTap: () {
                signOutUser();
              }),
        ],
      ),
    );
  }

  Future<Widget> setDrawerHeader() async {
    String name;
    String surname;
    String email;

    if (currentUserID == null) {
      // Handle case where currentUserID is null
      return DrawerHeader(
        child: Text('User not found'),
        decoration: BoxDecoration(
          color: Colors.blue,
        ),
      );
    }

    DocumentReference<Map<String, dynamic>> usersRef =
        firestore.collection('users').doc(currentUserID);
    DocumentSnapshot<Map<String, dynamic>> userSnapshot = await usersRef.get();

    if (!userSnapshot.exists) {
      // Handle case where user document doesn't exist
      return DrawerHeader(
        child: Text('User not found'),
        decoration: BoxDecoration(
          color: Colors.blue,
        ),
      );
    }

    name = userSnapshot.get('name');
    surname = userSnapshot.get('surname');
    email = userSnapshot.get('email');

    return DrawerHeader(
      child: Column(
        children: [
          Text('${name} ${surname}',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
              )),
          Text('$email',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              )),
        ],
      ),
      decoration: BoxDecoration(
        color: Colors.blue,
      ),
    );
  }

  void signOutUser() async {
    await FirebaseAuth.instance.signOut();
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => LoginPage()));

    prefs.setBool('rememberMe', false);
  }
}
