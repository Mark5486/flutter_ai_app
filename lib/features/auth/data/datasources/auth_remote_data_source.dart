import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

abstract interface class AuthRemoteDataSource {
  Stream<UserModel?> get authStateChanges;
  Future<UserModel?> getCurrentUser();
  Future<UserModel> loginWithEmail(String email, String password);
  Future<UserModel> registerWithEmail(
    String name,
    String email,
    String password,
  );
  Future<UserModel> signInWithGoogle();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRemoteDataSourceImpl({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((user) {
      return user != null ? UserModel.fromFirebaseUser(user) : null;
    });
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      return UserModel.fromFirebaseUser(user);
    }
    return null;
  }

  @override
  Future<UserModel> loginWithEmail(String email, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return UserModel.fromFirebaseUser(credential.user!);
  }

  @override
  Future<UserModel> registerWithEmail(
    String name,
    String email,
    String password,
  ) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user?.updateDisplayName(name);
    await credential.user?.reload();
    final updatedUser = _firebaseAuth.currentUser!;

    final userModel = UserModel.fromFirebaseUser(updatedUser);

    await _saveUserToFirestore(userModel);
    return userModel;
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw const FormatException('CANCELED_BY_USER');
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final userModel = UserModel.fromFirebaseUser(userCredential.user!);
    await _saveUserToFirestore(userModel);
    return userModel;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> logout() async {
    await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
  }

  Future<void> _saveUserToFirestore(UserModel user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);

    final Map<String, dynamic> userData = user.toMap();
    userData['lastLoginAt'] = FieldValue.serverTimestamp();

    await userDoc.set(userData, SetOptions(merge: true));
  }
}
