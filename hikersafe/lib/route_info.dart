import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'hiking_map.dart';

class RouteInfoPage extends StatefulWidget {
  const RouteInfoPage({Key? key, required this.routeId}) : super(key: key);
  // final bool saved;
  final String routeId;

  @override
  _RouteInfoPageState createState() => _RouteInfoPageState();
}

class _RouteInfoPageState extends State<RouteInfoPage>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  late GoogleMapController mapController;
  double camLat = 22.3408088, camLng = 114.1798757;
  Map<MarkerId, Marker> markers = {};
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();
  List<String> checkPointName = [];
  List<double> checkPointLat = [];
  List<double> checkPointLng = [];
  List<List<String>> checkPointImage = [];
  String routeName = "", district = "", description = "", routeImage = "";
  String googleAPiKey = "AIzaSyBfG6onSh1iHDdGpDH_A5ukn995O-vyYX8";
  bool saved = false;
  late String routeId;
  final user = FirebaseAuth.instance.currentUser;

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

    this.routeId = widget.routeId;
    setSaved();

    tabController = TabController(vsync: this, length: 3);
    getRoute();
    _getPolyline();
  }

  Future<void> getRoute() async {
    await FirebaseFirestore.instance
        .collection("routes")
        .doc(routeId)
        .get()
        .then((value) {
      Map<String, dynamic>? routeData = value.data();
      List<dynamic>? images;
      for (int i = 0; i < routeData!['checkpoints'].length; i++) {
        checkPointName.add(routeData['checkpoints'][i]['checkPointName']);
        checkPointLat.add(routeData['checkpoints'][i]['checkPointLat']);
        checkPointLng.add(routeData['checkpoints'][i]['checkPointLng']);
        images = routeData['checkpoints'][i]['checkPointImage'];
        checkPointImage.add([]);
        for (int j = 0; j < images!.length; j++) {
          checkPointImage[i].add(images[j]);
        }
      }
      routeName = routeData['name'];
      district = routeData['district'];
      description = routeData['description'];
      routeImage = routeData['routeImage'];
    });
    setState(() {
      _getPolyline();
    });
  }

  Future<void> setSaved() async {
    saved = false;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get()
        .then((value) {
      for (int i = 0; i < value.data()!['savedRoute'].length; i++) {
        saved = (value.data()!['savedRoute'][i] == routeId);
        if (saved) break;
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    print(saved);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Visibility(
          child: FloatingActionButton(
            backgroundColor: Colors.red,
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .get()
                  .then((value) async {
                if (value.data()!['trustedUser'].isEmpty) {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(lang == "en" ? "Warning" : "警告"),
                        content: Text(lang == "en"
                            ? "For the safety reason, you must set a trusted user before hiking"
                            : "因為安全理由，你必須於行山前先設定信任用戶。"),
                        actions: [
                          TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(lang == "en" ? "OK" : "好"))
                        ],
                      );
                    },
                  );
                } else {
                  final hikingDoc =
                      FirebaseFirestore.instance.collection('hiking').doc();
                  await hikingDoc.set({
                    'lat': "22.340809",
                    'lng': "114.179876",
                    "routeId": routeId,
                    'hikerId': user!.uid,
                    'checkedPoint': 0
                  });
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(value.data()!['trustedUser'])
                      .get()
                      .then((val) async {
                    var notification = val.data()!['notification'];
                    notification.add({
                      'title': 'Hiking Notification!',
                      'desc':
                          '${user!.displayName} is Hiking Now! You can keep track of his hiking information at any time.',
                      'type': 'HN',
                      'hikingId': hikingDoc.id
                    });
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(value.data()!['trustedUser'])
                        .update({'notification': notification});
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HikingMapPage(
                          hikingId: hikingDoc.id,
                          // routeName: routeName,
                          // checkPointName: checkPointName,
                          // checkPointLat: checkPointLat,
                          // checkPointLng: checkPointLng,
                          // checkPointImage: checkPointImage,
                        ),
                      ),
                    );
                  });
                }
              });
            },
            child: Icon(Icons.hiking),
          ),
          visible: saved,
        ),
        appBar: AppBar(
          // automaticallyImplyLeading: false,
          backgroundColor: Colors.redAccent,
          bottom: TabBar(
            controller: tabController,
            tabs: const <Tab>[
              Tab(icon: Icon(Icons.text_fields)),
              Tab(icon: Icon(Icons.alt_route)),
              Tab(icon: Icon(Icons.map)),
            ],
          ),
          title: Text(routeName),
          actions: [
            if (saved)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: InkWell(
                  child: Icon(Icons.delete),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text(lang == "en" ? "Confirm" : "確認"),
                          content: Text(lang == "en"
                              ? "Do you want to delete this route?"
                              : "你是否刪除這個路線？"),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                showDialog(
                                  barrierDismissible: false,
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text(
                                          lang == "en" ? "Successfully" : "成功"),
                                      content: Text(lang == "en"
                                          ? "Route Deleted!"
                                          : "路線刪除了"),
                                      actions: [
                                        TextButton(
                                          onPressed: () async {
                                            List savedRoute = [];
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(user!.uid)
                                                .get()
                                                .then((value) {
                                              savedRoute =
                                                  value.data()!['savedRoute'];
                                            });
                                            savedRoute.remove(routeId);
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(user!.uid)
                                                .update(
                                                    {'savedRoute': savedRoute});
                                            Navigator.pop(context);
                                            await setSaved();
                                            setSaved();
                                          },
                                          child:
                                              Text(lang == "en" ? "OK" : "好"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Text(lang == "en" ? "Yes" : "是"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(lang == "en" ? "No" : "否"),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: InkWell(
                  child: Icon(Icons.save),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text(lang == "en" ? "Confirm" : "確認"),
                          content: Text(lang == "en"
                              ? "Do you want to save this route?"
                              : "是否儲存這個路線？"),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                showDialog(
                                  barrierDismissible: false,
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text(
                                          lang == "en" ? "Successfully" : "成功"),
                                      content: Text(lang == "en"
                                          ? "Route Saved!"
                                          : "路線儲存了！"),
                                      actions: [
                                        TextButton(
                                          onPressed: () async {
                                            List savedRoute = [];
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(user!.uid)
                                                .get()
                                                .then((value) {
                                              savedRoute =
                                                  value.data()!['savedRoute'];
                                            });
                                            savedRoute.add(routeId);
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(user!.uid)
                                                .update(
                                                    {'savedRoute': savedRoute});
                                            await setSaved();
                                            Navigator.pop(context);
                                          },
                                          child:
                                              Text(lang == "en" ? "OK" : "好"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Text(lang == "en" ? "Yes" : "是"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(lang == "en" ? "No" : "否"),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
        body: TabBarView(
          controller: tabController,
          physics: NeverScrollableScrollPhysics(),
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${lang == "en" ? "District" : "區域"}: $district",
                      style: TextStyle(
                        // color: Colors.white,
                        fontSize: 30,
                        fontFamily: "OpenSan",
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Divider(
                      color: Colors.black,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: routeImage != ""
                          ? Image.network(
                              // "https://www.afcd.gov.hk/tc_chi/country/cou_vis/cou_vis_cou/cou_vis_cou_lr/images/CP_photo_LionRock_s.jpg",
                              routeImage,
                              fit: BoxFit.contain,
                            )
                          : SizedBox(),
                    ),
                    Divider(
                      color: Colors.black,
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        // color: Colors.white,
                        fontSize: 20,
                        fontFamily: "OpenSan",
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // for (int j = 0; j <= 4; j++)
                    for (int i = 0; i < checkPointName.length; i++)
                      SizedBox(
                        width: double.infinity,
                        // child: InkWell(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.pin_drop,
                                  size: 40,
                                  color: Colors.red,
                                ),
                                Text(
                                  "${i + 1}: ${checkPointName[i]}",
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontFamily: "OpenSan",
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        //   onTap: () {
                        //     // final markerId = markers[checkPointName[i]];
                        //     // tabController.animateTo(2);
                        //     // mapController
                        //     //     .showMarkerInfoWindow(markerId!.markerId);
                        //     setState(() {
                        //       tabController.animateTo(2);
                        //       camLat = checkPointLat[i];
                        //       camLng = checkPointLng[i];
                        //     });
                        //   },
                        // ),
                      )
                  ],
                ),
              ),
            ),
            GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: LatLng(camLat, camLng), zoom: 15),
              myLocationEnabled: true,
              tiltGesturesEnabled: true,
              compassEnabled: true,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              onMapCreated: _onMapCreated,
              markers: Set<Marker>.of(markers.values),
              polylines: Set<Polyline>.of(polylines.values),
            ),
          ],
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
  }

  _addPolyLine() {
    // print("_addPolyLine");
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
        polylineId: id, color: Colors.blue, points: polylineCoordinates);
    polylines[id] = polyline;
    for (int i = 0; i < polylines.length; i++) {
      print(polylines[i].toString());
    }
    setState(() {});
  }

  _getPolyline() async {
    polylines = {};
    markers = {};
    polylineCoordinates = [];
    polylinePoints = PolylinePoints();
    print("_getPolyline");
    if (checkPointName.length == 0) {
      return;
    }

    camLat = checkPointLat[0];
    camLng = checkPointLng[0];

    addMaker(context);

    // _addMarkerCheckpoint();

    /// origin marker
    // _addMarker(LatLng(checkPointLat[0], checkPointLng[0]), "origin",
    //     BitmapDescriptor.defaultMarker);
    if (checkPointName.length >= 2) {
      /// destination marker
      // _addMarker(
      //     LatLng(checkPointLat[checkPointName.length - 1],
      //         checkPointLng[checkPointName.length - 1]),
      //     "destination",
      //     BitmapDescriptor.defaultMarkerWithHue(90));
      // print("_getPolyline");
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
          googleAPiKey,
          PointLatLng(checkPointLat[0], checkPointLng[0]),
          PointLatLng(checkPointLat[checkPointName.length - 1],
              checkPointLng[checkPointName.length - 1]),
          travelMode: TravelMode.walking,
          // optimizeWaypoints: true,
          wayPoints: [
            for (int i = 0; i < checkPointName.length; i++)
              PolylineWayPoint(
                  location: "${checkPointLat[i]},${checkPointLng[i]}"),
            //   PolylineWayPoint(location: "22.3543416,114.2030031"),
            // PolylineWayPoint(location: "22.3522705,114.1870366"),
            // PolylineWayPoint(location: "22.3495063,114.1692021"),
          ]);
      if (result.points.isNotEmpty) {
        result.points.forEach((PointLatLng point) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        });
      }
      // for (int i = 1; i < checkPointName.length - 1; i++) {
      //   // List<Location> locations = await locationFromAddress(checkPointName[i]);
      //   // print(i);
      //   // print(wayPointLatLng[i]);
      //   // print(locations);
      //   _addMarker(
      //       LatLng(checkPointLat[i], checkPointLng[i]),
      //       // "${checkPointLat[i]},${checkPointLng[i]}",
      //       checkPointName[i],
      //       BitmapDescriptor.defaultMarkerWithHue(200));
      // }
      // List<Location> locations = await locationFromAddress("沙田坳");
      _addPolyLine();
    }
  }

  Future addMaker(BuildContext context) async {
    for (int i = 0; i < checkPointName.length; i++) {
      String distance = "0 m", duration = "0 min";

      BitmapDescriptor descriptor =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      if (i > 0) {
        if (i == checkPointName.length - 1) {
          descriptor = BitmapDescriptor.defaultMarker;
        } else {
          descriptor = BitmapDescriptor.defaultMarkerWithHue(200);
        }
        final response = await http.get(Uri.parse(
            'https://maps.googleapis.com/maps/api/distancematrix/json?destinations='
            '${checkPointLat[i]},${checkPointLng[i]}'
            '&origins='
            '${checkPointLat[i - 1]},${checkPointLng[i - 1]}'
            '&mode=walking&key=$googleAPiKey&language=$lang'));
        print(jsonDecode(response.body));
        if (response.statusCode == 200) {
          print("distance: " +
              jsonDecode(response.body)['rows'][0]['elements'][0]['distance']
                  ['text']);
          distance = (jsonDecode(response.body)['rows'][0]['elements'][0]
              ['distance']['text']);
          print("duration: " +
              jsonDecode(response.body)['rows'][0]['elements'][0]['distance']
                  ['text']);
          duration = (jsonDecode(response.body)['rows'][0]['elements'][0]
              ['duration']['text']);
        }
      }
      addMarker(i, descriptor, context, distance, duration);
    }
  }

  void addMarker(int i, BitmapDescriptor descriptor, BuildContext context,
      String distance, String duration) {
    MarkerId markerId = MarkerId(checkPointName[i]);
    Marker marker = Marker(
      markerId: markerId,
      icon: descriptor,
      position: LatLng(checkPointLat[i], checkPointLng[i]),
      infoWindow: InfoWindow(
        title: checkPointName[i],
        snippet: lang == "en" ? "Click for more infomation" : "點擊以獲取更多資訊",
        onTap: () {
          showDialog(
            context: context,
            builder: (context) {
              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    title: Text(checkPointName[i]),
                    content: SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${lang == "en" ? "Distance" : "距離"}: $distance",
                            style: TextStyle(fontSize: 15),
                          ),
                          Text(
                            "${lang == "en" ? "Duration" : "需時"}: $duration",
                            style: TextStyle(fontSize: 15),
                          ),
                          Divider(color: Colors.black),
                          Center(
                            child: Wrap(
                              alignment: WrapAlignment.start,
                              children: [
                                for (int j = 0;
                                    j < checkPointImage[i].length;
                                    j++)
                                  InkWell(
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          0.15,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              0.15,
                                      child: Card(
                                        child: Image.network(
                                            checkPointImage[i][j]),
                                      ),
                                    ),
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: Text(
                                                lang == "en" ? "Photo" : "相片"),
                                            content: Image.network(
                                                checkPointImage[i][j]),
                                            actions: [
                                              // TextButton.icon(
                                              //   onPressed: () {
                                              //     Navigator.pop(context);
                                              //     setState(() {
                                              //       checkPointImage[i]
                                              //           .removeAt(j);
                                              //     });
                                              //   },
                                              //   icon: Icon(Icons.delete),
                                              //   label: Text("Delete"),
                                              // ),
                                              TextButton.icon(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  icon: Icon(Icons.check),
                                                  label: Text(lang == "en"
                                                      ? "Ok"
                                                      : "好")),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                // InkWell(
                                //   child: SizedBox(
                                //     width: MediaQuery.of(context).size.width *
                                //         0.15,
                                //     height: MediaQuery.of(context).size.width *
                                //         0.15,
                                //     child: Card(
                                //       color: Colors.grey[300],
                                //       child: Icon(Icons.add),
                                //     ),
                                //   ),
                                //   onTap: () async {
                                //     // showCupertinoModalPopup(
                                //     //   context: context,
                                //     //   builder: (context) {
                                //     //     return CupertinoActionSheet(
                                //     //       actions: [
                                //     //         CupertinoActionSheetAction(
                                //     //             onPressed: () async {
                                //     //               final image =
                                //     //                   await ImagePicker()
                                //     //                       .pickImage(
                                //     //                           source:
                                //     //                               ImageSource
                                //     //                                   .gallery);
                                //     //               setState(() {
                                //     //                 checkPointImage[i]
                                //     //                     .add(File(image!.path));
                                //     //                 print(checkPointImage[i]
                                //     //                     .last);
                                //     //               });
                                //     //               Navigator.pop(context);
                                //     //             },
                                //     //             child: Text("From Gallery")),
                                //     //         CupertinoActionSheetAction(
                                //     //           onPressed: () async {
                                //     //             final image =
                                //     //                 await ImagePicker()
                                //     //                     .pickImage(
                                //     //                         source: ImageSource
                                //     //                             .camera);
                                //     //             setState(() {
                                //     //               checkPointImage[i]
                                //     //                   .add(File(image!.path));
                                //     //               print(
                                //     //                   checkPointImage[i].last);
                                //     //             });
                                //     //             Navigator.pop(context);
                                //     //           },
                                //     //           child: Text("From Camera"),
                                //     //         ),
                                //     //       ],
                                //     //       cancelButton:
                                //     //           CupertinoActionSheetAction(
                                //     //         onPressed: () {
                                //     //           Navigator.pop(context);
                                //     //         },
                                //     //         child: Text("Cancel"),
                                //     //       ),
                                //     //     );
                                //     //   },
                                //     // );
                                //   },
                                // ),
                                for (int z = checkPointImage[i].length;
                                    z < 3;
                                    z++)
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.15,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.check),
                        label: Text(lang == "en" ? "OK" : "好"),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
    markers[markerId] = marker;
    setState(() {});
  }
}
