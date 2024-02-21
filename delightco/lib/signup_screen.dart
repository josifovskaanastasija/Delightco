import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  File? _pickedImage;

  Future<void> _pickImage() async {
    final imageSource = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Image Source'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
            child: Text('Gallery'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(ImageSource.camera),
            child: Text('Camera'),
          ),
        ],
      ),
    );

    if (imageSource != null) {
      final pickedImage = await ImagePicker().pickImage(source: imageSource);
      if (pickedImage != null) {
        setState(() {
          _pickedImage = File(pickedImage.path);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey,
                    backgroundImage:
                        _pickedImage != null ? FileImage(_pickedImage!) : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                      ),
                      child: Icon(
                        Icons.add_a_photo,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: confirmPasswordController,
              decoration: InputDecoration(labelText: 'Confirm Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (passwordController.text == confirmPasswordController.text &&
                    _pickedImage != null) {
                  User? user = await AuthService().signUpWithEmailAndPassword(
                    emailController.text,
                    passwordController.text,
                    _pickedImage!,
                  );

                  if (user != null) {
                    await saveUserProfile(
                        user.uid, emailController.text, _pickedImage!);

                    Navigator.pushReplacementNamed(context, '/home');
                  } else {
                    print('Signup failed');
                  }
                } else {
                  print(
                      'Passwords do not match or profile picture not selected');
                }
              },
              child: Text('Sign Up'),
            )
          ],
        ),
      ),
    );
  }

  Future<void> saveUserProfile(
      String uid, String email, File profilePicture) async {
    final storageRef = firebase_storage.FirebaseStorage.instance
        .ref()
        .child('profile_pictures/$uid.jpg');
    await storageRef.putFile(profilePicture);
    String username = email.split('@')[0];

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'email': email,
      'profilePictureUrl': await storageRef.getDownloadURL(),
      'username': username,
      'followers': 0,
      'following': 0,
    });
  }
}
