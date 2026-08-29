import 'package:firebase_auth/firebase_auth.dart' as firebase;
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    super.displayName,
    super.photoUrl,
    super.phoneNumber,
    super.isEmailVerified = false,
    required super.provider,
    super.createdAt,
    super.lastLoginAt,
  });

  factory UserModel.fromFirebaseUser(firebase.User user) {
    AuthProvider authProvider = AuthProvider.email;

    if (user.isAnonymous) {
      authProvider = AuthProvider.anonymous;
    } else if (user.providerData.isNotEmpty) {
      final providerId = user.providerData.first.providerId;
      if (providerId.contains('google')) {
        authProvider = AuthProvider.google;
      } else if (providerId.contains('apple')) {
        authProvider = AuthProvider.apple;
      }
    }

    return UserModel(
      uid: user.uid,
      email: user.email ?? (user.isAnonymous ? 'guest@app.com' : ''),
      displayName: user.displayName ?? (user.isAnonymous ? 'زائر' : null),
      photoUrl: user.photoURL,
      phoneNumber: user.phoneNumber,
      isEmailVerified: user.emailVerified,
      provider: authProvider,
      createdAt: user.metadata.creationTime,
      lastLoginAt: user.metadata.lastSignInTime,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      phoneNumber: map['phoneNumber'],
      isEmailVerified: map['isEmailVerified'] ?? false,
      provider: AuthProvider.values.firstWhere(
        (e) => e.name == map['provider'],
        orElse: () => AuthProvider.email,
      ),
      createdAt:
          map['createdAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
              : null,
      lastLoginAt:
          map['lastLoginAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['lastLoginAt'])
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'isEmailVerified': isEmailVerified,
      'provider': provider.name,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'lastLoginAt': DateTime.now().millisecondsSinceEpoch,
    };
  }
}
