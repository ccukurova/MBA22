import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Helpers/SharedPreferencesManager.dart';
import 'RegisterPage.dart';
import 'LedgerPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final users = FirebaseFirestore.instance.collection('users');
  FirebaseAuth mAuth = FirebaseAuth.instance;
  final SharedPreferencesManager prefs = SharedPreferencesManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Login'),
        ),
        body: Center(
            child: Container(
          width: 400,
          height: double.infinity,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter a e-mail address.';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    email = value!;
                  },
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter a password';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    password = value!;
                  },
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      print('Username: $email');
                      print('Password: $password');
                      loginUser(email, password);
                    }
                  },
                  child: Text('Log in'),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 20,
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => RegisterPage()));
                  },
                  child: Text('Register'),
                ),
              ],
            ),
          ),
        )));
  }

  Future<void> loginUser(String _email, String _password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: _email, password: _password);

      String currentUserUID = mAuth.currentUser!.uid;

      final querySnapshot =
          await users.where('userUID', isEqualTo: currentUserUID).get();

      for (final document in querySnapshot.docs) {
        final userID = document.id;
        await prefs.setString("userID", userID);
        print('userID=${await prefs.getString('userID')}');
      }

      Navigator.push(
          context, MaterialPageRoute(builder: (context) => LedgerPage()));

      print('Log-in is successful!');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
        const snackAlreadyUsed = SnackBar(
          content: Text('No user found for that email.'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackAlreadyUsed);
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
        const wrongPassword = SnackBar(
          content: Text('Wrong password provided for that user.'),
        );
        ScaffoldMessenger.of(context).showSnackBar(wrongPassword);
      } else if (e.code == "invalid-email") {
        const invalidEmail = SnackBar(
          content: Text('Invalid e-mail.'),
        );
        ScaffoldMessenger.of(context).showSnackBar(invalidEmail);
      } else if (e.code == "user-disabled") {
        const invalidEmail = SnackBar(
          content: Text('User account has been disabled.'),
        );
        ScaffoldMessenger.of(context).showSnackBar(invalidEmail);
      } else {
        print('Undefined auth error:${e.code}');
        const authError = SnackBar(
          content: Text('Authentication is failed.'),
        );
        ScaffoldMessenger.of(context).showSnackBar(authError);
      }
    } catch (e) {
      print(e);
    }
  }
}
