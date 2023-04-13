import 'package:flutter/material.dart';
import 'package:flutter_application_1/Pages/LeftDrawer.dart';
import '../Helpers/SharedPreferencesManager.dart';
import 'LeftDrawer.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPage createState() => _MainPage();
}

class _MainPage extends State<MainPage> {

    String? currentUserID;
    String? currentLedgerID;
    final SharedPreferencesManager prefs = SharedPreferencesManager();


   @override
  void initState() {
    super.initState();
    prefs.getString("userID").then((value) {
      setState(() {
        currentUserID = value;
      });
    });
    prefs.getString("ledgerID").then((value) {
      setState(() {
        currentLedgerID = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Main Page'),
      ),
      drawer: LeftDrawer(),
      body: Column(
        children:[
           Text(
          'Current user:${currentUserID}',
          style: TextStyle(fontSize: 24),
        ),
         Text(
          'Current ledger:${currentLedgerID}',
          style: TextStyle(fontSize: 24),
        )

        ]
        
      ),
    );
  }
}
