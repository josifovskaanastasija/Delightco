import 'dart:io';

// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class UserProfile {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> uploadProfilePicture(File imageFile) async {
    try {
      User? user = _auth.currentUser;
      String uid = user?.uid ?? '';
      Reference storageRef = _storage.ref().child('profile_pictures/$uid.jpg');
      await storageRef.putFile(imageFile);
    } catch (e) {
      print('Error uploading profile picture: $e');
    }
  }

  Future<String?> getUserProfilePicture() async {
    try {
      User? user = _auth.currentUser;
      String uid = user?.uid ?? '';

      firebase_storage.Reference storageRef = firebase_storage
          .FirebaseStorage.instance
          .ref()
          .child('profile_pictures/$uid.jpg');

      String downloadURL = await storageRef.getDownloadURL();

      return downloadURL;
    } catch (e) {
      print('Error getting profile picture: $e');
      return null;
    }
  }
}
