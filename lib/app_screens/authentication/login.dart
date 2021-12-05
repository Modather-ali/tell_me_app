import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hadithni/Backend/firebase/cloud_data_management.dart';
import 'package:hadithni/app_screens/Global_Uses/enums.dart';
import 'package:hadithni/Backend/firebase/authentication_methods.dart';
import 'package:hadithni/theme.dart';
import 'package:loading_overlay/loading_overlay.dart';

class LogInScreen extends StatefulWidget {
  LogInScreen({Key? key}) : super(key: key);

  @override
  _LogInScreenState createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  final RegExp emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool visibal = true;
  bool isLoading = false;
  late String username;
  late String email = '';
  late String password;
  final GoogleAuthentication _googleAuthentication = GoogleAuthentication();
  final FacebookAuthentication _facebookAuthentication =
      FacebookAuthentication();
  final CloudStoreDataManagement _cloudStoreDataManagement =
      CloudStoreDataManagement();
  @override
  Widget build(BuildContext context) {
    // here we get the height and width of user's screen
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Form(
        autovalidateMode: AutovalidateMode.always,
        key: formKey,
        child: LoadingOverlay(
          isLoading: isLoading,
          child: ListView(
            physics: BouncingScrollPhysics(),
            children: [
              showAppIcon(height, width),
              socialMediaAuthentication(width),
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                child: TextFormField(
                  onSaved: (value) {
                    setState(() {
                      email = value!;
                    });
                  },
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "This Field is required";
                    } else if (!emailRegex.hasMatch(value.toString())) {
                      return "This email is not valid";
                    } else if (value.endsWith(" ")) {
                      return "Pleas delete the empty space";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(
                        color: Colors.green,
                      ),
                    ),
                    labelText: "User Email",
                    prefixIcon: Icon(
                      Icons.email,
                    ),
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                child: TextFormField(
                  onSaved: (value) {
                    setState(() {
                      password = value!;
                    });
                  },
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "This Field is required";
                    }
                    if (value.length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: Colors.green,
                        ),
                      ),
                      labelText: "User Password",
                      prefixIcon: Icon(
                        Icons.security,
                      ),
                      suffix: InkWell(
                        onTap: () {
                          setState(() {
                            visibal = !visibal;
                          });
                        },
                        child: Icon(visibal
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                      )),
                  obscureText: visibal,
                ),
              ),
              logInButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget showAppIcon(height, width) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Hero(
          tag: "tag",
          child: Image.asset(
            "assets/chat-box.png",
            width: width / 3,
            height: height / 8.3,
          )),
    );
  }

  Widget socialMediaAuthentication(width) {
    return Column(
      children: [
        Text(
          "Log in by :",
          style: TextStyle(
              color: kPrimaryColor,
              fontSize: 16,
              decoration: TextDecoration.overline),
        ),
        SizedBox(
          height: 5,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            socialMediaAuthenticationButton(
              image: "assets/google-plus.png",
              onTap: () async {
                print('Google Pressed');

                if (mounted) {
                  setState(() {
                    this.isLoading = true;
                  });
                }

                final GoogleSignInResults _googleSignInResults =
                    await this._googleAuthentication.signInWithGoogle();
                String snackBarMessage = '';

                if (_googleSignInResults ==
                    GoogleSignInResults.SignInCompleted) {
                  snackBarMessage = 'Log In Completed';
                } else if (_googleSignInResults ==
                    GoogleSignInResults.SignInNotCompleted) {
                  snackBarMessage = 'Log In not Completed';
                } else if (_googleSignInResults ==
                    GoogleSignInResults.AlreadySignedIn) {
                  snackBarMessage = 'Already Google LogedIn';
                } else {
                  snackBarMessage = 'Unexpected Error Happen';
                }

                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(snackBarMessage)));

                if (_googleSignInResults ==
                    GoogleSignInResults.SignInCompleted) {
                  final bool _dataPresentResponse =
                      await _cloudStoreDataManagement.userRecordPresentOrNot(
                          email: FirebaseAuth.instance.currentUser!.email
                              .toString());
                  _dataPresentResponse
                      ? Navigator.of(context).pushReplacementNamed("insied")
                      : Navigator.of(context).pushReplacementNamed("userinfo");
                }
                if (mounted) {
                  setState(() {
                    this.isLoading = false;
                  });
                }
              },
            ),
            socialMediaAuthenticationButton(
              image: "assets/facebook.png",
              onTap: () async {
                print('Facebook Pressed');

                if (mounted) {
                  setState(() {
                    this.isLoading = true;
                  });
                }

                final FBSignInResults _fbSignInResults =
                    await this._facebookAuthentication.facebookLogIn();
                String snackBarMessage = '';

                if (_fbSignInResults == FBSignInResults.SignInCompleted) {
                  snackBarMessage = 'Log In Completed';
                } else if (_fbSignInResults ==
                    FBSignInResults.SignInNotCompleted) {
                  snackBarMessage = 'Log In not Completed';
                } else if (_fbSignInResults ==
                    FBSignInResults.AlreadySignedIn) {
                  snackBarMessage = 'Already Facebook LogedIn';
                } else {
                  snackBarMessage = 'Unexpected Error Happen';
                }

                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(snackBarMessage)));

                if (_fbSignInResults == FBSignInResults.SignInCompleted)
                  Navigator.of(context).pushReplacementNamed("insied");

                if (mounted) {
                  setState(() {
                    this.isLoading = false;
                  });
                }
              },
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: EdgeInsets.only(right: 10),
              width: width / 3,
              height: 1,
              color: Colors.grey,
            ),
            Text(
              "Or",
              style: TextStyle(
                color: kPrimaryColor,
                fontSize: 16,
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: 10),
              width: width / 3,
              height: 1,
              color: Colors.grey,
            ),
          ],
        ),
      ],
    );
  }

  Widget socialMediaAuthenticationButton({String? image, Function()? onTap}) {
    return InkWell(
        child: Image.asset(
          image!,
          height: 50,
          width: 50,
        ),
        onTap: onTap);
  }

  Widget textDataField(
    String? savedValue,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      child: TextFormField(
        onSaved: (value) {
          setState(() {
            // svedValue is the text that the user will write
            savedValue = value!;
          });
        },
        validator: (text) {
          savedValue == email
              ? emailValidator(text!)
              : passwordValidator(text!);
        },
        decoration: InputDecoration(
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                color: Colors.green,
              ),
            ),
            labelText: savedValue == email ? "User's Email" : "User's Password",
            prefixIcon:
                Icon(savedValue == email ? Icons.email : Icons.security),
            suffix: savedValue == email
                ? null
                : InkWell(
                    onTap: () {
                      setState(() {
                        visibal = !visibal;
                      });
                    },
                    child: Icon(visibal
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                  )),
        obscureText: savedValue == email ? false : visibal,
      ),
    );
  }

  emailValidator(String value) {
    if (value == '') {
      return "This Field is required";
    } else if (!emailRegex.hasMatch(value.toString())) {
      return "This email is not valid";
    } else if (value.endsWith(" ")) {
      return "Pleas delete the empty space";
    }
    return null;
  }

  passwordValidator(String value) {
    if (value.isEmpty) {
      return "This Field is required";
    }
    if (value.length < 6) {
      return "Password must be at least 6 characters";
    }
    return null;
  }

  Widget logInButton() {
    return Container(
        margin: EdgeInsets.symmetric(vertical: 15, horizontal: 50),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();

                    setState(() {
                      isLoading = true;
                    });

                    var response = await LogInAuth(email, password);

                    if (response != false) {
                      Navigator.of(context).pushReplacementNamed("insied");
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                          "Error log in not complete\nThe password may be wrong",
                        ),
                        duration: Duration(seconds: 5),
                      ));
                    }
                  } else {}

                  setState(() {
                    isLoading = false;
                  });

                  User? user = FirebaseAuth.instance.currentUser;

                  if (user != null && !user.emailVerified) {
                    await user.sendEmailVerification();
                  }
                },
                child: Text("Log in")),
          ],
        ));
  }
}
