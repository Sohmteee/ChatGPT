import 'dart:developer';

import 'package:auscy/data.dart';
import 'package:auscy/data/colors/colors.dart';
import 'package:auscy/screens/home.dart';
import 'package:auscy/widgets/text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_sign_in/google_sign_in.dart';

User? user = FirebaseAuth.instance.currentUser;

class SignInScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  SignInScreen({super.key});

  Future<User?> _signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth =
        await googleUser!.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential =
        await _auth.signInWithCredential(credential);
    return userCredential.user;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () async {
            try {
              user = await _signInWithGoogle();
              showDialog(
                context: context,
                builder: (context) {
                  return Dialog(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          alignment: Alignment.center,
                          width: 100.sp,
                          height: 100.sp,
                          child: const CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  );
                },
              );
            } catch (e) {
              log(e.toString());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: AppBoldText(
                    e.toString().split(']').last,
                    textAlign: TextAlign.center,
                  ),
                  showCloseIcon: true,
                  closeIconColor: Colors.white,
                  backgroundColor: primaryColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }

            if (user != null) {
              log('Signed in as ${user!.displayName}');
              log('Email: ${user!.email}');
              log('UID: ${user!.uid}');

              await usersDB.doc(user!.uid).set(
                {
                  'email': user!.email,
                  'name': user!.displayName,
                  'uid': user!.uid,
                },
                SetOptions(merge: true),
              );

              Navigator.pop(context);

              /*  ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: AppBoldText(
                    'Welcome, ${user!.displayName}',
                    textAlign: TextAlign.center,
                  ),
                  showCloseIcon: true,
                  closeIconColor: Colors.white,
                  backgroundColor: primaryColor,
                  behavior: SnackBarBehavior.floating,
                ),
              ); */

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(),
                ),
              );
            } else {
              log('Failed to sign in');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: AppBoldText(
                    'Failed to sign in, try again.',
                    textAlign: TextAlign.center,
                  ),
                  showCloseIcon: true,
                  closeIconColor: Colors.white,
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/svg/google-icon.svg',
                width: 20.w,
              ),
              SizedBox(width: 8.w),
              const Text('Sign in with Google'),
            ],
          ),
        ),
      ),
    );
  }
}
