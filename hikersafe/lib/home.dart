import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:hikersafe/hiking_map.dart';
import 'package:hikersafe/tracking_map.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_friend.dart';
import 'friend_list.dart';
import 'plan_route.dart';
import 'manage_route.dart';
import 'route_info.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser;
  List name = [];
  List picUrl = [];
  List routeId = [];
  List notification = [];
  String isHiking = "";
  List<Color> colorList = [
    Colors.orangeAccent,
    Colors.green,
    Colors.blueAccent,
    Colors.purpleAccent
  ];

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
    checkHiking();
    getRoute();
    getNotification();
  }

  checkHiking() async {
    await FirebaseFirestore.instance
        .collection("hiking")
        .where('hikerId', isEqualTo: user!.uid)
        .get()
        .then((value) {
      print("value:$value");
      if (value.docs.isNotEmpty) {
        isHiking = value.docs[0].id;
        print(isHiking);
      }
    });
    setState(() {});
  }

  getNotification() async {
    FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .snapshots()
        .listen((event) {
      notification = event['notification'];
    });
    setState(() {});
  }

  getRoute() async {
    var savedRouteId = [];
    // prefs.getStringList('savedRouteId');
    FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .snapshots()
        .listen((event) async {
      savedRouteId = [];
      savedRouteId = event['savedRoute'];

      name = [];
      picUrl = [];
      routeId = [];

      print(picUrl);
      print(name);
      print(routeId);
      for (int i = 0; i < savedRouteId.length; i++) {
        await FirebaseFirestore.instance
            .collection("routes")
            .doc(savedRouteId[i])
            .get()
            .then((value) {
          if (value.data() == null) {
            savedRouteId.removeAt(i--);
          } else {
            setState(() {
              name.add(value.data()!['name']);
              picUrl.add(value.data()!['routeImage']);
              routeId.add(savedRouteId[i]);
            });
          }
        });
      }
      setState(() {});
      print(picUrl);
      print(name);
      print(routeId);
    });
    // if (savedRouteId != null) {

    // prefs.setStringList('savedRouteId', savedRouteId);
    // print(prefs.getStringList('savedRouteId'));
    // }
  }

  @override
  Widget build(BuildContext context) {
    // if (isHiking.isNotEmpty) {
    //   Future.delayed(
    //       Duration.zero,
    //       () => showDialog(
    //           context: context,
    //           builder: (context) {
    //             return AlertDialog(
    //               actions: [
    //                 TextButton(
    //                     onPressed: () => Navigator.push(
    //                           context,
    //                           MaterialPageRoute(
    //                               builder: (context) => TrackingMapPage(
    //                                     hikingId: '',
    //                                   )),
    //                         ),
    //                     child: Text("Ok"))
    //               ],
    //             );
    //           }));
    // }
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CarouselSlider(
              items: [
                if (routeId.isEmpty)
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    width: double.infinity,
                    child: InkWell(
                      child: Card(
                        color: Colors.blueAccent,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang == 'en'
                                    ? "You haven't saved any route! Let's creted a new route first!"
                                    : "你尚未儲存任何路線！請先創造一個新號線！",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontFamily: "OpenSan",
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Divider(color: Colors.white),
                              SizedBox(
                                  width: double.infinity,
                                  child: Icon(
                                    Icons.hiking,
                                    size: 200,
                                    color: Colors.white,
                                  )),
                            ],
                          ),
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlanRoutePage(),
                          ),
                        );
                      },
                    ),
                  ),
                if (routeId.isNotEmpty)
                  for (int i = 0;
                      i < routeId.length && i < colorList.length;
                      i++)
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      width: double.infinity,
                      child: InkWell(
                        child: Card(
                          color: colorList[i],
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name[i],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontFamily: "OpenSan",
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Divider(color: Colors.white),
                                SizedBox(
                                  width: double.infinity,
                                  child: Image.network(
                                    picUrl[i],
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RouteInfoPage(
                                routeId: routeId[i],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
              ],
              options: CarouselOptions(
                height: MediaQuery.of(context).size.height * 0.5,
                viewportFraction: 0.95,
                autoPlay: true,
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => isHiking.isEmpty
                          ? ManageRoutePage()
                          : HikingMapPage(hikingId: isHiking)),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isHiking.isEmpty
                          ? lang == 'en'
                              ? 'Start Hiking'
                              : "開始行山"
                          : lang == 'en'
                              ? "Back to Hiking"
                              : "返回行山",
                      style: TextStyle(
                        // color: Colors.white,
                        fontSize: 40,
                        fontFamily: "OpenSan",
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios)
                  ],
                ),
              ),
            ),
            const Divider(color: Colors.black),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => FriendListPage()),
                      );
                    },
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: Column(
                        children: [
                          Icon(Icons.people),
                          Text(
                            lang == 'en' ? "Friend\nList" : "好友名單",
                            style: TextStyle(
                              // color: Colors.white,
                              fontSize: 5,
                              fontFamily: "OpenSan",
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AddFriendPage()),
                      );
                    },
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: Column(
                        children: [
                          Icon(Icons.person_add),
                          Text(
                            lang == 'en' ? "Add\nFriend" : "新增好友",
                            style: TextStyle(
                              // color: Colors.white,
                              fontSize: 5,
                              fontFamily: "OpenSan",
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PlanRoutePage()),
                      );
                    },
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: Column(
                        children: [
                          Icon(Icons.list_alt),
                          Text(
                            lang == 'en' ? "Planning\nRoute" : "設計路線",
                            style: TextStyle(
                              // color: Colors.white,
                              fontSize: 5,
                              fontFamily: "OpenSan",
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ManageRoutePage()),
                      );
                    },
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: Column(
                        children: [
                          Icon(Icons.manage_search),
                          Text(
                            lang == 'en' ? "Manage\nRoute" : "管理路線",
                            style: TextStyle(
                              // color: Colors.white,
                              fontSize: 5,
                              fontFamily: "OpenSan",
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
