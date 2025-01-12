import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUpUser(String email, String password, String fullName, String phoneNumber) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('Users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'userType': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
      return userCredential;
    } catch (e) {
      throw e;
    }
  }

  Future<UserCredential> signUpCompany(String email, String password, String companyName, String gstNumber) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('Companies').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'companyName': companyName,
        'gstNumber': gstNumber,
        'isAuthorized': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
      return userCredential;
    } catch (e) {
      throw e;
    }
  }

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check user type by looking for documents in both collections
      final userDoc = await _firestore.collection('Users').doc(credential.user!.uid).get();
      final companyDoc = await _firestore.collection('Companies').doc(credential.user!.uid).get();

      bool isCompany = companyDoc.exists && companyDoc.data()?.containsKey('gstNumber') == true;
      
      notifyListeners();
      return {
        'credential': credential,
        'isCompany': isCompany,
      };
    } catch (e) {
      throw e;
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      notifyListeners();
      
      // Clear navigation stack and go to login
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      throw e;
    }
  }
}