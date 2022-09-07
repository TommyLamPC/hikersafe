import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class FriendListPage extends StatefulWidget {
  const FriendListPage({Key? key}) : super(key: key);

  @override
  _FriendListPageState createState() => _FriendListPageState();
}

class Friend {
  String name = "", phoneNum = "", emaillAddress = "";
  Friend(String name, String phoneNum, String emaillAddress) {
    this.name = name;
    this.phoneNum = phoneNum;
    this.emaillAddress = emaillAddress;
  }
}

class _FriendListPageState extends State<FriendListPage> {
  final user = FirebaseAuth.instance.currentUser;
  List friends = [];
  List<Widget> friendWidgets = [];
  String trustedUser = "";

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
    super.initState();
    getLanguage();
    getFriend();
  }

  void getFriend() {
    print("getFriend");
    FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .get()
        .then((event) {
      friends = event['friends'];
      trustedUser = event['trustedUser'];
      print("friends");
      print(friends);
      friendWidget();
      // for (int i = 0; i < event['friends'].length; i++) {
      //   setState(() {
      //     friendWidget(event['friends'][i], event['trustedUser']);
      //   });
      // }
    });
  }

  @override
  Widget build(BuildContext context) {
    print(friendWidgets.length);
    return Scaffold(
      appBar: AppBar(
        // automaticallyImplyLeading: false,
        backgroundColor: Colors.redAccent,
        title: Text(lang == "en" ? "Friend List" : "好友清單"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              for (int i = 0; i < friendWidgets.length; i++) friendWidgets[i],
            ],
          ),
        ),
      ),
    );
  }

  friendWidget() async {
    print("friendWidget");
    friendWidgets = [];
    for (int i = 0; i < friends.length; i++) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(friends[i])
          .get()
          .then((value) {
        friendWidgets.add(
          SizedBox(
            width: double.infinity,
            child: Card(
              color: Colors.lightBlue[200],
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.network(value['iconPic']),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              value['name'],
                              style: TextStyle(
                                fontSize: 30,
                                fontFamily: "OpenSan",
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              child: Container(
                                child: Text(
                                  value['email'],
                                  style: TextStyle(
                                    // fontSize: 20,
                                    fontFamily: "OpenSan",
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: value.id != trustedUser
                            ? () {
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user!.uid)
                                    .update({'trustedUser': value.id});
                                getFriend();
                              }
                            : () {
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user!.uid)
                                    .update({'trustedUser': ""});
                                getFriend();
                              },
                        icon: Icon(Icons.verified),
                        label: Text(
                            "${value.id != trustedUser ? lang == "en" ? "Mark" : "標記" : lang == "en" ? "Unmark" : "取消標記"}${lang == "en" ? " as Trusted User" : "為信任用戶"}"),
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                              value.id != trustedUser
                                  ? Colors.blue
                                  : Colors.grey),
                          foregroundColor:
                              MaterialStateProperty.all<Color>(Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () {
                          print(value['name']);
                          showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text(lang == "en" ? "Confirm" : "確認"),
                                  content: Text(lang == "en"
                                      ? "Are you sure to remove ${value['name']} from friend list?"
                                      : "你是否肯定要將${value['name']}從好友清單移除"),
                                  actions: [
                                    TextButton(
                                        onPressed: () async {
                                          final name = value['name'];
                                          friends.remove(value.id);
                                          print("friends:$friends");
                                          print("trustedUser:$trustedUser");
                                          print("value.id:$value.id");
                                          print(
                                              "trustedUser == value.id:${trustedUser == value.id}");
                                          if (trustedUser == value.id) {
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(user!.uid)
                                                .update({
                                              'friends': friends,
                                              'trustedUser': ""
                                            });
                                          } else {
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(user!.uid)
                                                .update({'friends': friends});
                                          }
                                          var removeTarget = value['friends'];
                                          removeTarget.remove(user!.uid);
                                          print("removeTarget:$removeTarget");
                                          print(
                                              "value['trustedUser']:${value['trustedUser']}");
                                          print("user!.uid:${user!.uid}");
                                          print(
                                              "value['trustedUser'] ==user!.uid:${value['trustedUser'] == user!.uid}");
                                          if (value['trustedUser'] ==
                                              user!.uid) {
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(value.id)
                                                .update({
                                              'trustedUser': "",
                                              'friends': removeTarget
                                            });
                                          } else {
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(value.id)
                                                .update(
                                                    {'friends': removeTarget});
                                          }
                                          Navigator.pop(context);
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: Text(lang == "en"
                                                    ? "Successfully"
                                                    : "成功"),
                                                content: Text(lang == "en"
                                                    ? "$name is removed from the friend list!"
                                                    : "$name已從你的好友清單移除"),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                    child: Text(lang == "en"
                                                        ? "OK"
                                                        : "好"),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                          setState(() {
                                            getFriend();
                                          });
                                        },
                                        child:
                                            Text(lang == "en" ? "Yes" : "是")),
                                    TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text(lang == "en" ? "No" : "否")),
                                  ],
                                );
                              });
                        },
                        icon: Icon(Icons.person_remove),
                        label: Text(lang == "en" ? "Remove Friend" : "移除好友"),
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.red),
                          foregroundColor:
                              MaterialStateProperty.all<Color>(Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      });
    }
    setState(() {});
  }
}
