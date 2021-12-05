import 'package:flutter/material.dart';
import 'package:hadithni/app_screens/chat/inbox.dart';
import 'package:hadithni/app_screens/chat/contacts_page.dart';
import 'package:hadithni/app_screens/chat/profile.dart';
import 'package:fancy_bottom_navigation/fancy_bottom_navigation.dart';

class NavigationBarController extends StatefulWidget {
  NavigationBarController({Key? key}) : super(key: key);

  @override
  _NavigationBarControllerState createState() =>
      _NavigationBarControllerState();
}

class _NavigationBarControllerState extends State<NavigationBarController> {
  var selected = 0;

  List pages = [AllMessagesScreen(), ContactsPage(), UserProfile()];
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          backgroundColor: Colors.grey[400],
          body: pages.elementAt(selected),
          bottomNavigationBar: FancyBottomNavigation(
            tabs: [
              TabData(
                  iconData: Icons.message_outlined,
                  title: selected == 0 ? "Inbox" : ""),
              TabData(
                iconData: Icons.people_outline,
                title: selected == 1 ? "Contacts" : "",
              ),
              TabData(
                  iconData: Icons.person, title: selected == 2 ? "Profile" : "")
            ],
            onTabChangedListener: (position) {
              setState(() {
                selected = position;
              });
            },
          )),
    );
  }
}
