import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_social_login_firebase/utils/laravel_passport.dart';
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

    try {
      const charset =
          '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
      final random = Random.secure();
      final rawNonce =
          List.generate(32, (_) => charset[random.nextInt(charset.length)])
              .join();

      final bytes = utf8.encode(rawNonce);
      final digest = sha256.convert(bytes);
      final nonce = digest.toString();

      final appleCredential =
          await SignInWithApple.getAppleIDCredential(scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ], nonce: nonce);

      final oauthCredential = OAuthProvider("apple.com").credential(
          idToken: appleCredential.identityToken, rawNonce: rawNonce);

      final UserCredential userCredential =
          await auth.signInWithCredential(oauthCredential);

      /* In case displayName and email from firebase is null */
      final userDisplayName = [
        appleCredential.givenName ?? '',
        appleCredential.familyName ?? '',
      ].join(' ').trim();

      final userEmail = appleCredential.email ?? '';
      /*  */

      user = userCredential.user;

      if (userDisplayName.isNotEmpty) {
        await user?.updateDisplayName(userDisplayName);
      }

      if (userEmail.isNotEmpty) {
        await user?.updateEmail(userEmail);
      }

      await user?.reload();

      final token = await userCredential.user?.getIdTokenResult();

      Map<String, dynamic> parameters = {
        'name': userDisplayName,
        'email': userEmail,
      };

      await LaravelPassport.exchangeToken(token?.token, parameters);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code != AuthorizationErrorCode.canceled && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppleAuthentication.customSnackBar(
            content: e.message,
          ),
        );
      }
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
            content: 'Error occurred using Apple Sign In. Try again.',
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
