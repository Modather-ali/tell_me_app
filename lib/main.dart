import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hadithni/Backend/firebase/cloud_data_management.dart';
import 'package:hadithni/app_screens/authentication/login_and_register.dart';
import 'package:hadithni/app_screens/authentication/more_info_about_user.dart';
import 'package:hadithni/app_screens/chat/navigation_bar_controller.dart';
import 'package:hadithni/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Tell me Chat App',
    theme: MainThemeData(),
    home: await currentScreen(),
    routes: {
      "main": (context) => MyHomePage(),
      "LogInAndRegisterPage": (context) => LogInAndRegisterPage(),
      "insied": (context) => NavigationBarController(),
      "userinfo": (context) => MoreInfoAboutUser()
    },
  ));
}

Future<Widget> currentScreen() async {
  if (FirebaseAuth.instance.currentUser == null) {
    return MyHomePage();
  } else {
    final CloudStoreDataManagement _cloudStoreDataManagement =
        CloudStoreDataManagement();

    final bool _dataPresentResponse =
        await _cloudStoreDataManagement.userRecordPresentOrNot(
            email: FirebaseAuth.instance.currentUser!.email.toString());

    return _dataPresentResponse
        ? NavigationBarController()
        : MoreInfoAboutUser();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // here we get the height and width of user's screen
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(alignment: Alignment.center, children: [
        inBackInterface(height, width),
        inFrontOfInterface(height, width),
      ]),
    );
  }

  Widget inBackInterface(height, width) {
    return Stack(
      children: [
        Positioned(
          top: 0.0,
          left: 0.0,
          child: Container(
            height: height / 5,
            width: width / 3,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                    blurRadius: 15.0,
                    color: Colors.black54,
                    offset: Offset(0.5, -1.0),
                    spreadRadius: 0.0)
              ],
              color: Color(0xFFdeaaff),
              shape: BoxShape.rectangle,
              borderRadius:
                  BorderRadius.only(bottomRight: Radius.circular(100)),
            ),
          ),
        ),
        Positioned(
          bottom: 0.0,
          left: 0.0,
          right: 0.0,
          child: Container(
            alignment: Alignment.bottomCenter,
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            height: height / 3,
            width: double.infinity,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(150),
                    topRight: Radius.circular(150)),
                color: Color(0xFF6930c3),
                shape: BoxShape.rectangle),
          ),
        )
      ],
    );
  }

  inFrontOfInterface(height, width) {
    return Positioned(
      bottom: height / 4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Hero(
              tag: "tag",
              child: Image.asset(
                "assets/chat-box.png",
                width: width / 2,
                height: height / 4,
              )),
          Container(
              margin: EdgeInsets.symmetric(vertical: 25),
              width: width / 1.3,
              child: Text(
                "Spend a beautiful times with Tell Me app and contact with your friends and family",
                style: Theme.of(context).textTheme.bodyText1!,
                textAlign: TextAlign.center,
              )),
          ElevatedButton(
              onPressed: () {
                Navigator.of(context)
                    .pushReplacementNamed("LogInAndRegisterPage");
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Enter to the App",
                  ),
                  Icon(Icons.arrow_forward_outlined)
                ],
              ))
        ],
      ),
    );
  }
}
