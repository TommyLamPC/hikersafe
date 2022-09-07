// import 'dart:ffi';

import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hikersafe/google_sign_in.dart';
import 'package:hikersafe/tracking_map.dart';
import 'package:hikersafe/translate.dart';
import 'package:hikersafe/translate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';
import 'home.dart';
import 'search_route.dart';
import 'social_media.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BottomNavigation extends StatefulWidget {
  BottomNavigation({Key? key}) : super(key: key);

  @override
  _BottomNavigationState createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  String lang = "en";
  int _currentIndex = 0;
  List notification = [];
  final pages = [HomePage(), SearchRoutePage(), SocialMediaPage()];
  final user = FirebaseAuth.instance.currentUser;

  getNotification() async {
    print("getNotification");
    FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .snapshots()
        .listen((event) {
      print(event);
      setState(() {
        notification = event['notification'];
      });
      print(notification);
      print("notification");
    });
  }

  @override
  void initState() {
    getLanguage();
    addUser();
    getNotification();

    super.initState();
  }

  addUser() async {
    final docUsers =
        FirebaseFirestore.instance.collection("users").doc(user!.uid);
    // try {
    docUsers.get().then((value) async {
      if (value.data() == null) {
        print("account doesn't exist!");
        await docUsers.set({
          'name': user!.displayName,
          'email': user!.email,
          'iconPic': user!.photoURL,
          'friends': [],
          'notification': [],
          'savedRoute': [],
          'trustedUser': ""
        });
      } else {
        print("account  exist!");
        await docUsers.update({
          'name': user!.displayName,
          'email': user!.email,
          'iconPic': user!.photoURL,
        });
      }
    });
    // } catch (e) {
    //   print("account doesn't exist!");
    //
    // }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.redAccent,
          title: Text("HikerSafe"),
          leading: IconButton(
              onPressed: () {
                final provider =
                    Provider.of<GoogleSignInProvider>(context, listen: false);
                provider.googleLogout();
                // showDialog(
                //   context: context,
                //   builder: (context) {
                //     return AlertDialog(
                //       title: Text(
                //           ""),
                //       content: ,
                //     );
                //   },
                // );
              },
              icon: Icon(Icons.logout)),
          actions: [
            IconButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(user!.uid)
                    .update({
                  'savedRoute': ['T3ok3cYHWZE4JVLK4zAg', 'BBAYCFXPxluNk6a4dKyN']
                });
              },
              icon: Icon(Icons.settings),
              color: Colors.redAccent,
            ),
            IconButton(
                onPressed: () async {
                  SharedPreferences pref =
                      await SharedPreferences.getInstance();
                  String? language = pref.getString('language');
                  if (language == "zh-tw") {
                    pref.setString('language', 'en');
                  } else {
                    pref.setString('language', 'zh-tw');
                  }
                  setState(() {
                    lang = pref.getString('language')!;
                  });
                },
                icon: Icon(Icons.translate)),
            if (notification.isNotEmpty)
              Stack(
                children: [
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: new BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                      ),
                      // constraints: BoxConstraints(
                      //   minWidth: 14,
                      //   minHeight: 14,
                      // ),
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Text(
                          "${notification.length}",
                          // "20",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.notifications),
                    onPressed: () async {
                      await showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (context) {
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return AlertDialog(
                                title:
                                    Text(lang == 'en' ? "Notification" : "通知"),
                                content: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      for (int i = 0;
                                          i < notification.length;
                                          i++)
                                        SizedBox(
                                          width: double.infinity,
                                          child: Card(
                                            color: Colors.white70,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    notification[i]['title'],
                                                    style: TextStyle(
                                                      // color: Colors.white,
                                                      fontSize: 20,
                                                      fontFamily: "OpenSan",
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(notification[i]['desc']),
                                                  if (notification[i]['type'] ==
                                                      "FR")
                                                    SizedBox(
                                                      width: double.infinity,
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            flex: 1,
                                                            child:
                                                                TextButton.icon(
                                                              style: TextButton
                                                                  .styleFrom(
                                                                primary: Colors
                                                                    .white,
                                                                backgroundColor:
                                                                    Colors
                                                                        .green,
                                                              ),
                                                              onPressed:
                                                                  () async {
                                                                showDialog(
                                                                  context:
                                                                      context,
                                                                  barrierDismissible:
                                                                      false,
                                                                  builder:
                                                                      (BuildContext
                                                                          context) {
                                                                    return AlertDialog(
                                                                      backgroundColor: Colors
                                                                          .white
                                                                          .withOpacity(
                                                                              0),
                                                                      content:
                                                                          Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        children: [
                                                                          new CircularProgressIndicator(),
                                                                        ],
                                                                      ),
                                                                    );
                                                                  },
                                                                );
                                                                var friendList =
                                                                    [];
                                                                await FirebaseFirestore
                                                                    .instance
                                                                    .collection(
                                                                        "users")
                                                                    .doc(user!
                                                                        .uid)
                                                                    .get()
                                                                    .then(
                                                                        (value) {
                                                                  friendList = value
                                                                          .data()![
                                                                      'friends'];
                                                                });
                                                                friendList.add(
                                                                    notification[
                                                                            i][
                                                                        'senderId']);
                                                                await FirebaseFirestore
                                                                    .instance
                                                                    .collection(
                                                                        "users")
                                                                    .doc(user!
                                                                        .uid)
                                                                    .update({
                                                                  'friends':
                                                                      friendList
                                                                });

                                                                friendList = [];
                                                                await FirebaseFirestore
                                                                    .instance
                                                                    .collection(
                                                                        "users")
                                                                    .doc(notification[
                                                                            i][
                                                                        'senderId'])
                                                                    .get()
                                                                    .then(
                                                                        (value) {
                                                                  friendList = value
                                                                          .data()![
                                                                      'friends'];
                                                                });
                                                                friendList.add(
                                                                    user!.uid);
                                                                await FirebaseFirestore
                                                                    .instance
                                                                    .collection(
                                                                        "users")
                                                                    .doc(notification[
                                                                            i][
                                                                        'senderId'])
                                                                    .update({
                                                                  'friends':
                                                                      friendList
                                                                });

                                                                notification
                                                                    .removeAt(
                                                                        i);
                                                                print(
                                                                    notification);
                                                                await FirebaseFirestore
                                                                    .instance
                                                                    .collection(
                                                                        "users")
                                                                    .doc(user!
                                                                        .uid)
                                                                    .update({
                                                                  'notification':
                                                                      notification
                                                                });
                                                                setState(() {
                                                                  getNotification();
                                                                });
                                                                Navigator.pop(
                                                                    context);
                                                              },
                                                              icon: Icon(
                                                                  Icons.check),
                                                              label: Text(
                                                                  lang == 'en'
                                                                      ? "Accept"
                                                                      : "接受"),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 1,
                                                            child:
                                                                TextButton.icon(
                                                              style: TextButton
                                                                  .styleFrom(
                                                                primary: Colors
                                                                    .white,
                                                                backgroundColor:
                                                                    Colors.red,
                                                              ),
                                                              onPressed:
                                                                  () async {
                                                                showDialog(
                                                                  context:
                                                                      context,
                                                                  barrierDismissible:
                                                                      false,
                                                                  builder:
                                                                      (BuildContext
                                                                          context) {
                                                                    return AlertDialog(
                                                                      backgroundColor: Colors
                                                                          .white
                                                                          .withOpacity(
                                                                              0),
                                                                      content:
                                                                          Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        children: [
                                                                          new CircularProgressIndicator(),
                                                                        ],
                                                                      ),
                                                                    );
                                                                  },
                                                                );
                                                                notification
                                                                    .removeAt(
                                                                        i);
                                                                await FirebaseFirestore
                                                                    .instance
                                                                    .collection(
                                                                        "users")
                                                                    .doc(user!
                                                                        .uid)
                                                                    .update({
                                                                  'notification':
                                                                      notification
                                                                });
                                                                setState(() {
                                                                  getNotification();
                                                                });
                                                                Navigator.pop(
                                                                    context);
                                                              },
                                                              icon: Icon(
                                                                  Icons.close),
                                                              label: Text(
                                                                  lang == 'en'
                                                                      ? "Reject"
                                                                      : "拒絕"),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  else if (notification[i]
                                                          ['type'] ==
                                                      "HN")
                                                    SizedBox(
                                                      width: double.infinity,
                                                      child: TextButton.icon(
                                                        style: TextButton
                                                            .styleFrom(
                                                          primary: Colors.white,
                                                          backgroundColor:
                                                              Colors.blue,
                                                        ),
                                                        onPressed: () async {
                                                          await FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                  'hiking')
                                                              .doc(notification[
                                                                      i]
                                                                  ['hikingId'])
                                                              .get()
                                                              .then((value) {
                                                            if (value.data() !=
                                                                null) {
                                                              Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                      builder: (context) =>
                                                                          TrackingMapPage(
                                                                            hikingId:
                                                                                notification[i]['hikingId'],
                                                                          )));
                                                            } else {
                                                              showDialog(
                                                                  barrierDismissible:
                                                                      false,
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (context) {
                                                                    return AlertDialog(
                                                                      title: Text(lang ==
                                                                              'en'
                                                                          ? "Failed!"
                                                                          : "失敗"),
                                                                      content: Text(lang ==
                                                                              'en'
                                                                          ? "The hiking is ended!"
                                                                          : "行山已結束"),
                                                                      actions: [
                                                                        TextButton(
                                                                            onPressed:
                                                                                () async {
                                                                              Navigator.pop(context);
                                                                              notification.removeAt(i);
                                                                              await FirebaseFirestore.instance.collection("users").doc(user!.uid).update({
                                                                                'notification': notification
                                                                              });
                                                                              setState(() {
                                                                                getNotification();
                                                                              });
                                                                            },
                                                                            child: Text(lang == 'en'
                                                                                ? "OK"
                                                                                : "好"))
                                                                      ],
                                                                    );
                                                                  });
                                                            }
                                                          });
                                                        },
                                                        icon: Icon(Icons.map),
                                                        label: Text(lang == 'en'
                                                            ? "Track"
                                                            : "跟隨"),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton.icon(
                                      onPressed: () {
                                        setState() {
                                          getNotification();
                                        }

                                        Navigator.pop(context);
                                      },
                                      icon: Icon(Icons.check),
                                      label: Text(lang == 'en' ? "OK" : "好"))
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
        body: pages[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: lang == 'en' ? "Home" : '家',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: lang == 'en' ? "Search Route" : '搜尋路線',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sms),
              label: lang == 'en' ? "Social" : '社交',
            ),
          ],
          currentIndex: _currentIndex,
          fixedColor: Colors.red,
          onTap: _onItemClick,
        ),
      ),
    );
  }

  void _onItemClick(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> getLanguage() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? language = pref.getString('language');
    if (language == "zh-tw") {
      lang = "zh-tw";
    } else {
      lang = 'en';
    }
    setState(() {});
  }
}
