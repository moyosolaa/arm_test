import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Firebase Auth Provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

// Firestore Provider
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// Auth State Provider
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(firebaseAuthProvider).authStateChanges();
});

// Groups Stream Provider
final groupsStreamProvider = StreamProvider<QuerySnapshot>((ref) {
  return ref.read(firestoreProvider).collection('groups').snapshots();
});
