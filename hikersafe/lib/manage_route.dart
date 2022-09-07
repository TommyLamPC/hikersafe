import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:shared_preferences/shared_preferences.dart';

import 'dart:async';

import 'route_info.dart';

class ManageRoutePage extends StatefulWidget {
  const ManageRoutePage({Key? key}) : super(key: key);

  @override
  _ManageRoutePageState createState() => _ManageRoutePageState();
}

// class Route {
//   late String cnName, engName, cnDistrict, engDistrict;
//   Route(cnName, engName, cnDistrict, engDistrict) {
//     this.cnName = cnName;
//     this.engName = engName;
//     this.cnDistrict = cnDistrict;
//     this.engDistrict = engDistrict;
//   }
// }

class _ManageRoutePageState extends State<ManageRoutePage> {
  // List<Route> route = [
  //   Route("蝌蚪坪", "FO DAU PING", "沙田", "Sha Tin"),
  //   Route("尖風山", "HEBE HILL", "西貢", "Sai Kung"),
  //   Route("大埔滘黃徑", "TAI PO KAU YELLOW WALK", "大埔", "Tai Po"),
  //   Route("獅子山", "LION ROCK", "黃大仙", "Wong Tai Sin"),
  //   Route("大上托", "TAI SHEUNG TOK", "西貢", "Sai Kung"),
  //   Route("大老山", "TATE'S CAIRN", "黃大仙", "Wong Tai Sin"),
  //   Route("摩星嶺", "MOUNT DAVIS", "中西區", "Central and Western"),
  //   Route("太平山", "Victoria_Peak", "中西區", "Central and Western"),
  //   Route("渣甸山", "Jardines Lookout", "灣仔區", "Wan Chai"),
  //   Route("龍脊", "Dragons Back", "南區", "Southern"),
  // ];
  List<Widget> routeWidget = [];
  // var savedRouteId;
  final user = FirebaseAuth.instance.currentUser;
  // List<Map<String, dynamic>?> savedRouteData = [];

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
    super.initState();
    getLanguage();
    getRoute();
  }

  getRoute() async {
    // routeWidget = [];
    // final prefs = await SharedPreferences.getInstance();
    var savedRouteId = [];
    // prefs.getStringList('savedRouteId');
    FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .snapshots()
        .listen((event) async {
      routeWidget = [];
      savedRouteId = [];
      savedRouteId = event['savedRoute'];
      for (int i = 0; i < savedRouteId.length; i++) {
        await FirebaseFirestore.instance
            .collection("routes")
            .doc(savedRouteId[i])
            .get()
            .then((value) {
          if (value.data() == null) {
            savedRouteId.removeAt(i--);
          } else {
            setRouteWidget(value.data(), savedRouteId[i]);
          }
        });
      }
      FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .update({'savedRoute': savedRouteId});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        centerTitle: true,
        title: Text(lang == "en" ? "Manage Route" : "管理路線"),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection("users")
                  .doc(user!.uid)
                  .update({'savedRoute': []});
              setState(() {});
            },
            icon: Icon(Icons.delete),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(children: routeWidget),
      ),
    );
  }

  // setRoute() {
  //   for (int i = 0; i < route.length; i++) {
  //     setState(() {
  //       routeWidget.add(
  //         Padding(
  //           padding: EdgeInsets.only(left: 2, right: 2, bottom: 8),
  //           child: SizedBox(
  //             width: double.infinity,
  //             child: InkWell(
  //               child: Card(
  //                 child: Padding(
  //                   padding: EdgeInsets.all(8.0),
  //                   child: Row(
  //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                     children: [
  //                       Column(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           Text(
  //                             route[i].cnName,
  //                             style: TextStyle(
  //                               fontSize: 40,
  //                               fontFamily: "OpenSan",
  //                               fontWeight: FontWeight.bold,
  //                             ),
  //                           ),
  //                           Text(
  //                             route[i].engName,
  //                             style: TextStyle(
  //                               fontSize: 20,
  //                               fontFamily: "OpenSan",
  //                               fontWeight: FontWeight.bold,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                       Column(
  //                         crossAxisAlignment: CrossAxisAlignment.end,
  //                         children: [
  //                           Text(
  //                             route[i].cnDistrict,
  //                             style: TextStyle(
  //                               fontSize: 30,
  //                               fontFamily: "OpenSan",
  //                               fontWeight: FontWeight.bold,
  //                             ),
  //                           ),
  //                           Text(
  //                             route[i].engDistrict,
  //                             style: TextStyle(
  //                               fontSize: 15,
  //                               fontFamily: "OpenSan",
  //                               fontWeight: FontWeight.bold,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //               onTap: () {
  //                 Navigator.push(
  //                   context,
  //                   MaterialPageRoute(
  //                     builder: (context) => RouteInfoPage(
  //                       saved: true,
  //                     ),
  //                   ),
  //                 );
  //               },
  //             ),
  //           ),
  //         ),
  //       );
  //     });
  //   }
  // }

  setRouteWidget(Map<String, dynamic>? routeData, routeId) {
    // for (int i = 0; i < savedRouteData.length; i++) {
    setState(() {
      routeWidget.add(
        Padding(
          padding: EdgeInsets.only(left: 2, right: 2, bottom: 8),
          child: SizedBox(
            width: double.infinity,
            child: InkWell(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            // route[i].cnName,
                            routeData!['name'],
                            style: TextStyle(
                              fontSize: 40,
                              fontFamily: "OpenSan",
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Text(
                          //   // route[i].engName,
                          //   routeData['name'],
                          //   style: TextStyle(
                          //     fontSize: 20,
                          //     fontFamily: "OpenSan",
                          //     fontWeight: FontWeight.bold,
                          //   ),
                          // ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            // route[i].cnDistrict,
                            routeData['district'],
                            style: TextStyle(
                              fontSize: 20,
                              fontFamily: "OpenSan",
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Text(
                          //   // route[i].engDistrict,
                          //   routeData['district'],
                          //   style: TextStyle(
                          //     fontSize: 10,
                          //     fontFamily: "OpenSan",
                          //     fontWeight: FontWeight.bold,
                          //   ),
                          // ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              onLongPress: () {
                showCupertinoModalPopup(
                  context: context,
                  builder: (context) {
                    return CupertinoActionSheet(
                      actions: [
                        CupertinoActionSheetAction(
                          isDestructiveAction: true,
                          onPressed: () async {
                            // final prefs = await SharedPreferences.getInstance();
                            var savedRouteId = [];
                            //  =
                            //     prefs.getStringList('savedRouteId');
                            await FirebaseFirestore.instance
                                .collection("users")
                                .doc(user!.uid)
                                .get()
                                .then((val) async {
                              savedRouteId = val['savedRoute'];
                              print(savedRouteId);
                              savedRouteId.remove(routeId);
                              print(savedRouteId);
                              await FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(user!.uid)
                                  .update({'savedRoute': savedRouteId});
                            });

                            // savedRouteId.remove(routeId);
                            // // prefs.setStringList('savedRouteId', savedRouteId);
                            //
                            Navigator.pop(context);
                          },
                          child: Text(lang == "en" ? "Delete" : "刪除"),
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RouteInfoPage(
                      // saved: true,
                      routeId: routeId,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    });
  }
}
