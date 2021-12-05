import 'package:animations/animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hadithni/app_screens/Global_Uses/enums.dart';
import 'package:hadithni/app_screens/chat/chat_room.dart';
import 'package:hadithni/app_screens/chat/helpful_screens/search_screen.dart';
import 'package:hadithni/theme.dart';

class ContactsPage extends StatefulWidget {
  ContactsPage({Key? key}) : super(key: key);

  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  String imageUrl =
      'https://firebasestorage.googleapis.com/v0/b/hadithni.appspot.com/o/profile.png?alt=media&token=e5cc42a1-2182-4155-be7f-d83f76e87136';

  List<Map<String, String>> conectedUsersData = [];

  final CollectionReference<Map<String, dynamic>> collectionReference =
      FirebaseFirestore.instance.collection("users");

  final String? currentUserEmail = FirebaseAuth.instance.currentUser!.email;

  Future getConnectionData() async {
    Stream<QuerySnapshot> collectionData = collectionReference.snapshots();
    collectionData.listen((querySnapshot) {
      querySnapshot.docs.forEach((queryDocumentSnapshot) async {
        if (queryDocumentSnapshot.id ==
            FirebaseAuth.instance.currentUser!.email) {
          await getconectedUsersData(queryDocumentSnapshot, querySnapshot.docs);
        }
      });
    });
  }

  getconectedUsersData(
    QueryDocumentSnapshot queryDocumentSnapshot,
    List<QueryDocumentSnapshot> docs,
  ) async {
    conectedUsersData.clear(); // to be sure it's Empty
    List connectionRequestList =
        await queryDocumentSnapshot.get("connection_request");

    connectionRequestList.forEach((connectionRequestData) {
      if (connectionRequestData.values.first.toString() ==
              OtherConnectionStatus.Invitation_Accepted.toString() ||
          connectionRequestData.values.first.toString() ==
              OtherConnectionStatus.Request_Accepted.toString()) {
        docs.forEach((document) {
          if (document.id == connectionRequestData.keys.first.toString()) {
            setState(() {
              conectedUsersData.add({
                'user_name': document.get('user_name'),
                'profile_pic': document.get('profile_pic')
              });
            });
          }
        });
      }
    });
  }

  @override
  void initState() {
    getConnectionData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            "My Connections",
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
        ),
        body: conectedUsersNamesListItems(),
        floatingActionButton: _openAvailableConnectionsScreen());
  }

  Widget conectedUsersNamesListItems() {
    return ListView.builder(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: conectedUsersData.length,
        itemBuilder: (context, index) {
          return contactsCard(index);
        });
  }

  Widget contactsCard(int index) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ChatRoom(
                userName: conectedUsersData[index]['user_name'].toString())));
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 25),
              child: CircleAvatar(
                radius: 30,
                foregroundImage:
                    conectedUsersData[index]['profile_pic'].toString() == ''
                        ? NetworkImage(imageUrl)
                        : NetworkImage(
                            conectedUsersData[index]['profile_pic'].toString(),
                          ),
              ),
            ),
            Expanded(
              child: Text(
                conectedUsersData[index]['user_name'].toString(),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _openAvailableConnectionsScreen() {
    return OpenContainer(
        closedElevation: 20,
        closedColor: kPrimaryColor,
        closedShape: CircleBorder(),
        closedBuilder: (context, close) {
          return Container(
            padding: EdgeInsets.all(10),
            child: Icon(
              Icons.person_add,
              color: Colors.white,
              size: 35,
            ),
          );
        },
        openBuilder: (context, open) {
          return SearchScreen();
        });
  }
}
