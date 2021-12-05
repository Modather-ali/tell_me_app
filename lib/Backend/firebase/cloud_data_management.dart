import 'dart:io';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:path/path.dart';

class CloudStoreDataManagement {
  final _collectionName = 'users';

  Future<bool> checkThisUserAlreadyPresentOrNot(
      {required String userName}) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> findResults =
          await FirebaseFirestore.instance
              .collection(_collectionName)
              .where('user_name', isEqualTo: userName)
              .get();

      print('Debug 1: ${findResults.docs.isEmpty}');

      return findResults.docs.isEmpty ? true : false;
    } catch (e) {
      print(
          'Error in Checkj This User Already Present or not: ${e.toString()}');
      return false;
    }
  }

  Future<bool> registerNewUser(
      {required String userName,
      required String userAbout,
      required String userEmail}) async {
    try {
      final String? _getToken = await FirebaseMessaging.instance.getToken();

      final String currDate = DateFormat('dd-MM-yyyy').format(DateTime.now());

      final String currTime = "${DateFormat('hh:mm a').format(DateTime.now())}";

      await FirebaseFirestore.instance.doc('$_collectionName/$userEmail').set({
        "about": userAbout,
        "activity": [],
        "connection_request": [],
        "messages_store": {},
        "creation_date": currDate,
        "creation_time": currTime,
        "profile_pic": "",
        "token": _getToken.toString(),
        "user_name": userName,
      });

      return true;
    } catch (e) {
      print('Error in Register new user: ${e.toString()}');
      return false;
    }
  }

  Future<bool> userRecordPresentOrNot({required String email}) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
          await FirebaseFirestore.instance
              .doc('${this._collectionName}/$email')
              .get();
      return documentSnapshot.exists;
    } catch (e) {
      print('Error in user Record Present or not: ${e.toString()}');
      return false;
    }
  }

  Future<Map<String, dynamic>> getTokenFromCloudStore(
      {required String userMail}) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
          await FirebaseFirestore.instance
              .doc('${this._collectionName}/$userMail')
              .get();

      print('DocumentSnapShot is: ${documentSnapshot.data()}');

      final Map<String, dynamic> importantData = Map<String, dynamic>();

      importantData["token"] = documentSnapshot.data()!["token"];
      importantData["date"] = documentSnapshot.data()!["creation_date"];
      importantData["time"] = documentSnapshot.data()!["creation_time"];

      return importantData;
    } catch (e) {
      print('Error in get Token from Cloud Store: ${e.toString()}');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsersListExceptMyAccount(
      {required String currentUserEmail}) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection(this._collectionName)
              .get();

      List<Map<String, dynamic>> _usersDataCollection = [];

      querySnapshot.docs.forEach(
          (QueryDocumentSnapshot<Map<String, dynamic>> queryDocumentSnapshot) {
        if (currentUserEmail != queryDocumentSnapshot.id)
          _usersDataCollection.add({
            queryDocumentSnapshot.id:
                '${queryDocumentSnapshot.get("user_name")}[user-name-about-divider]${queryDocumentSnapshot.get("about")}',
          });
      });

      print(_usersDataCollection);

      return _usersDataCollection;
    } catch (e) {
      print('Error in get All Users List: ${e.toString()}');
      return [];
    }
  }

  Future<Map<String, dynamic>?> _getCurrentAccountAllData(
      {required String email}) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
          await FirebaseFirestore.instance
              .doc('${this._collectionName}/$email')
              .get();

      return documentSnapshot.data();
    } catch (e) {
      print('Error in getCurrentAccountAll Data: ${e.toString()}');
      return {};
    }
  }

  Future<List<dynamic>> currentUserConnectionRequestList(
      {required String email}) async {
    try {
      Map<String, dynamic>? _currentUserData =
          await _getCurrentAccountAllData(email: email);

      final List<dynamic> _connectionRequestCollection =
          _currentUserData!["connection_request"];

      print('Collection: $_connectionRequestCollection');

      return _connectionRequestCollection;
    } catch (e) {
      print('Error in Current USer Collection List: ${e.toString()}');
      return [];
    }
  }

  Future<void> changeConnectionStatus({
    required String oppositeUserMail,
    required String currentUserMail,
    required String connectionUpdatedStatus,
    required List<dynamic> currentUserUpdatedConnectionRequest,
    bool storeDataAlsoInConnections = false,
  }) async {
    try {
      print('Come here');

      /// Opposite Connection database Update
      final DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
          await FirebaseFirestore.instance
              .doc('${this._collectionName}/$oppositeUserMail')
              .get();

      Map<String, dynamic>? map = documentSnapshot.data();

      print('Map: $map');

      List<dynamic> _oppositeConnectionsRequestsList =
          map!["connection_request"];

      int index = -1;

      _oppositeConnectionsRequestsList.forEach((element) {
        if (element.keys.first.toString() == currentUserMail)
          index = _oppositeConnectionsRequestsList.indexOf(element);
      });

      if (index > -1) _oppositeConnectionsRequestsList.removeAt(index);

      print('Opposite Connections: $_oppositeConnectionsRequestsList');

      _oppositeConnectionsRequestsList.add({
        currentUserMail: connectionUpdatedStatus,
      });

      print('Opposite Connections: $_oppositeConnectionsRequestsList');

      map["connection_request"] = _oppositeConnectionsRequestsList;
      await FirebaseFirestore.instance
          .doc('${this._collectionName}/$oppositeUserMail')
          .update(map);

      /// Current User Connection Database Update
      final Map<String, dynamic>? currentUserMap =
          await _getCurrentAccountAllData(email: currentUserMail);

      currentUserMap!["connection_request"] =
          currentUserUpdatedConnectionRequest;

      await FirebaseFirestore.instance
          .doc('${this._collectionName}/$currentUserMail')
          .update(currentUserMap);
    } catch (e) {
      print('Error in Change Connection Status: ${e.toString()}');
    }
  }

  Future<void> sendMessageToConnection(
      {required String receiverName,
      required String messageData,
      required String chatMessageTypes,
      required String theTime}) async {
    try {
      List oldMessages = [];
      Map message = {
        "the_message": messageData,
        "message_type": chatMessageTypes,
        "the_time": theTime,
        "is_receiver": false
      };

      final CollectionReference<Map<String, dynamic>> collectionReference =
          FirebaseFirestore.instance.collection(this._collectionName);

      final String? currentUserEmail = FirebaseAuth.instance.currentUser!.email;

      final DocumentReference<Map<String, dynamic>> currentUserDocument =
          collectionReference.doc("$currentUserEmail");

      final DocumentSnapshot<Map<String, dynamic>> getCurrentUserData =
          await currentUserDocument.get();

      final Map<String, dynamic>? currentUserData = getCurrentUserData.data();

      if (currentUserData!['messages_store'][receiverName] != null) {
        oldMessages = currentUserData['messages_store'][receiverName];
      }

      oldMessages.add(message);

      currentUserData['messages_store'][receiverName] = oldMessages;

      await currentUserDocument.update({
        "messages_store": currentUserData['messages_store']
      }).whenComplete(() {
        print("======= Complete ========");
      });
    } catch (e) {
      print('error in Send Data: ${e.toString()}');
    }
  }

  receiveMessageFromConnection(
      {required String senderName,
      required String receiverName,
      required String messageData,
      required String chatMessageTypes,
      required String theTime}) async {
    try {
      String receiverID = '';
      List oldMessages = [];
      Map message = {
        "the_message": messageData,
        "message_type": chatMessageTypes,
        "the_time": theTime,
        "is_receiver": true
      };

      final CollectionReference<Map<String, dynamic>> collectionReference =
          FirebaseFirestore.instance.collection(this._collectionName);

      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await collectionReference
              .where("user_name", isEqualTo: receiverName)
              .get();

      querySnapshot.docs.forEach((receiverDoc) {
        print("=================================");
        receiverID = receiverDoc.id;
        print(receiverID);
      });

      DocumentSnapshot<Map<String, dynamic>> getReceiverData =
          await collectionReference.doc(receiverID).get();
      Map<String, dynamic>? receiverData = getReceiverData.data();

      if (receiverData!['messages_store'][senderName] != null) {
        oldMessages = receiverData['messages_store'][senderName];
      }

      oldMessages.add(message);

      receiverData['messages_store'][senderName] = oldMessages;

      await collectionReference.doc(receiverID).update(
          {"messages_store": receiverData['messages_store']}).whenComplete(() {
        print("======= Complete ========");
      });
    } catch (e) {
      print('error in receive Data: ${e.toString()}');
    }
  }

  Future<String> saveFileAndGetLink(String filePath, String folderName) async {
    var randomNumber = Random().nextInt(1000000);
    File file = File(filePath);
    String fileName = basename(filePath);
    Reference firestore = FirebaseStorage.instance
        .ref(folderName)
        .child('$randomNumber&$fileName');
    await firestore.putFile(file);
    String url = await firestore.getDownloadURL();
    return url;
  }
}
