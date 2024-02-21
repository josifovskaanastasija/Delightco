import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class AddPostScreen extends StatefulWidget {
  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController descriptionController = TextEditingController();
  int rating = 1;
  File? _pickedImage;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? pickedImage = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  _setImage(pickedImage);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Camera'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? pickedImage = await picker.pickImage(
                    source: ImageSource.camera,
                  );
                  _setImage(pickedImage);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _setImage(XFile? pickedImage) {
    if (pickedImage != null) {
      setState(() {
        _pickedImage = File(pickedImage.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: _pickedImage != null
                      ? Image.file(_pickedImage!)
                      : Icon(Icons.add_a_photo, size: 30, color: Colors.black),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Text('Rating:'),
                SizedBox(width: 8),
                DropdownButton<int>(
                  value: rating,
                  onChanged: (value) {
                    setState(() {
                      rating = value!;
                    });
                  },
                  items: List.generate(5, (index) => index + 1)
                      .map<DropdownMenuItem<int>>((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(value.toString()),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _uploadPost();
          Navigator.pop(context);
        },
        child: Icon(Icons.post_add),
      ),
    );
  }

  Future<void> _uploadPost() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      String uid = user?.uid ?? '';

      String postId = FirebaseFirestore.instance.collection('posts').doc().id;

      if (_pickedImage != null) {
        firebase_storage.Reference storageRef = firebase_storage
            .FirebaseStorage.instance
            .ref()
            .child('posts/$postId.jpg');
        await storageRef.putFile(_pickedImage!);

        String imageUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance.collection('posts').doc(postId).set({
          'userId': uid,
          'description': descriptionController.text,
          'rating': rating,
          'imageUrl': imageUrl,
        });
      }
    } catch (e) {
      print('Error uploading post: $e');
    }
  }
}
