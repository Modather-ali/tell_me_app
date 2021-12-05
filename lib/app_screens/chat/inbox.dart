import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hadithni/app_screens/Global_Uses/enums.dart';
import 'package:hadithni/app_screens/chat/chat_room.dart';
import 'package:hadithni/app_screens/chat/helpful_screens/search_screen.dart';
import 'package:hadithni/app_screens/chat/profile.dart';
import 'package:hadithni/theme.dart';
import 'package:animations/animations.dart';

class AllMessagesScreen extends StatefulWidget {
  AllMessagesScreen({Key? key}) : super(key: key);

  @override
  _AllMessagesScreenState createState() => _AllMessagesScreenState();
}

class _AllMessagesScreenState extends State<AllMessagesScreen> {
  String imageUrl =
      'https://firebasestorage.googleapis.com/v0/b/hadithni.appspot.com/o/profile.png?alt=media&token=e5cc42a1-2182-4155-be7f-d83f76e87136';

  bool loading = false;
  List conectedUsersNames = [];
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
                'profile_pic': document.get('profile_pic'),
                'user_email': document.id,
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
    var heigth = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[400],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            expandedHeight:
                MediaQuery.of(context).orientation == Orientation.portrait
                    ? heigth / 3
                    : heigth / 2,
            flexibleSpace: FlexibleSpaceBar(
              background: Column(
                children: [
                  _searchBar(),
                  _activityList(context),
                ],
              ),
            ),
          ),
          SliverList(
              delegate: SliverChildListDelegate([
            _allChatMessages(context),
          ]))
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 15),
        alignment: Alignment.center,
        height: MediaQuery.of(context).size.height / 8,
        width: double.infinity,
        color: Colors.transparent,
        child: GestureDetector(
            onTap: () async {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => SearchScreen()));
            },
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height / 16,
              decoration: BoxDecoration(boxShadow: [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 10.0,
                  spreadRadius: 0.0,
                  offset: const Offset(0.0, 5.0),
                )
              ], color: Colors.white, borderRadius: BorderRadius.circular(30)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search),
                  SizedBox(
                    width: 10,
                  ),
                  Text("Send a message?")
                ],
              ),
            )));
  }

  Widget _activityList(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        left: 10.0,
      ),
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).orientation == Orientation.portrait
          ? MediaQuery.of(context).size.height * (1.5 / 8)
          : MediaQuery.of(context).size.height * (3 / 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal, // Make ListView Horizontally
        itemCount: conectedUsersData.length,
        itemBuilder: (context, position) {
          return _activityCollectionList(context, position);
        },
      ),
    );
  }

  Widget _activityCollectionList(BuildContext context, int index) {
    return Container(
      margin: EdgeInsets.only(right: MediaQuery.of(context).size.width / 18),
      height: MediaQuery.of(context).size.height * (1.5 / 8),
      child: Column(
        children: [
          Stack(
            children: [
              OpenContainer(
                closedColor: const Color.fromRGBO(34, 48, 60, 1),
                openColor: const Color.fromRGBO(34, 48, 60, 1),
                middleColor: const Color.fromRGBO(34, 48, 60, 1),
                closedElevation: 0.0,
                closedShape: CircleBorder(),
                transitionDuration: Duration(
                  milliseconds: 500,
                ),
                transitionType: ContainerTransitionType.fadeThrough,
                openBuilder: (context, openWidget) {
                  return UserProfile(
                    userEmail:
                        conectedUsersData[index]['user_email'].toString(),
                  );
                },
                closedBuilder: (context, closeWidget) {
                  return CircleAvatar(
                    backgroundColor: const Color.fromRGBO(34, 48, 60, 1),
                    backgroundImage:
                        conectedUsersData[index]['profile_pic'].toString() == ''
                            ? NetworkImage(imageUrl)
                            : NetworkImage(
                                conectedUsersData[index]['profile_pic']
                                    .toString(),
                              ),
                    radius: MediaQuery.of(context).orientation ==
                            Orientation.portrait
                        ? MediaQuery.of(context).size.height * (1 / 8) / 2.5
                        : MediaQuery.of(context).size.height * (2.5 / 8) / 2.5,
                  );
                },
              ),
            ],
          ),
          Container(
            alignment: Alignment.center,
            margin: EdgeInsets.only(
              top: 7.0,
            ),
            child: Text(
              conectedUsersData[index]['user_name'].toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _allChatMessages(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height / 1.2),
      child: Container(
          padding: EdgeInsets.only(bottom: 25),
          decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10.0,
                  spreadRadius: 0.0,
                  offset:
                      const Offset(0.0, -5.0), // shadow direction: bottom right
                )
              ],
              color: Colors.white,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50), topRight: Radius.circular(50))),
          child: conectedUsersData.isEmpty
              ? Center(
                  child: Text(
                  "You have no messages yet",
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ))
              : ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: conectedUsersData.length,
                  itemBuilder: (context, index) {
                    return _chatMessageList(index, () {});
                  })),
    );
  }

  Widget _chatMessageList(index, press) {
    return InkWell(
      onTap: press,
      child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding, vertical: kDefaultPadding * 0.75),
          child: OpenContainer(
              closedElevation: 0,
              transitionType: ContainerTransitionType.fadeThrough,
              closedBuilder: (context, closedBuilder) {
                return closedBuilderWidget(index);
              },
              openBuilder: (context, openBuilder) {
                return ChatRoom(
                    userName: conectedUsersData[index]['user_name'].toString());
              })),
    );
  }

  closedBuilderWidget(int index) {
    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage:
                  conectedUsersData[index]['profile_pic'].toString() == ''
                      ? NetworkImage(imageUrl)
                      : NetworkImage(
                          conectedUsersData[index]['profile_pic'].toString(),
                        ),
            ),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conectedUsersData[index]['user_name'].toString(),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Opacity(
                  opacity: 0.64,
                  child: Text(
                    '',
                  ),
                ),
              ],
            ),
          ),
        ),
        Opacity(
            opacity: 0.64,
            child: Icon(
              Icons.message,
            )),
      ],
    );
  }
}
