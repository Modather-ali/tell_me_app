import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:hadithni/app_screens/Global_Uses/enums.dart';

Future<bool> RegisterAuth(String email, String password) async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);
    if (userCredential.user!.email != null) {
      userCredential.user!.sendEmailVerification();
    }
    return true;
  } on FirebaseAuthException catch (e) {
    if (e.code == 'weak-password') {
      print('The password provided is too weak. $e');
    } else if (e.code == 'email-already-in-use') {
      print('The account already exists for that email.');
    }
    return false;
  }
}

Future LogInAuth(String email, String password) async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
    return;
  } on FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found') {
      print('No user found for that email.');
    } else if (e.code == 'wrong-password') {
      print('Wrong password provided for that user.');
    }
    return false;
  }
}

class GoogleAuthentication {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<GoogleSignInResults> signInWithGoogle() async {
    try {
      if (await this._googleSignIn.isSignedIn())
        return GoogleSignInResults.AlreadySignedIn;
      else {
        final GoogleSignInAccount? _googleSignInAccount =
            await this._googleSignIn.signIn();

        if (_googleSignInAccount == null)
          return GoogleSignInResults.SignInNotCompleted;
        else {
          final GoogleSignInAuthentication _googleSignInAuth =
              await _googleSignInAccount.authentication;

          final OAuthCredential _oAuthCredential =
              GoogleAuthProvider.credential(
            accessToken: _googleSignInAuth.accessToken,
            idToken: _googleSignInAuth.idToken,
          );

          final UserCredential userCredential = await FirebaseAuth.instance
              .signInWithCredential(_oAuthCredential);

          if (userCredential.user!.email != null) {
            print('Google Sign In Completed');
            return GoogleSignInResults.SignInCompleted;
          } else {
            print('Google Sign In Problem');
            return GoogleSignInResults.UnexpectedError;
          }
        }
      }
    } catch (e) {
      print('Error in Google Sign In ${e.toString()}');
      return GoogleSignInResults.UnexpectedError;
    }
  }

  Future<bool> logOut() async {
    try {
      print('Google Log out');

      await _googleSignIn.disconnect();
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      return true;
    } catch (e) {
      print('Error in Google Log Out: ${e.toString()}');
      return false;
    }
  }
}

class FacebookAuthentication {
  final FacebookAuth _facebookLogin = FacebookAuth.instance;

  Future<FBSignInResults> facebookLogIn() async {
    try {
      if (await _facebookLogin.accessToken == null) {
        final LoginResult _fbLogInResult = await _facebookLogin.login();

        if (_fbLogInResult.status == LoginStatus.success) {
          final OAuthCredential _oAuthCredential =
              FacebookAuthProvider.credential(
                  _fbLogInResult.accessToken!.token);

          if (FirebaseAuth.instance.currentUser != null)
            FirebaseAuth.instance.signOut();

          final UserCredential fbUser = await FirebaseAuth.instance
              .signInWithCredential(_oAuthCredential);

          print(
              'Fb Log In Info: ${fbUser.user}    ${fbUser.additionalUserInfo}');

          return FBSignInResults.SignInCompleted;
        }

        return FBSignInResults.UnExpectedError;
      } else {
        print('Already Fb Logged In');
        await logOut();
        return FBSignInResults.AlreadySignedIn;
      }
    } catch (e) {
      print('Facebook Log In Error: ${e.toString()}');
      return FBSignInResults.UnExpectedError;
    }
  }

  Future<bool> logOut() async {
    try {
      print('Facebook Log Out');
      if (await _facebookLogin.accessToken != null) {
        await _facebookLogin.logOut();
        await FirebaseAuth.instance.signOut();
        return true;
      }
      return false;
    } catch (e) {
      print('Facebook Log out Error: ${e.toString()}');
      return false;
    }
  }
}
