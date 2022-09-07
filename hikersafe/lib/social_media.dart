import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SocialMediaPage extends StatefulWidget {
  const SocialMediaPage({Key? key}) : super(key: key);

  @override
  _SocialMediaPageState createState() => _SocialMediaPageState();
}

class _SocialMediaPageState extends State<SocialMediaPage> {
  final user = FirebaseAuth.instance.currentUser;
  List<Widget> post = [];
  @override
  void initState() {
    super.initState();
    getLanguage();
    getPost();
  }

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

  getPost() async {
    List friendList = [];
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get()
        .then((value) {
      friendList = value.data()!['friends'];
      friendList.add(user!.uid);
    });
    FirebaseFirestore.instance
        .collection('posts')
        .where('userId', whereIn: friendList)
        .snapshots()
        .listen((event) {
      post = [];
      for (var result in event.docs) {
        postBlock(result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.refresh),
        onPressed: () async {
          setState(() {
            getLanguage();
          });
        },
        backgroundColor: Colors.blue,
      ),
      appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          title: SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                posting(context);
              },
              icon: Icon(Icons.post_add),
              label: Text(lang == "en" ? "New Post" : "新推文"),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
                foregroundColor: MaterialStateProperty.all<Color>(
                  Colors.black,
                ),
              ),
            ),
          )),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            children: post,
          ),
        ),
      ),
    );
  }

  Future<void> posting(BuildContext context) async {
    List imageUrlData = [];
    List<File> images = [];
    TextEditingController content = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(lang == "en" ? "New Post" : "新推文"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: content,
                    maxLines: 10,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: lang == "en" ? 'Content...' : "內容...",
                    ),
                  ),
                  Divider(color: Colors.black),
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      children: [
                        for (int i = 0; i < images.length; i++)
                          InkWell(
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.15,
                              height: MediaQuery.of(context).size.width * 0.15,
                              child: Card(
                                child: Image.file(images[i]),
                              ),
                            ),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text(lang == "en" ? "Photo" : "相片"),
                                    content: Image.file(images[i]),
                                    actions: [
                                      TextButton.icon(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          setState(() {
                                            images.removeAt(i);
                                          });
                                        },
                                        icon: Icon(Icons.delete),
                                        label: Text(
                                            lang == "en" ? "Delete" : "刪除"),
                                      ),
                                      TextButton.icon(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        icon: Icon(Icons.check),
                                        label: Text(lang == "en" ? "Ok" : "好"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        InkWell(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.15,
                            height: MediaQuery.of(context).size.width * 0.15,
                            child: Card(
                              color: Colors.grey[300],
                              child: Icon(Icons.add),
                            ),
                          ),
                          onTap: () async {
                            showCupertinoModalPopup(
                              context: context,
                              builder: (context) {
                                return CupertinoActionSheet(
                                  actions: [
                                    CupertinoActionSheetAction(
                                        onPressed: () async {
                                          final image = await ImagePicker()
                                              .pickImage(
                                                  source: ImageSource.gallery);
                                          setState(() {
                                            images.add(File(image!.path));
                                            print(images.last);
                                          });
                                          Navigator.pop(context);
                                        },
                                        child: Text(lang == "en"
                                            ? "From Gallery"
                                            : "從相冊")),
                                    CupertinoActionSheetAction(
                                      onPressed: () async {
                                        final image = await ImagePicker()
                                            .pickImage(
                                                source: ImageSource.camera);
                                        setState(() {
                                          images.add(File(image!.path));
                                          print(images.last);
                                        });
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                          lang == "en" ? "From Camera" : "從相機"),
                                    ),
                                  ],
                                  cancelButton: CupertinoActionSheetAction(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text(lang == "en" ? "Cancel" : "取消"),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        for (int z = images.length; z < 3; z++)
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.15,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: Colors.white.withOpacity(0),
                        content: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            new CircularProgressIndicator(),
                          ],
                        ),
                      );
                    },
                  );
                  final doc =
                      FirebaseFirestore.instance.collection('posts').doc();
                  for (int i = 0; i < images.length; i++) {
                    final storageReference = FirebaseStorage.instance
                        .ref()
                        .child('posts/${doc.id}/${images[i]}[$i]');
                    await storageReference.putFile(images[i]);
                    String returnURL = "";
                    await storageReference.getDownloadURL().then((fileURL) {
                      returnURL = fileURL;
                    });
                    print(returnURL);
                    imageUrlData.add(returnURL);
                  }
                  await FirebaseFirestore.instance
                      .collection('posts')
                      .doc()
                      .set({
                    'userId': user!.uid,
                    'content': content.text,
                    'photo': imageUrlData,
                    'likes': [],
                    'comment': {}
                  });
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                icon: Icon(Icons.send),
                label: Text(lang == "en" ? "Post" : "發送"),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(Icons.cancel),
                label: Text(lang == "en" ? "Cancel" : "取消"),
              ),
            ],
          );
        });
      },
    );
  }

  // SizedBox postBlock() {
  //   return SizedBox(
  //     width: double.infinity,
  //     child: Card(
  //       color: Colors.white30,
  //       child: Padding(
  //         padding: const EdgeInsets.all(8.0),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Container(
  //               child: Row(
  //                 children: const [
  //                   Card(
  //                     color: Colors.pinkAccent,
  //                     child: Icon(
  //                       Icons.person,
  //                       size: 75,
  //                       color: Colors.lightBlueAccent,
  //                     ),
  //                   ),
  //                   Padding(
  //                     padding: EdgeInsets.all(8.0),
  //                     child: Text(
  //                       "TommyLam456",
  //                       style: TextStyle(
  //                         fontSize: 20,
  //                         fontFamily: "OpenSan",
  //                         fontWeight: FontWeight.bold,
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             const Text(
  //                 " 行山容易流汗，特別在烈日當空，要不斷飲水，但每次不要過多。「小吃，密食」能不斷保充體力，食物應為高能量如提子干、果仁、巧克力、Power Bar等。拉筋是對疲倦的雙腿有很大幫助，加快恢復體力，減少疲勞和抽筋。"),
  //             SizedBox(
  //               height: 8,
  //             ),
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 Text("Liked: 2000"),
  //                 Text("Commented: 30"),
  //               ],
  //             ),
  //             Divider(
  //               color: Colors.black,
  //             ),
  //             Row(
  //               children: [
  //                 Expanded(
  //                   flex: 1,
  //                   child: Card(
  //                     color: Colors.lightBlue,
  //                     child: Padding(
  //                       padding: const EdgeInsets.all(8.0),
  //                       child: Row(
  //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                         children: const [
  //                           Icon(Icons.thumb_up),
  //                           Text(
  //                             "Like",
  //                             style: TextStyle(
  //                               fontSize: 20,
  //                               fontFamily: "OpenSan",
  //                               fontWeight: FontWeight.bold,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //                 Expanded(
  //                   flex: 1,
  //                   child: Card(
  //                     color: Colors.amber,
  //                     child: Padding(
  //                       padding: const EdgeInsets.all(8.0),
  //                       child: Row(
  //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                         children: const [
  //                           Icon(Icons.chat),
  //                           Text(
  //                             "Comment",
  //                             style: TextStyle(
  //                               fontSize: 20,
  //                               fontFamily: "OpenSan",
  //                               fontWeight: FontWeight.bold,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  postBlock(var value) async {
    bool liked = false;
    for (var result in value.data()['likes']) {
      if (result == user!.uid) {
        liked = true;
        break;
      }
    }
    var userData;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(value.data()['userId'])
        .get()
        .then((val) {
      userData = val.data();
    });
    setState(() {
      post.add(
        SizedBox(
          width: double.infinity,
          child: Card(
            color: Colors.white30,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Card(
                          color: Colors.lightBlueAccent,
                          child: Image.network(userData['iconPic'])),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          userData['name'],
                          style: TextStyle(
                            fontSize: 20,
                            fontFamily: "OpenSan",
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    value.data()['content'],
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: "OpenSan",
                      // fontWeight: FontWeight.bold,
                    ),
                  ),
                  Divider(
                    color: Colors.black,
                  ),
                  // Center(child:
                  Wrap(
                    alignment: WrapAlignment.start,
                    children: [
                      for (int i = 0; i < value.data()['photo'].length; i++)
                        InkWell(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.2,
                            height: MediaQuery.of(context).size.width * 0.2,
                            child: Card(
                              child: Image.network(value.data()['photo'][i]),
                            ),
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text("Photo"),
                                  content:
                                      Image.network(value.data()['photo'][i]),
                                  actions: [
                                    TextButton.icon(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        icon: Icon(Icons.check),
                                        label: Text("Ok")),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      for (int z = value.data()['photo'].length; z < 3; z++)
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.2,
                        ),
                    ],
                    // ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextButton.icon(
                          onPressed: () async {
                            List likesList = [];
                            await FirebaseFirestore.instance
                                .collection('posts')
                                .doc(value.id)
                                .get()
                                .then((val) async {
                              likesList = val.data()!['likes'];
                              if (liked) {
                                likesList.remove(user!.uid);
                              } else {
                                likesList.add(user!.uid);
                              }
                              await FirebaseFirestore.instance
                                  .collection('posts')
                                  .doc(value.id)
                                  .update({'likes': likesList});
                            });
                          },
                          icon: Icon(Icons.thumb_up),
                          label: Text(
                              "${lang == "en" ? "Likes" : "讚好"}: ${value.data()['likes'].length}"),
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                                liked ? Colors.grey : Colors.lightBlue),
                            foregroundColor: MaterialStateProperty.all<Color>(
                              Colors.black,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: TextButton.icon(
                          onPressed: () async {
                            List<Widget> commentCard = [];
                            for (int i = 0;
                                i < value.data()['comment'].length;
                                i++) {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(value.data()['comment'][i]['userId'])
                                  .get()
                                  .then((val2) => commentCard.add(
                                        SizedBox(
                                          width: double.infinity,
                                          child: Card(
                                            color: Colors.blue[100],
                                            child: Row(
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Image.network(
                                                      val2.data()!['iconPic'],
                                                      height: 30),
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      val2.data()!['name'],
                                                      style: TextStyle(
                                                        fontFamily: "OpenSan",
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(value.data()['comment']
                                                        [i]['content'])
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ));
                            }
                            showDialog(
                                context: context,
                                builder: (context) {
                                  TextEditingController newComment =
                                      TextEditingController();
                                  return AlertDialog(
                                    title:
                                        Text(lang == "en" ? "Comment" : "留言"),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        children: commentCard,
                                        // [
                                        //   for (int i = 0;
                                        //       i <
                                        //           value
                                        //               .data()['comment']
                                        //               .length;
                                        //       i++)
                                        //     SizedBox(
                                        //       width: double.infinity,
                                        //       child: Card(
                                        //         child: Row(
                                        //           children: [
                                        //             // Image.network(
                                        //             //     value.data()['comment']
                                        //             //         [i]['images']),
                                        //             Text(value.data()['comment']
                                        //                 [i]['content'])
                                        //           ],
                                        //         ),
                                        //       ),
                                        //     )
                                        // ],
                                      ),
                                    ),
                                    actions: [
                                      TextField(
                                        controller: newComment,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () async {
                                              var commentList =
                                                  value.data()['comment'];
                                              commentList.add({
                                                'userId': user!.uid,
                                                'content': newComment.text
                                              });
                                              await FirebaseFirestore.instance
                                                  .collection('posts')
                                                  .doc(value.id)
                                                  .update(
                                                      {'comment': commentList});
                                              Navigator.pop(context);
                                            },
                                            icon: Icon(Icons.send),
                                            label: Text(
                                                lang == "en" ? "Send" : "發送"),
                                          ),
                                          TextButton.icon(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            icon: Icon(Icons.cancel),
                                            label: Text(
                                                lang == "en" ? "Cancel" : "取消"),
                                          ),
                                        ],
                                      )
                                    ],
                                  );
                                });
                          },
                          icon: Icon(Icons.chat),
                          label: Text(
                              "${lang == "en" ? "Comments" : "留言"}: ${value.data()['comment'].length}"),
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all<Color>(Colors.amber),
                            foregroundColor: MaterialStateProperty.all<Color>(
                              Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
