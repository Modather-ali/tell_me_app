import 'dart:io';
import 'package:animations/animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hadithni/Backend/firebase/cloud_data_management.dart';
import 'package:hadithni/app_screens/Global_Uses/enums.dart';
import 'package:hadithni/app_screens/chat/helpful_screens/images_view.dart';
import 'package:hadithni/app_screens/chat/profile.dart';
import 'package:hadithni/theme.dart';
import 'package:just_audio/just_audio.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:photo_view/photo_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class ChatRoom extends StatefulWidget {
  final String userName;

  ChatRoom({
    Key? key,
    required this.userName,
  }) : super(key: key);

  @override
  _ChatRoomState createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  TextEditingController _textController = TextEditingController();
  bool isText = false;
  bool isLoading = false;
  String currentUserName = "";
  String conectedUserId = '';
  String conectedUserProfileImageLink = '';
  String imageUrl =
      'https://firebasestorage.googleapis.com/v0/b/hadithni.appspot.com/o/profile.png?alt=media&token=e5cc42a1-2182-4155-be7f-d83f76e87136';

  List<Map> messagesDataList = [];
  bool isSendre = true;

  final Record _record = Record();

  /// Some Integer Value Initialized
  late double _currAudioPlayingTime = 0.0;
  int _lastAudioPlayingIndex = 0;

  double _audioPlayingSpeed = 1.0;

  /// Audio Playing Time Related
  String _totalDuration = '0:00';
  String _loadingTime = '0:00';

  String _hintText = "Start Writeing";

  late Directory _audioDirectory;

  /// For Audio Player
  IconData _iconData = Icons.play_arrow_rounded;

  final AudioPlayer _justAudioPlayer = AudioPlayer();

  final CloudStoreDataManagement _cloudStoreDataManagement =
      CloudStoreDataManagement();

  final CollectionReference<Map<String, dynamic>> collectionReference =
      FirebaseFirestore.instance.collection("users");

  final String? currentUserEmail = FirebaseAuth.instance.currentUser!.email;

  getCurrentUserName() async {
    final DocumentReference<Map<String, dynamic>> currentUserDocument =
        collectionReference.doc("$currentUserEmail");

    final DocumentSnapshot<Map<String, dynamic>> getCurrentUserData =
        await currentUserDocument.get();

    final Map<String, dynamic>? currentUserData = getCurrentUserData.data();
    setState(() {
      currentUserName = currentUserData!['user_name'];
    });
    print("================ currentUserName is: $currentUserName =========");
  }

  getCurrentChatMessagesData() {
    final Stream<DocumentSnapshot<Map<String, dynamic>>> currentUserStream =
        collectionReference.doc(currentUserEmail).snapshots();

    currentUserStream.listen((event) {
      if (messagesDataList.isNotEmpty) {
        setState(() {
          messagesDataList.clear();
        });
      }
      for (var i = 0;
          i < event.data()!['messages_store'][widget.userName].length;
          i++) {
        setState(() {
          messagesDataList.add({
            'the_message': event.data()!['messages_store'][widget.userName][i]
                ['the_message'],
            'message_type': event.data()!['messages_store'][widget.userName][i]
                ['message_type'],
            'the_time': event.data()!['messages_store'][widget.userName][i]
                ['the_time'],
            'is_receiver': event.data()!['messages_store'][widget.userName][i]
                ['is_receiver'],
          });
        });

        print(
            "=============== message : ${messagesDataList[i]['the_message']} ===========");
      }
    });
  }

  _takePermissionForStorage() async {
    var status = await Permission.storage.request();
    await Permission.microphone.request();
    if (status == PermissionStatus.granted) {
      _makeDirectoryForRecordings();
    }
  }

  _makeDirectoryForRecordings() async {
    final Directory? directory = await getExternalStorageDirectory();

    _audioDirectory = await Directory(directory!.path + '/Recordings/')
        .create(); // This directory will create Once in whole Application
  }

  getConectedUserData() async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot =
        await collectionReference
            .where('user_name', isEqualTo: widget.userName)
            .get();
    querySnapshot.docs.forEach((element) {
      setState(() {
        conectedUserId = element.id.toString();
        conectedUserProfileImageLink = element.get('profile_pic');
      });
      print("User Id : ${element.id}");
    });
  }

  @override
  void initState() {
    _takePermissionForStorage();

    getCurrentUserName();

    getCurrentChatMessagesData();

    getConectedUserData();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: _appBar(),
      body: LoadingOverlay(
          isLoading: isLoading,
          child: Column(children: [
            Expanded(
                child: Container(
              child: ListView.builder(
                  physics: PageScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: messagesDataList.length,
                  itemBuilder: (itemBuilderContext, index) {
                    if (messagesDataList[index]['message_type'] ==
                        ChatMessageTypes.Text.toString()) {
                      return _textConversationManagement(
                          itemBuilderContext, index);
                    } else if (messagesDataList[index]['message_type'] ==
                        ChatMessageTypes.Image.toString())
                      return imagesView(itemBuilderContext, index);
                    else if (messagesDataList[index]['message_type'] ==
                        ChatMessageTypes.Audio.toString())
                      return _audioConversationManagement(
                          itemBuilderContext, index);

                    return Center(child: Text("Start the First message"));
                  }),
            )),
            _myBottomSheet()
          ])),
    ));
  }

  AppBar _appBar() {
    return AppBar(
      leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
          )),
      backgroundColor: Colors.white,
      title: Text(
        widget.userName,
        style: TextStyle(color: Colors.black),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 10),
          child: InkWell(
            child: CircleAvatar(
              foregroundImage: conectedUserProfileImageLink == ''
                  ? NetworkImage(imageUrl)
                  : NetworkImage(conectedUserProfileImageLink),
            ),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => UserProfile(
                        userEmail: conectedUserId,
                      )));
            },
          ),
        )
      ],
    );
  }

  Widget _myBottomSheet() {
    return Container(
      height: 80,
      width: double.infinity,
      margin: EdgeInsets.all(12),
      padding: EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: Colors.grey[400],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Padding(
              padding: EdgeInsets.only(left: 12, right: 10),
              child: InkWell(
                  onTap: _sendMedia, child: Icon(Icons.file_upload_sharp))),
          Expanded(
              child: SizedBox(
                  height: 70,
                  width: double.maxFinite,
                  child: TextFormField(
                    decoration: InputDecoration(
                        hintStyle: _hintText == "Start Writeing"
                            ? null
                            : TextStyle(color: Colors.red),
                        hintText: _hintText,
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black))),
                    maxLines: null,
                    controller: _textController,
                    onChanged: (text) {
                      bool _isEmpty = false;
                      text.isEmpty ? _isEmpty = true : _isEmpty = false;
                      setState(() {
                        isText = !_isEmpty;
                      });
                    },
                  ))),
          Container(
            margin: EdgeInsets.only(right: 15, left: 10),
            child: InkWell(
                onTap: isText ? _sendText : takeVoiceRecording,
                child:
                    Icon(isText ? Icons.send : Icons.keyboard_voice_rounded)),
          )
        ],
      ),
    );
  }

  void _sendMedia() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              "send media from your dvice:",
              style: TextStyle(fontSize: 15.0, color: Colors.grey),
            ),
            content: Container(
                height: MediaQuery.of(context).size.height / 4.5,
                width: MediaQuery.of(context).size.width / 2,
                child: ListView(physics: PageScrollPhysics(), children: [
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          sendMediaButton(
                            buttonColor: Colors.purpleAccent,
                            icon: Icons.image,
                            mediaType: "Gallery",
                            onPressed: () async {
                              final XFile? pickedImage =
                                  await ImagePicker().pickImage(
                                source: ImageSource.gallery,
                              );

                              if (pickedImage != null) {
                                _addSelectedImageToChat(pickedImage.path);
                              }
                            },
                          ),
                          sendMediaButton(
                            buttonColor: Colors.redAccent,
                            icon: Icons.camera,
                            mediaType: "Camera",
                            onPressed: () async {
                              final XFile? pickedImage = await ImagePicker()
                                  .pickImage(
                                      source: ImageSource.camera,
                                      imageQuality: 50);
                              if (pickedImage != null) {
                                _addSelectedImageToChat(pickedImage.path);
                              }
                            },
                          ),
                        ],
                      ),
                      sendMediaButton(
                          buttonColor: Colors.blueAccent,
                          icon: Icons.music_note_sharp,
                          mediaType: "Music",
                          onPressed: () async {
                            final FilePickerResult? _audioFilePickerResult =
                                await FilePicker.platform.pickFiles(
                              type: FileType.audio,
                            );

                            Navigator.pop(context);

                            if (_audioFilePickerResult != null) {
                              _audioFilePickerResult.files.forEach((element) {
                                _voiceAndAudioSend(element.path.toString());
                              });
                            }
                          })
                    ],
                  ),
                ])),
          );
        });
  }

  void _sendText() async {
    if (this.isText) {
      if (mounted) {
        setState(() {
          this.isLoading = true;
        });
      }

      final String _messageTime =
          "${DateTime.now().hour}:${DateTime.now().minute}";

      await _cloudStoreDataManagement.sendMessageToConnection(
          receiverName: widget.userName,
          messageData: _textController.text,
          chatMessageTypes: ChatMessageTypes.Text.toString(),
          theTime: _messageTime);

      await _cloudStoreDataManagement.receiveMessageFromConnection(
          senderName: currentUserName,
          receiverName: widget.userName,
          messageData: _textController.text,
          chatMessageTypes: ChatMessageTypes.Text.toString(),
          theTime: _messageTime);

      if (mounted) {
        setState(() {
          this._textController.clear();
          this.isLoading = false;
          this.isText = false;
        });
      }
    }
  }

  void takeVoiceRecording() async {
    if (!await Permission.microphone.status.isGranted) {
      final microphoneStatus = await Permission.microphone.request();
      if (microphoneStatus != PermissionStatus.granted) {
        print('Microphone permission is request!');
      }
    } else {
      if (await this._record.isRecording()) {
        if (mounted) {
          setState(() {
            _hintText = "Start Writeing";
          });
        }
        final String? recordedFilePath = await this._record.stop();

        _voiceAndAudioSend(recordedFilePath.toString());
      } else {
        if (mounted) {
          setState(() {
            _hintText = '🎙️ Recording...';
          });
        }

        await this
            ._record
            .start(
              path: '${_audioDirectory.path}${DateTime.now()}.aac',
            )
            .then((value) => print("Recording"));
      }
    }
  }

  void _voiceAndAudioSend(
    String recordedFilePath,
  ) async {
    await SystemChannels.textInput.invokeMethod('TextInput.hide');

    if (_justAudioPlayer.duration != null) {
      if (mounted) {
        setState(() {
          _justAudioPlayer.stop();
          _iconData = Icons.play_arrow_rounded;
        });
      }
    }

    await _justAudioPlayer.setFilePath(recordedFilePath);

    if (mounted) {
      setState(() {
        this.isLoading = true;
      });
    }

    final String _messageTime =
        "${DateTime.now().hour}:${DateTime.now().minute}";

    String audioLink = await _cloudStoreDataManagement.saveFileAndGetLink(
        recordedFilePath, 'audios');

    await _cloudStoreDataManagement.sendMessageToConnection(
        receiverName: widget.userName,
        messageData: audioLink,
        chatMessageTypes: ChatMessageTypes.Audio.toString(),
        theTime: _messageTime);

    await _cloudStoreDataManagement.receiveMessageFromConnection(
        senderName: currentUserName,
        receiverName: widget.userName,
        messageData: audioLink,
        chatMessageTypes: ChatMessageTypes.Audio.toString(),
        theTime: _messageTime);

    if (mounted) {
      setState(() {
        this.isLoading = false;
      });
    }
  }

  Widget sendMediaButton(
      {Function()? onPressed,
      required IconData icon,
      required String mediaType,
      required Color buttonColor}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Card(
          color: buttonColor,
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

  Widget _timeReFormat(String _willReturnTime) {
    return Text(
      _willReturnTime,
      style: const TextStyle(color: Colors.lightBlue),
    );
  }

  Widget _textConversationManagement(
      BuildContext itemBuilderContext, int index) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          alignment: messagesDataList[index]['is_receiver']
              ? Alignment.centerLeft
              : Alignment.centerRight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              primary: messagesDataList[index]['is_receiver']
                  ? Color(0xFFadb5bd)
                  : kSecondaryColor,
              elevation: 0.0,
              padding: EdgeInsets.all(10.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: messagesDataList[index]['is_receiver']
                      ? Radius.circular(0.0)
                      : Radius.circular(20.0),
                  topRight: messagesDataList[index]['is_receiver']
                      ? Radius.circular(20.0)
                      : Radius.circular(0.0),
                  bottomLeft: Radius.circular(20.0),
                  bottomRight: Radius.circular(20.0),
                ),
              ),
            ),
            child: Text(
              messagesDataList[index]['the_message'],
              style: TextStyle(fontSize: 13.5, color: Colors.white),
            ),
            onPressed: () {},
            onLongPress: () {},
          ),
        ),
        _conversationMessageTime(
            messagesDataList[index]['the_time'].toString(), index),
      ],
    );
  }

  Widget _conversationMessageTime(String time, int index) {
    return Container(
      alignment: messagesDataList[index]['is_receiver']
          ? Alignment.centerLeft
          : Alignment.centerRight,
      margin: messagesDataList[index]['is_receiver']
          ? const EdgeInsets.only(
              left: 5.0,
              bottom: 5.0,
              top: 5.0,
            )
          : const EdgeInsets.only(
              right: 5.0,
              bottom: 5.0,
              top: 5.0,
            ),
      child: _timeReFormat(time),
    );
  }

  Widget _audioConversationManagement(
      BuildContext itemBuilderContext, int index) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        GestureDetector(
          onLongPress: () async {},
          child: Container(
            margin: messagesDataList[index]['is_receiver']
                ? EdgeInsets.only(
                    right: MediaQuery.of(context).size.width / 3,
                    left: 5.0,
                    top: 5.0,
                  )
                : EdgeInsets.only(
                    left: MediaQuery.of(context).size.width / 3,
                    right: 5.0,
                    top: 5.0,
                  ),
            alignment: messagesDataList[index]['is_receiver']
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: Container(
              height: 70.0,
              width: 250.0,
              decoration: BoxDecoration(
                color: messagesDataList[index]['is_receiver']
                    ? Color(0xFFadb5bd)
                    : kSecondaryColor,
                borderRadius: messagesDataList[index]['is_receiver']
                    ? BorderRadius.only(
                        topRight: Radius.circular(40.0),
                        bottomLeft: Radius.circular(40.0),
                        bottomRight: Radius.circular(40.0),
                      )
                    : BorderRadius.only(
                        topLeft: Radius.circular(40.0),
                        bottomLeft: Radius.circular(40.0),
                        bottomRight: Radius.circular(40.0),
                      ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 20.0,
                  ),
                  GestureDetector(
                    onLongPress: () => _chatMicrophoneOnLongPressAction(),
                    onTap: () => chatMicrophoneOnTapAction(index),
                    child: Icon(
                      index == _lastAudioPlayingIndex
                          ? _iconData
                          : Icons.play_arrow_rounded,
                      color: Color.fromRGBO(10, 255, 30, 1),
                      size: 35.0,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 5.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            margin: EdgeInsets.only(
                              top: 26.0,
                            ),
                            child: LinearPercentIndicator(
                              percent: _justAudioPlayer.duration == null
                                  ? 0.0
                                  : _lastAudioPlayingIndex == index
                                      ? _currAudioPlayingTime /
                                                  _justAudioPlayer
                                                      .duration!.inMicroseconds
                                                      .ceilToDouble() <=
                                              1.0
                                          ? _currAudioPlayingTime /
                                              _justAudioPlayer
                                                  .duration!.inMicroseconds
                                                  .ceilToDouble()
                                          : 0.0
                                      : 0,
                              backgroundColor: Colors.black26,
                              progressColor: messagesDataList[index]
                                      ['is_receiver']
                                  ? Colors.lightBlue
                                  : Colors.pinkAccent,
                            ),
                          ),
                          SizedBox(
                            height: 10.0,
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 10.0, right: 7.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _lastAudioPlayingIndex == index
                                          ? _loadingTime
                                          : '0:00',
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      _lastAudioPlayingIndex == index
                                          ? _totalDuration
                                          : '',
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 15.0),
                    child: GestureDetector(
                      child: Text(
                        '${this._audioPlayingSpeed.toString().contains('.0') ? this._audioPlayingSpeed.toString().split('.')[0] : this._audioPlayingSpeed}x',
                        style: TextStyle(color: Colors.white, fontSize: 18.0),
                      ),
                      onTap: () {
                        print('Audio Play Speed Tapped');
                        if (mounted) {
                          setState(() {
                            if (this._audioPlayingSpeed != 3.0)
                              this._audioPlayingSpeed += 0.5;
                            else
                              this._audioPlayingSpeed = 1.0;

                            _justAudioPlayer.setSpeed(this._audioPlayingSpeed);
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _conversationMessageTime(messagesDataList[index]['the_time'], index),
      ],
    );
  }

  void chatMicrophoneOnTapAction(int index) async {
    try {
      _justAudioPlayer.positionStream.listen((event) {
        if (mounted) {
          setState(() {
            _currAudioPlayingTime = event.inMicroseconds.ceilToDouble();
            _loadingTime =
                '${event.inMinutes} : ${event.inSeconds > 59 ? event.inSeconds % 60 : event.inSeconds}';
          });
        }
      });

      _justAudioPlayer.playerStateStream.listen((event) {
        if (event.processingState == ProcessingState.completed) {
          _justAudioPlayer.stop();
          if (mounted) {
            setState(() {
              this._loadingTime = '0:00';
              this._iconData = Icons.play_arrow_rounded;
            });
          }
        }
      });

      if (_lastAudioPlayingIndex != index) {
        await _justAudioPlayer.setUrl(messagesDataList[index]['the_message']);

        if (mounted) {
          setState(() {
            _lastAudioPlayingIndex = index;
            _totalDuration =
                '${_justAudioPlayer.duration!.inMinutes} : ${_justAudioPlayer.duration!.inSeconds > 59 ? _justAudioPlayer.duration!.inSeconds % 60 : _justAudioPlayer.duration!.inSeconds}';
            _iconData = Icons.pause;
          });
        }

        await _justAudioPlayer.play();
      } else {
        print(_justAudioPlayer.processingState);
        if (_justAudioPlayer.processingState == ProcessingState.idle) {
          await _justAudioPlayer.setUrl(messagesDataList[index]['the_message']);

          if (mounted) {
            setState(() {
              _lastAudioPlayingIndex = index;
              _totalDuration =
                  '${_justAudioPlayer.duration!.inMinutes} : ${_justAudioPlayer.duration!.inSeconds}';
              _iconData = Icons.pause;
            });
          }

          await _justAudioPlayer.play();
        } else if (_justAudioPlayer.playing) {
          if (mounted) {
            setState(() {
              _iconData = Icons.play_arrow_rounded;
            });
          }

          await _justAudioPlayer.pause();
        } else if (_justAudioPlayer.processingState == ProcessingState.ready) {
          if (mounted) {
            setState(() {
              _iconData = Icons.pause;
            });
          }

          await _justAudioPlayer.play();
        } else if (_justAudioPlayer.processingState ==
            ProcessingState.completed) {}
      }
    } catch (e) {
      print('Audio Playing Error');
    }
  }

  void _chatMicrophoneOnLongPressAction() async {
    if (_justAudioPlayer.playing) {
      await _justAudioPlayer.stop();

      if (mounted) {
        setState(() {
          print('Audio Play Completed');
          _justAudioPlayer.stop();
          if (mounted) {
            setState(() {
              _loadingTime = '0:00';
              _iconData = Icons.play_arrow_rounded;
              _lastAudioPlayingIndex = -1;
            });
          }
        });
      }
    }
  }

  Widget imagesView(BuildContext itemBuilderContext, int index) {
    return Column(
      children: [
        Container(
            height: MediaQuery.of(context).size.height * 0.3,
            margin: messagesDataList[index]['is_receiver']
                ? EdgeInsets.only(
                    right: MediaQuery.of(context).size.width / 3,
                    left: 5.0,
                    top: 30.0,
                  )
                : EdgeInsets.only(
                    left: MediaQuery.of(context).size.width / 3,
                    right: 5.0,
                    top: 15.0,
                  ),
            alignment: messagesDataList[index]['is_receiver']
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: OpenContainer(
              openColor: const Color.fromRGBO(60, 80, 100, 1),
              closedColor: messagesDataList[index]['is_receiver']
                  ? const Color.fromRGBO(60, 80, 100, 1)
                  : const Color.fromRGBO(102, 102, 255, 1),
              middleColor: Color.fromRGBO(60, 80, 100, 1),
              closedElevation: 0.0,
              closedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              transitionDuration: Duration(
                milliseconds: 400,
              ),
              transitionType: ContainerTransitionType.fadeThrough,
              openBuilder: (context, openWidget) {
                return ImageViewScreen(
                  imagePath: messagesDataList[index]['the_message'],
                );
              },
              closedBuilder: (context, closeWidget) => Container(
                alignment: Alignment.center,
                child: PhotoView(
                  imageProvider: NetworkImage(
                    messagesDataList[index]['the_message'],
                  ),
                  loadingBuilder: (context, event) => Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorBuilder: (context, obj, stackTrace) => Center(
                      child: Text(
                    'Image not Found',
                    style: TextStyle(
                      fontSize: 23.0,
                      color: Colors.red,
                      fontFamily: 'Lora',
                      letterSpacing: 1.0,
                    ),
                  )),
                  enableRotation: true,
                  minScale: PhotoViewComputedScale.covered,
                ),
              ),
            )),
        _conversationMessageTime(messagesDataList[index]['the_time'], index),
      ],
    );
  }

  void _addSelectedImageToChat(
    String imagePath,
  ) async {
    Navigator.pop(context);
    if (mounted) {
      setState(() {
        this.isLoading = true;
      });
    }

    final String _messageTime =
        "${DateTime.now().hour}:${DateTime.now().minute}";
    String imageLink =
        await _cloudStoreDataManagement.saveFileAndGetLink(imagePath, 'images');

    await _cloudStoreDataManagement.sendMessageToConnection(
        receiverName: widget.userName,
        messageData: imageLink,
        chatMessageTypes: ChatMessageTypes.Image.toString(),
        theTime: _messageTime);

    await _cloudStoreDataManagement.receiveMessageFromConnection(
        senderName: currentUserName,
        receiverName: widget.userName,
        messageData: imageLink,
        chatMessageTypes: ChatMessageTypes.Image.toString(),
        theTime: _messageTime);

    if (mounted) {
      setState(() {
        this.isLoading = false;
      });
    }
  }
}
