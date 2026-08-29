import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

abstract interface class FirebaseService {
  FirebaseAuth get auth;

  FirebaseFirestore get firestore;

  User? get currentUser;

  Future<void> initialize();
}

class FirebaseServiceImpl implements FirebaseService {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;

  @override
  FirebaseAuth get auth {
    final value = _auth;

    if (value == null) {
      throw StateError('FirebaseService has not been initialized');
    }

    return value;
  }

  @override
  FirebaseFirestore get firestore {
    final value = _firestore;

    if (value == null) {
      throw StateError('FirebaseService has not been initialized');
    }

    return value;
  }

  @override
  User? get currentUser => _auth?.currentUser;

  @override
  Future<void> initialize() async {
    await Firebase.initializeApp();

    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
  }
}
