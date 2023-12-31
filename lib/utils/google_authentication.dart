import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_social_login_firebase/utils/laravel_passport.dart';
import 'package:flutter_social_login_firebase/widgets/custom_snackbar.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../views/user_info_view.dart';

class GoogleAuthentication {
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

  static Future<User?> signInWithGoogle({required BuildContext context}) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user;

    if (kIsWeb) {
      GoogleAuthProvider authProvider = GoogleAuthProvider();

      try {
        final UserCredential userCredential =
            await auth.signInWithPopup(authProvider);

        user = userCredential.user;
      } catch (e) {
        if (kDebugMode) {
          debugPrint(e as String?);
        }
      }
    } else {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();

      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        try {
          final UserCredential userCredential =
              await auth.signInWithCredential(credential);

          user = userCredential.user;

          final token = await userCredential.user?.getIdTokenResult();
          await LaravelPassport.exchangeToken('google', token?.token, {});
        } on FirebaseAuthException catch (e) {
          if (e.code == 'account-exists-with-different-credential') {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                CustomSnackBar.show(
                  content:
                      'The account already exists with a different credential',
                ),
              );
            }
          } else if (e.code == 'invalid-credential') {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                CustomSnackBar.show(
                  content:
                      'Error occurred while accessing credentials. Try again.',
                ),
              );
            }
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              CustomSnackBar.show(
                content: 'Error occurred using Google Sign In. Try again.',
              ),
            );
          }
        }
      }
    }

    return user;
  }

  static Future<void> signOut({required BuildContext context}) async {
    final GoogleSignIn googleSignIn = GoogleSignIn();

    try {
      if (!kIsWeb) {
        await googleSignIn.signOut();
      }
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            content: 'Error signing out. Try again.',
          ),
        );
      }
    }
  }
}
