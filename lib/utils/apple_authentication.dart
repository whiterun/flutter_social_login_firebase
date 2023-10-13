// import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../views/user_info_view.dart';

class AppleAuthentication {
  static Future<FirebaseApp> initializeFirebase(
      {required BuildContext context}) async {
    FirebaseApp firebaseApp = await Firebase.initializeApp();

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => UserInfoView(
              user: user,
            ),
          ),
        );
      }
    }

    return firebaseApp;
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  static Future<User?> signInWithApple({required BuildContext context}) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user;

    final appleCredential = await SignInWithApple.getAppleIDCredential(scopes: [
      AppleIDAuthorizationScopes.email,
      AppleIDAuthorizationScopes.fullName,
    ]);

    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
    );

    try {
      final UserCredential userCredential =
          await auth.signInWithCredential(oauthCredential);

      user = userCredential.user;

      final token = await userCredential.user?.getIdTokenResult();
      debugPrint(token.toString());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppleAuthentication.customSnackBar(
              content: 'The account already exists with a different credential',
            ),
          );
        }
      } else if (e.code == 'invalid-credential') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppleAuthentication.customSnackBar(
              content: 'Error occurred while accessing credentials. Try again.',
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppleAuthentication.customSnackBar(
            content: 'Error occurred using Google Sign In. Try again.',
          ),
        );
      }
    }

    return user;
  }

  static SnackBar customSnackBar({required String content}) {
    return SnackBar(
      backgroundColor: Colors.black,
      content: Text(
        content,
        style: const TextStyle(color: Colors.redAccent, letterSpacing: 0.5),
      ),
    );
  }
}
