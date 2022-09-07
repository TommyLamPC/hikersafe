import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'dart:async';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'qr_scan.dart';

class AddFriendPage extends StatefulWidget {
  const AddFriendPage({Key? key}) : super(key: key);

  @override
  _AddFriendPageState createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final user = FirebaseAuth.instance.currentUser;
  var id = "iLoveHiking@gmail.com";

  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;

  var txt = TextEditingController();

  String lang = "en";

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

  @override
  void initState() {
    // TODO: implement initState
    // id = user!.email!;
    super.initState();
    getLanguage();
    setState(() {
      id = user!.email!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: Text(lang == "en" ? "Add Friend" : "新增好友"),
      ),
      body: SingleChildScrollView(
        child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding:
                  const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    child: Column(
                      children: [
                        Text(
                          lang == "en" ? "Your ID:" : "你的ID:",
                          style: TextStyle(
                            // color: Colors.white,
                            fontSize: 20,
                            fontFamily: "OpenSan",
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user!.email!,
                          style: TextStyle(
                            // color: Colors.white,
                            fontSize: 20,
                            fontFamily: "OpenSan",
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        QrImage(
                          data: id,
                          version: QrVersions.auto,
                          // embeddedImage: Image.network(user!.photoURL!).image,
                          // size: 200.0,
                        ),
                        const Divider(color: Colors.black),
                        TextFormField(
                          controller: txt,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: lang == "en" ? 'Friends ID' : "朋友ID",
                          ),
                        ),
                        Text(
                          "OR",
                          style: TextStyle(
                            // color: Colors.white,
                            fontSize: 40,
                            fontFamily: "OpenSan",
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () async {
                              final returnValue = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => QrScanPage()),
                              );
                              setState(() {
                                txt.text = returnValue;
                              });
                              print(txt.text);
                            },
                            child: Text(
                                lang == "en" ? "Scan QR Code" : "掃描QR Code"),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.green,
                              primary: Colors.black,
                              textStyle: const TextStyle(
                                fontSize: 40,
                                fontFamily: "OpenSan",
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    color: Colors.black,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () async {
                        if (txt.text.toLowerCase() != user!.email) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .where('email', isEqualTo: txt.text.toLowerCase())
                              .get()
                              .then((value) async {
                            if (value.docs.length == 1) {
                              var notification = value.docs[0]['notification'];
                              bool doTask = true;
                              bool added = false;
                              value.docs[0]['friends'].forEach((result) {
                                if (result == user!.email) {
                                  doTask = false;
                                  added = true;
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: Text(
                                              lang == "en" ? "Failed!" : "失敗"),
                                          content: Text(lang == "en"
                                              ? "This friend already in your friend list!"
                                              : "他已經在你的朋友名單了！"),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                print(txt.text);
                                                Navigator.pop(context);
                                              },
                                              child: Text(
                                                  lang == "en" ? "OK" : "好"),
                                            ),
                                          ],
                                        );
                                      });
                                } else {
                                  if (notification.length <= 0) {
                                  } else {
                                    notification.forEach((val) {
                                      if (val['senderId'] == user!.uid &&
                                          val['type'] == "FR") {
                                        print(
                                            'the request already sended before!');
                                        doTask = false;
                                      }
                                    });
                                  }
                                }
                              });
                              if (doTask) {
                                notification.add({
                                  'title': 'Friend Request!',
                                  'desc':
                                      '${user!.displayName} want to add you as friend!\nDo you accept?',
                                  'type': 'FR',
                                  'senderId': user!.uid
                                });
                                await FirebaseFirestore.instance
                                    .collection("users")
                                    .doc(value.docs[0].id)
                                    .update({'notification': notification});
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text(lang == "en"
                                            ? "Successfully!"
                                            : "成功"),
                                        content: Text(lang == "en"
                                            ? "The friend request is sended!"
                                            : "朋友申請已經發送！"),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: Text("OK"),
                                          ),
                                        ],
                                      );
                                    });
                              } else if (!added) {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text(
                                            lang == "en" ? "Failed!" : "失敗"),
                                        content: Text(lang == "en"
                                            ? "You can't send a friend request repeatedly!"
                                            : "你無法重新發送好友申請！"),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              print(txt.text);
                                              Navigator.pop(context);
                                            },
                                            child:
                                                Text(lang == "en" ? "OK" : "好"),
                                          ),
                                        ],
                                      );
                                    });
                              }
                            } else {
                              // no this account
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title:
                                          Text(lang == "en" ? "Failed!" : "失敗"),
                                      content: Text(lang == "en"
                                          ? "The account is not exist!"
                                          : "帳戶不存在！"),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            print(txt.text);
                                            Navigator.pop(context);
                                          },
                                          child:
                                              Text(lang == "en" ? "OK" : "好"),
                                        ),
                                      ],
                                    );
                                  });
                            }
                          });
                        } else {
                          showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text(lang == "en" ? "Failed!" : "失敗"),
                                  content: Text(lang == "en"
                                      ? "You can't add youself!"
                                      : "你無法新增自己為好友"),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        print(txt.text);
                                        Navigator.pop(context);
                                      },
                                      child: Text(lang == "en" ? "OK" : "好"),
                                    ),
                                  ],
                                );
                              });
                        }
                        txt.text = "";
                      },
                      child: Text(lang == "en" ? "Add Friend" : "新增好友"),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.lightBlueAccent,
                        primary: Colors.black,
                        textStyle: const TextStyle(
                          fontSize: 40,
                          fontFamily: "OpenSan",
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ),
    );
  }
}
