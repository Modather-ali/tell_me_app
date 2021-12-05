import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hadithni/Backend/firebase/cloud_data_management.dart';
import 'package:hadithni/app_screens/Global_Uses/enums.dart';
import 'package:loading_overlay/loading_overlay.dart';

class SearchScreen extends StatefulWidget {
  SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Map<String, dynamic>> _availableUsers = [];
  List<Map<String, dynamic>> _sortedAvailableUsers = [];
  List<dynamic> _myConnectionRequestCollection = [];

  bool isLoading = false;

  final CloudStoreDataManagement _cloudStoreDataManagement =
      CloudStoreDataManagement();

  Future<void> _initialDataFetchAndCheckUp() async {
    if (mounted) {
      setState(() {
        this.isLoading = true;
      });
    }

    final List<Map<String, dynamic>> takeUsers =
        await _cloudStoreDataManagement.getAllUsersListExceptMyAccount(
            currentUserEmail:
                FirebaseAuth.instance.currentUser!.email.toString());

    final List<Map<String, dynamic>> takeUsersAfterSorted = [];

    if (mounted) {
      setState(() {
        takeUsers.forEach((element) {
          if (mounted) {
            setState(() {
              takeUsersAfterSorted.add(element);
            });
          }
        });
      });
    }

    final List<dynamic> _connectionRequestList =
        await _cloudStoreDataManagement.currentUserConnectionRequestList(
            email: FirebaseAuth.instance.currentUser!.email.toString());

    if (mounted) {
      setState(() {
        this._availableUsers = takeUsers;
        this._sortedAvailableUsers = takeUsersAfterSorted;
        this._myConnectionRequestCollection = _connectionRequestList;
      });
    }

    if (mounted) {
      setState(() {
        this.isLoading = false;
      });
    }
  }

  @override
  void initState() {
    _initialDataFetchAndCheckUp();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Available Connections :",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: LoadingOverlay(
        isLoading: isLoading,
        child: ListView(
          children: [
            Container(
              width: double.maxFinite,
              margin: EdgeInsets.all(20),
              child: TextField(
                autofocus: true,
                style: TextStyle(color: Colors.grey),
                decoration: InputDecoration(
                  hintText: 'Search User Name',
                  hintStyle: TextStyle(color: Colors.grey),
                  focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(width: 2.0, color: Colors.lightBlue)),
                  enabledBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(width: 2.0, color: Colors.lightBlue)),
                ),
                onChanged: (writeText) {
                  if (mounted) {
                    setState(() {
                      this.isLoading = true;
                    });
                  }

                  if (mounted) {
                    setState(() {
                      this._sortedAvailableUsers.clear();

                      print('Available Users: ${this._availableUsers}');

                      this._availableUsers.forEach((userNameMap) {
                        if (userNameMap.values.first
                            .toString()
                            .toLowerCase()
                            .startsWith('${writeText.toLowerCase()}'))
                          this._sortedAvailableUsers.add(userNameMap);
                      });
                    });
                  }

                  print(this._sortedAvailableUsers);

                  if (mounted) {
                    setState(() {
                      this.isLoading = false;
                    });
                  }
                },
              ),
            ),
            ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: this._sortedAvailableUsers.length,
                itemBuilder: (context, index) {
                  return _availableConnectionsList(index);
                }),
          ],
        ),
      ),
    );
  }

  _availableConnectionsList(int index) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, left: 15, right: 15),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      this
                          ._availableUsers[index]
                          .values
                          .first
                          .toString()
                          .split("[user-name-about-divider]")[0],
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      this
                          ._availableUsers[index]
                          .values
                          .first
                          .toString()
                          .split("[user-name-about-divider]")[1],
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    )
                  ],
                ),
              ),
              TextButton(
                  style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100.0),
                        side: BorderSide(
                            color: _getRelevantButtonConfig(
                                connectionStateType:
                                    ConnectionStateType.ButtonBorderColor,
                                index: index)),
                      )),
                  child: _getRelevantButtonConfig(
                      connectionStateType: ConnectionStateType.ButtonNameWidget,
                      index: index),
                  onPressed: () async {
                    final String buttonName = _getRelevantButtonConfig(
                        connectionStateType: ConnectionStateType.ButtonOnlyName,
                        index: index);

                    if (mounted) {
                      setState(() {
                        this.isLoading = true;
                      });
                    }

                    if (buttonName == ConnectionStateName.Connect.toString()) {
                      if (mounted) {
                        setState(() {
                          this._myConnectionRequestCollection.add({
                            this
                                    ._sortedAvailableUsers[index]
                                    .keys
                                    .first
                                    .toString():
                                OtherConnectionStatus.Request_Pending
                                    .toString(),
                          });
                        });
                      }

                      await _cloudStoreDataManagement.changeConnectionStatus(
                          oppositeUserMail: this
                              ._sortedAvailableUsers[index]
                              .keys
                              .first
                              .toString(),
                          currentUserMail: FirebaseAuth
                              .instance.currentUser!.email
                              .toString(),
                          connectionUpdatedStatus:
                              OtherConnectionStatus.Invitation_Came.toString(),
                          currentUserUpdatedConnectionRequest:
                              this._myConnectionRequestCollection);
                    } else if (buttonName ==
                        ConnectionStateName.Accept.toString()) {
                      if (mounted) {
                        setState(() {
                          this
                              ._myConnectionRequestCollection
                              .forEach((element) {
                            if (element.keys.first.toString() ==
                                this
                                    ._sortedAvailableUsers[index]
                                    .keys
                                    .first
                                    .toString()) {
                              this._myConnectionRequestCollection[this
                                  ._myConnectionRequestCollection
                                  .indexOf(element)] = {
                                this
                                        ._sortedAvailableUsers[index]
                                        .keys
                                        .first
                                        .toString():
                                    OtherConnectionStatus.Invitation_Accepted
                                        .toString(),
                              };
                            }
                          });
                        });
                      }

                      await _cloudStoreDataManagement.changeConnectionStatus(
                          storeDataAlsoInConnections: true,
                          oppositeUserMail: this
                              ._sortedAvailableUsers[index]
                              .keys
                              .first
                              .toString(),
                          currentUserMail: FirebaseAuth
                              .instance.currentUser!.email
                              .toString(),
                          connectionUpdatedStatus:
                              OtherConnectionStatus.Request_Accepted.toString(),
                          currentUserUpdatedConnectionRequest:
                              this._myConnectionRequestCollection);
                    }

                    if (mounted) {
                      setState(() {
                        this.isLoading = false;
                      });
                    }
                  }),
            ],
          ),
          Divider()
        ],
      ),
    );
  }

  dynamic _getRelevantButtonConfig(
      {required ConnectionStateType connectionStateType, required int index}) {
    bool _isUserPresent = false;
    String _storeStatus = '';

    this._myConnectionRequestCollection.forEach((element) {
      if (element.keys.first.toString() ==
          this._sortedAvailableUsers[index].keys.first.toString()) {
        _isUserPresent = true;
        _storeStatus = element.values.first.toString();
      }
    });

    if (_isUserPresent) {
      print('User Present in Connection List');

      if (_storeStatus == OtherConnectionStatus.Request_Pending.toString() ||
          _storeStatus == OtherConnectionStatus.Invitation_Came.toString()) {
        if (connectionStateType == ConnectionStateType.ButtonNameWidget)
          return Text(
            _storeStatus == OtherConnectionStatus.Request_Pending.toString()
                ? ConnectionStateName.Pending.toString()
                    .split(".")[1]
                    .toString()
                : ConnectionStateName.Accept.toString()
                    .split(".")[1]
                    .toString(),
            style: TextStyle(color: Colors.yellow),
          );
        else if (connectionStateType == ConnectionStateType.ButtonOnlyName)
          return _storeStatus ==
                  OtherConnectionStatus.Request_Pending.toString()
              ? ConnectionStateName.Pending.toString()
              : ConnectionStateName.Accept.toString();

        return Colors.yellow;
      } else {
        if (connectionStateType == ConnectionStateType.ButtonNameWidget)
          return Text(
            ConnectionStateName.Connected.toString().split(".")[1].toString(),
            style: TextStyle(color: Colors.green),
          );
        else if (connectionStateType == ConnectionStateType.ButtonOnlyName)
          return ConnectionStateName.Connected.toString();

        return Colors.green;
      }
    } else {
      print('User Not Present in Connection List');

      if (connectionStateType == ConnectionStateType.ButtonNameWidget)
        return Text(
          ConnectionStateName.Connect.toString().split(".")[1].toString(),
          style: TextStyle(color: Colors.lightBlue),
        );
      else if (connectionStateType == ConnectionStateType.ButtonOnlyName)
        return ConnectionStateName.Connect.toString();

      return Colors.lightBlue;
    }
  }
}
