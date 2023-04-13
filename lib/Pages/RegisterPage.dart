import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:MBA22/Models/UserModel.dart';
import 'package:MBA22/Pages/LoginPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Helpers/SharedPreferencesManager.dart';
import 'LedgerPage.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String surname = '';
  String email = '';
  String phone = '';
  String password = '';
  String passwordConfirmation = '';
  final passController = TextEditingController();
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final users = FirebaseFirestore.instance.collection('users');
  FirebaseAuth mAuth = FirebaseAuth.instance;
  final SharedPreferencesManager prefs = SharedPreferencesManager();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    name = value!;
                  },
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Surname',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your surname';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    surname = value!;
                  },
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
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
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    phone = value!;
                  },
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: passController,
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
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != passController.value.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    passwordConfirmation = value!;
                  },
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      print('Name: $name');
                      print('Surname: $surname');
                      print('Email: $email');
                      print('Phone: $phone');
                      print('Password: $password');
                      print('Password Confirmation: $passwordConfirmation');
                      // TODO: Call the API to register the user

                      await createUser(name, surname, email, phone, password);
                      await loginUser(email, password);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LedgerPage()));
                    }
                  },
                  child: Text('Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> createUser(String _name, String _surname, String _email,
      String _phone, String _password) async {
    try {
      await authUser(_email, _password);
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: _email, password: _password);
      var newUser = UserModel(
          userUID: mAuth.currentUser!.uid,
          email: _email,
          name: _name,
          surname: _surname,
          phone: _phone,
          createDate: DateTime.now(),
          updateDate: DateTime.now(),
          isActive: true);

      DocumentReference usersDoc = await users.add({
        'userUID': newUser.userUID,
        'email': newUser.email,
        'name': newUser.name,
        'surname': newUser.surname,
        'phone': newUser.phone,
        'createDate': Timestamp.fromDate(newUser.createDate),
        'updateDate': Timestamp.fromDate(newUser.updateDate),
        'isActive': newUser.isActive
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> authUser(String _email, String _password) async {
    try {
      UserCredential credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email,
        password: _password,
      );
      await Future.delayed(Duration(seconds: 1));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
        const snackWeakPass = SnackBar(
          content: Text('The password provided is too weak.'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackWeakPass);
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
        const snackAlreadyUsed = SnackBar(
          content: Text('The account already exists for that email.'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackAlreadyUsed);
      } else if (e.code == 'invalid-email') {
        print('Email address is invalid.');
        const snackInvalidEmail = SnackBar(
          content: Text('Email address is invalid.'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackInvalidEmail);
      } else {
        const snackRegisterError = SnackBar(
          content: Text("Registere failed.Please check your input values."),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackRegisterError);
      }
    } catch (E) {
      print("Authentication failed!");
    }
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
