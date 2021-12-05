import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hadithni/Backend/firebase/authentication_methods.dart';
import 'package:hadithni/Backend/firebase/cloud_data_management.dart';
import 'package:hadithni/app_screens/chat/helpful_screens/images_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_overlay/loading_overlay.dart';

class UserProfile extends StatefulWidget {
  final String userEmail;
  const UserProfile({Key? key, this.userEmail = ''}) : super(key: key);

  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final GoogleAuthentication _googleAuthentication = GoogleAuthentication();
  final FacebookAuthentication _facebookAuthentication =
      FacebookAuthentication();

  final CloudStoreDataManagement _cloudStoreDataManagement =
      CloudStoreDataManagement();
  bool isLoading = false;
  String currentUserName = "";
  String currentUserAbout = "";
  String currentUserJoinTime = "";
  String currentUserJoinDate = "";
  String currentUserImage = "";

  late TextEditingController _about = TextEditingController();

  final CollectionReference<Map<String, dynamic>> collectionReference =
      FirebaseFirestore.instance.collection("users");

  getCurrentUserProfileData() async {
    final String? userId = widget.userEmail == ''
        ? FirebaseAuth.instance.currentUser!.email
        : widget.userEmail;

    final DocumentReference<Map<String, dynamic>> currentUserDocument =
        collectionReference.doc("$userId");

    final DocumentSnapshot<Map<String, dynamic>> getCurrentUserData =
        await currentUserDocument.get();

    final Map<String, dynamic>? currentUserData = getCurrentUserData.data();
    setState(() {
      currentUserName = currentUserData!['user_name'];

      currentUserAbout = currentUserData['about'];
      currentUserJoinTime = currentUserData['creation_time'];
      currentUserJoinDate = currentUserData['creation_date'];
      currentUserImage = currentUserData['profile_pic'];
      _about.text = currentUserAbout;
    });
  }

  editMyProfile(String imagePath) async {
    Navigator.of(context).pop();
    try {
      setState(() {
        isLoading = true;
      });

      final DocumentReference<Map<String, dynamic>> currentUserDocument =
          collectionReference.doc(FirebaseAuth.instance.currentUser!.email);

      if (imagePath == '') {
        currentUserDocument.update({'about': _about.text});
      } else {
        String imageLink = await _cloudStoreDataManagement.saveFileAndGetLink(
            imagePath, 'profile_image');
        currentUserDocument.update({'profile_pic': imageLink});
      }

      await getCurrentUserProfileData();
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error in : $e');
    }
  }

  @override
  void initState() {
    getCurrentUserProfileData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double heigth = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
        body: LoadingOverlay(
      isLoading: isLoading,
      child: ListView(
        children: [
          personalImageCard(heigth, width),
          userInfo("About", "$currentUserAbout"),
          SizedBox(
            height: 15,
          ),
          userInfo(
              "Email",
              widget.userEmail == ''
                  ? FirebaseAuth.instance.currentUser!.email.toString()
                  : widget.userEmail.toString()),
          SizedBox(
            height: 15,
          ),
          userInfo("Join Date", currentUserJoinDate),
          SizedBox(
            height: 15,
          ),
          userInfo("Join Time", currentUserJoinTime),
          SizedBox(
            height: 15,
          ),
        ],
      ),
    ));
  }

  personalImageCard(double heigth, double width) {
    return Container(
        alignment: Alignment.topCenter,
        height: MediaQuery.of(context).orientation == Orientation.portrait
            ? heigth / 2.5
            : width / 2.5,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            widget.userEmail == ''
                ? Padding(
                    padding: const EdgeInsets.only(
                      left: 250,
                    ),
                    child: ElevatedButton(
                      child: Text('Log Out'),
                      onPressed: () async {
                        setState(() {
                          isLoading = true;
                        });
                        final bool googleResponse =
                            await this._googleAuthentication.logOut();

                        if (!googleResponse) {
                          final bool fbResponse =
                              await this._facebookAuthentication.logOut();

                          if (!fbResponse) {
                            await FirebaseAuth.instance.signOut();
                          }
                        }
                        Navigator.of(context).pushReplacementNamed("main");
                      },
                    ),
                  )
                : Center(),
            Stack(children: [
              InkWell(
                onTap: () {
                  if (currentUserImage != '')
                    openProfileImage(currentUserImage);
                },
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: currentUserImage == ''
                      ? Image.asset("assets/profile.png")
                      : Container(
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: NetworkImage(
                                  currentUserImage,
                                ),
                                fit: BoxFit.cover,
                              )),
                        ),
                  radius:
                      MediaQuery.of(context).orientation == Orientation.portrait
                          ? width / 4
                          : heigth / 4,
                ),
              ),
              widget.userEmail == ''
                  ? Positioned(
                      bottom: 0, right: 0, child: editProfileImage(heigth))
                  : SizedBox()
            ]),
            Text(
              "$currentUserName",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ));
  }

  openProfileImage(String imagePath) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ImageViewScreen(imagePath: imagePath)));
  }

  editProfileImage(height) {
    return InkWell(
      child: Image.asset(
        'assets/camera.png',
        height: 50,
        width: 50,
      ),
      onTap: () {
        showModalBottomSheet(
            context: context,
            builder: (context) {
              return Container(
                height: height / 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text("Take Image :",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w500)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        takeImageButton(
                          color: Colors.purpleAccent,
                          icon: Icons.image,
                          mediaType: "Gallery",
                          onPressed: () async {
                            final XFile? pickedImage =
                                await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                            );

                            if (pickedImage != null) {
                              editMyProfile(pickedImage.path);
                            }
                          },
                        ),
                        takeImageButton(
                          color: Colors.redAccent,
                          icon: Icons.camera,
                          mediaType: "Camera",
                          onPressed: () async {
                            final XFile? pickedImage = await ImagePicker()
                                .pickImage(
                                    source: ImageSource.camera,
                                    imageQuality: 50);
                            if (pickedImage != null) {
                              editMyProfile(pickedImage.path);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            });
      },
    );
  }

  Widget takeImageButton(
      {required Color color,
      Function()? onPressed,
      required IconData icon,
      required String mediaType}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Card(
          color: color,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: Colors.white,
            ),
          ),
        ),
        Text(mediaType)
      ],
    );
  }

  Widget userInfo(
    String _title,
    String _subtitle,
  ) {
    return ListTile(
      title: Text(_title),
      subtitle: Text(_subtitle),
      trailing: _title == "About"
          ? widget.userEmail == ''
              ? IconButton(
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Edit :'),
                            content: TextFormField(
                              maxLength: 200,
                              minLines: 3,
                              maxLines: 5,
                              controller: _about,
                            ),
                            actions: [
                              TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(
                                    "Cancel",
                                    style: TextStyle(color: Colors.green),
                                  )),
                              TextButton(
                                  onPressed: () {
                                    editMyProfile('');
                                  },
                                  child: Text(
                                    "Save",
                                    style: TextStyle(color: Colors.blueGrey),
                                  ))
                            ],
                          );
                        });
                  },
                  icon: Icon(Icons.edit))
              : SizedBox()
          : SizedBox(),
    );
  }
}
