import 'package:flutter/material.dart';
import 'package:hadithni/app_screens/Global_Uses/enums.dart';
import 'package:hadithni/Backend/firebase/authentication_methods.dart';
import 'package:loading_overlay/loading_overlay.dart';

import '../../theme.dart';

class RegisterScreen extends StatefulWidget {
  RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final RegExp emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
  bool visibal = true;
  bool isLoading = false;

  late String usernNme;
  late String email;
  late String password = '';
  late String rePassword;

  final GoogleAuthentication _googleAuthentication = GoogleAuthentication();
  final FacebookAuthentication _facebookAuthentication =
      FacebookAuthentication();

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
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
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
                      return "Invalid Email!";
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
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: TextFormField(
                  onChanged: (value) {
                    setState(() {
                      password = value;
                    });
                  },
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "This Field is required";
                    }
                    if (value.length < 6) {
                      return "Password must not be at least 6 characters!";
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
                        Icons.security_outlined,
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
              Container(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: TextFormField(
                  onChanged: (value) {
                    setState(() {
                      rePassword = value;
                    });
                  },
                  validator: (value) {
                    if (value != password) {
                      return "Password does not conform!";
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
                      labelText: "Conform Password",
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
              registerButton(),
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
          "Register by :",
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
                  snackBarMessage = 'Register Completed';
                } else if (_googleSignInResults ==
                    GoogleSignInResults.SignInNotCompleted) {
                  snackBarMessage = 'Register not Completed';
                } else if (_googleSignInResults ==
                    GoogleSignInResults.AlreadySignedIn) {
                  snackBarMessage = 'Already Google Registered';
                } else {
                  snackBarMessage = 'Unexpected Error Happen';
                }

                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(snackBarMessage)));

                if (_googleSignInResults == GoogleSignInResults.SignInCompleted)
                  Navigator.of(context).pushReplacementNamed("userinfo");

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
                  snackBarMessage = 'Register Completed';
                } else if (_fbSignInResults ==
                    FBSignInResults.SignInNotCompleted) {
                  snackBarMessage = 'Register not Completed';
                } else if (_fbSignInResults ==
                    FBSignInResults.AlreadySignedIn) {
                  snackBarMessage = 'Already Facebook Registered';
                } else {
                  snackBarMessage = 'Unexpected Error Happen';
                }

                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(snackBarMessage)));

                if (_fbSignInResults == FBSignInResults.SignInCompleted)
                  Navigator.of(context).pushReplacementNamed("userinfo");

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

  Widget registerButton() {
    return Container(
        margin: EdgeInsets.symmetric(vertical: 15, horizontal: 25),
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
                    bool response = await RegisterAuth(email, password);
                    if (response) {
                      Navigator.of(context).pushReplacementNamed("userinfo");
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content:
                              Text("This email is already used or invalid.")));
                    }
                  } else {}
                  setState(() {
                    isLoading = false;
                  });
                },
                child: Text("Create your account"))
          ],
        ));
  }
}
