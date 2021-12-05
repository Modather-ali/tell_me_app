import 'package:flutter/material.dart';
import 'package:hadithni/app_screens/authentication/login.dart';
import 'package:hadithni/app_screens/authentication/register.dart';

class LogInAndRegisterPage extends StatefulWidget {
  LogInAndRegisterPage({Key? key}) : super(key: key);

  @override
  _LogInAndRegisterPageState createState() => _LogInAndRegisterPageState();
}

class _LogInAndRegisterPageState extends State<LogInAndRegisterPage>
    with SingleTickerProviderStateMixin {
  late TabController mycontroller;

  @override
  void initState() {
    mycontroller = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: TabBar(
        controller: mycontroller,
        tabs: [
          Tab(
            child: Text(
              "Log in",
              style: Theme.of(context).textTheme.bodyText1!,
            ),
          ),
          Tab(
            child: Text(
              "Register",
              style: Theme.of(context).textTheme.bodyText1!,
            ),
          )
        ],
      ),
      body: TabBarView(
        controller: mycontroller,
        children: [LogInScreen(), RegisterScreen()],
      ),
    ));
  }
}
