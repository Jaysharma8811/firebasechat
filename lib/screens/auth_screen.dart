import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_chat_app/widgets/user_image_picker_widget.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _selectedImage;
  var _isLogin = true;
  var _enterEmail = '';
  var _enterPassword = '';
  var _isUploading = false;
  var _enterUserName= '';

  void _submit() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid || !_isLogin && _selectedImage == null) {
      return;
    }
    _formKey.currentState!.save();
    try {
      setState(() {
        _isUploading = true;
      });
      if (_isLogin) {
        final userCredentials = await _firebase.signInWithEmailAndPassword(
            email: _enterEmail, password: _enterPassword);
        print(userCredentials);
      } else {
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
            email: _enterEmail, password: _enterPassword);
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${userCredentials.user!.uid}.jpg');
        await storageRef.putFile(_selectedImage!);
        final imageUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredentials.user!.uid)
            .set({
          'username': _enterUserName,
          'email': _enterEmail,
          'imageUrl': imageUrl
        });

        print(userCredentials);
        print(imageUrl);
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {}
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Authentication Failed.')));
    }
    setState(() {
      _isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                  top: 30,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                width: 200,
                child: Image.asset("images/chatlogo.gif"),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_isLogin)
                            UserImagePickerWidget(
                              onPickImage: (pickedImage) {
                                _selectedImage = pickedImage;
                              },
                            ),
                          if(!_isLogin)
                          TextFormField(
                            decoration: const InputDecoration(
                                labelText: 'User name'),

                            autocorrect: false,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ) {
                                return 'Please Enter a valid user name';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enterUserName = value!;
                            },
                          ),
                          TextFormField(
                            decoration: const InputDecoration(
                                labelText: 'Email Address'),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  !value.contains('@')) {
                                return 'Please Enter a valid Email Address';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enterEmail = value!;
                            },
                          ),
                          TextFormField(
                            decoration:
                                const InputDecoration(labelText: 'Password'),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.trim().length < 6) {
                                return 'Password must be 6 character long';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enterPassword = value!;
                            },
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          if (_isUploading) const CircularProgressIndicator(),
                          if (!_isUploading)
                            ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary),
                              child: Text(
                                _isLogin ? 'Login' : 'SignUp',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          if (!_isUploading)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                });
                              },
                              child: Text(_isLogin
                                  ? 'Create an Account'
                                  : 'I already have an Account'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
