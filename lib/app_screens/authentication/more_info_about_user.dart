import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hadithni/Backend/firebase/cloud_data_management.dart';
import 'package:hadithni/app_screens/chat/navigation_bar_controller.dart';
import 'package:loading_overlay/loading_overlay.dart';

class MoreInfoAboutUser extends StatefulWidget {
  MoreInfoAboutUser({Key? key}) : super(key: key);

  @override
  _MoreInfoAboutUserState createState() => _MoreInfoAboutUserState();
}

class _MoreInfoAboutUserState extends State<MoreInfoAboutUser> {
  bool loading = false;
  TextEditingController _name = TextEditingController();
  TextEditingController _about = TextEditingController();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final RegExp _messageRegex = RegExp(r'[a-zA-Z0-9]');
  final CloudStoreDataManagement _cloudStoreDataManagement =
      CloudStoreDataManagement();

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(isLoading: loading, child: Scaffold(body: setUp()));
  }

  Widget setUp() {
    return ListView(
      children: [pageTitle(), myTextField(), toNextPageButton()],
    );
  }

  Widget pageTitle() {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).size.height / 5,
      ),
      child: Center(
          child: Text(
        "Set up your profile",
        style: TextStyle(fontSize: 18),
      )),
    );
  }

  Widget toNextPageButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: ElevatedButton.icon(
        onPressed: () async {
          if (formKey.currentState!.validate()) {
            if (mounted) {
              setState(() {
                this.loading = true;
              });
            }

            final bool canRegisterNewUser = await _cloudStoreDataManagement
                .checkThisUserAlreadyPresentOrNot(userName: this._name.text);

            String snackBarMessage = '';

            if (!canRegisterNewUser)
              snackBarMessage = 'User Name Already Present';
            else {
              final bool _userEntryResponse =
                  await _cloudStoreDataManagement.registerNewUser(
                      userName: this._name.text,
                      userAbout: this._about.text,
                      userEmail:
                          FirebaseAuth.instance.currentUser!.email.toString());
              if (_userEntryResponse) {
                snackBarMessage = 'User data Entry Successfully';
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => NavigationBarController()),
                    (route) => false);
              } else
                snackBarMessage = 'User Data Not Entry Successfully';
            }

            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(snackBarMessage)));

            if (mounted) {
              setState(() {
                this.loading = false;
              });
            } else {}
          }
        },
        label: Text("Next"),
        icon: Icon(Icons.arrow_forward),
      ),
    );
  }

  Widget myTextField() {
    return Form(
      key: formKey,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 30, vertical: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: _name,
              validator: (value) {
                if (value!.length < 6)
                  return "User Name At Least 6 Characters";
                else if (value.contains(' ') || value.contains('@'))
                  return "Space and '@' Not Allowed";
                else if (value.contains('__'))
                  return "'__' Not Allowed...User '_' instead of '__'";
                else if (!_messageRegex.hasMatch(value))
                  return "Sorry,Only Emoji Not Supported";
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
                labelText: "Your name",
                prefixIcon: Icon(
                  Icons.person,
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            TextFormField(
              controller: _about,
              maxLength: 200,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                    color: Colors.green,
                  ),
                ),
                labelText: "About you",
                prefixIcon: Icon(
                  Icons.info,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
