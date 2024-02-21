import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_profile.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserProfile _userProfile = UserProfile();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return result.user;
    } catch (e) {
      print('Error during sign in: $e');
      return null;
    }
  }

  Future<User?> signUpWithEmailAndPassword(
      String email, String password, File profilePicture) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _userProfile.uploadProfilePicture(profilePicture);
      return result.user;
    } catch (e) {
      print('Error during sign up: $e');
      return null;
    }
  }

    Future<String?> getUsernameFromUserId(String userId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _firestore.collection('users').doc(userId).get();
      return snapshot.data()?['username'];
    } catch (e) {
      print('Error getting username: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
