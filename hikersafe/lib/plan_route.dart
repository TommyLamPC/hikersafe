import 'dart:convert';
// import 'dart:ffi';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:async';

// googleAPIKey = "AIzaSyBfG6onSh1iHDdGpDH_A5ukn995O-vyYX8"

class PlanRoutePage extends StatefulWidget {
  const PlanRoutePage({Key? key}) : super(key: key);

  @override
  _PlanRoutePageState createState() => _PlanRoutePageState();
}

class _PlanRoutePageState extends State<PlanRoutePage> {
  static const List<Tab> myTabs = <Tab>[
    Tab(icon: Icon(Icons.text_fields)),
    Tab(icon: Icon(Icons.map)),
  ];

  late GoogleMapController mapController;
  double camLat = 22.3408088, camLng = 114.1798757;
  Map<MarkerId, Marker> markers = {};
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();
  List<String> checkPointName = [];
  List<double> checkPointLat = [];
  List<double> checkPointLng = [];
  List<List<File>> checkPointImage = [];
  File? routeImage = null;
  // List wayPointString = ["慈雲山慈雲閣", '沙田坳道', '獅子山', '筆架山', "蘇屋村"];
  // List wayPointLatLng = [
  //   '22.350448 114.196811',
  //   '22.3543416 114.2030031',
  //   '22.3522705 114.1870366',
  //   '22.3495063 114.1692021',
  //   '22.3411232 114.1565588'
  // ];
  String googleAPiKey = "AIzaSyBfG6onSh1iHDdGpDH_A5ukn995O-vyYX8";
  String newPlace = "";
  // List<String> districtList = [
  //   "Central and Western District",
  //   "Wan Chai District",
  //   "Eastern District",
  //   "Southern District",
  //   "Yau Tsim Mong District",
  //   "Sham Shui Po District",
  //   "Kowloon City District",
  //   "Wong Tai Sin District",
  //   "Kwun Tong District",
  //   "Kwai Tsing District",
  //   "Tsuen Wan District",
  //   "Tuen Mun District",
  //   "Yuen Long District",
  //   "North District",
  //   "Tai Po District",
  //   "Sha Tin District",
  //   "Sai Kung District",
  //   "Islands District"
  // ];
  // String district = 'Central and Western District';
  // String routeName = '';
  // String description = '';

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
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.green,
          onPressed: () {},
          child: IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(lang == "en" ? "New Checkpoint" : "新檢查點:"),
                    content: TextFormField(
                      onFieldSubmitted: (_) => Navigator.of(context).pop(),
                      onChanged: (name) => setState(() => newPlace = name),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          addPlace(context, newPlace);
                        },
                        child: Text(lang == "en" ? "Save" : "儲存"),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            // wayPointString.add(newPlace);
                            newPlace = "";
                          });
                          Navigator.of(context).pop();
                        },
                        child: Text(lang == "en" ? "Cancel" : "取消"),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        appBar: AppBar(
          backgroundColor: Colors.redAccent,
          bottom: const TabBar(
            tabs: myTabs,
          ),
          title: Text(lang == "en" ? "Planning Route" : "設計路線"),
          actions: [
            InkWell(
              child: const Padding(
                padding: EdgeInsets.all(10.0),
                child: Icon(Icons.save),
              ),
              onTap: () {
                save(context);
              },
            ),
          ],
        ),
        body: TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            SafeArea(
              bottom: true,
              child: Column(
                children: [
                  if (checkPointName.length == 0)
                    Expanded(
                      flex: 10,
                      child: Center(
                        child: Text(
                          lang == "en"
                              ? "Please add some checkpoint first!"
                              : "請先新增檢查點",
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  if (checkPointName.length > 0)
                    Expanded(
                      flex: 10,
                      child: ReorderableListView(
                        children: [
                          for (int i = 0; i < checkPointName.length; i++)
                            ListTile(
                              key: Key('$i'),
                              title: Text(checkPointName[i]),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.black),
                                    onPressed: () => showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: Text(
                                              lang == "en" ? "Edit" : "修改"),
                                          content: TextFormField(
                                            initialValue: checkPointName[i],
                                            onFieldSubmitted: (_) =>
                                                Navigator.of(context).pop(),
                                            onChanged: (name) =>
                                                setState(() => newPlace = name),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                changePlace(
                                                    context, newPlace, i);
                                              },
                                              child: Text(
                                                  lang == "en" ? "Save" : "儲存"),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                setState() {
                                                  newPlace = "";
                                                }

                                                Navigator.of(context).pop();
                                              },
                                              child: Text(lang == "en"
                                                  ? "Cancel"
                                                  : "取消"),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  IconButton(
                                      icon: Icon(Icons.delete,
                                          color: Colors.black),
                                      onPressed: () {
                                        setState(() {
                                          checkPointName.removeAt(i);
                                          checkPointLat.removeAt(i);
                                          checkPointLng.removeAt(i);
                                          checkPointImage.removeAt(i);
                                          _getPolyline();
                                        });
                                      }
                                      // () => setState(
                                      //     () => checkPointName.removeAt(i)),
                                      ),
                                ],
                              ),
                            ),
                        ],
                        onReorder: (int oldIndex, int newIndex) {
                          setState(() {
                            if (oldIndex < newIndex) {
                              newIndex -= 1;
                            }
                            final String item =
                                checkPointName.removeAt(oldIndex);
                            checkPointName.insert(newIndex, item);
                            final double itemLat =
                                checkPointLat.removeAt(oldIndex);
                            checkPointLat.insert(newIndex, itemLat);
                            final double itemLng =
                                checkPointLng.removeAt(oldIndex);
                            checkPointLng.insert(newIndex, itemLng);
                            final List<File> itemImage =
                                checkPointImage.removeAt(oldIndex);
                            checkPointImage.insert(newIndex, itemImage);
                            _getPolyline();
                          });
                        },
                      ),
                    ),
                  // Expanded(
                  //   flex: 1,
                  //   child: SizedBox(
                  //     width: double.infinity,
                  //     child: InkWell(
                  //       child: const Card(
                  //         color: Colors.green,
                  //         child: Icon(Icons.add),
                  //       ),
                  //       onTap: () {
                  //         showDialog(
                  //           context: context,
                  //           builder: (BuildContext context) {
                  //             return AlertDialog(
                  //               title: Text("New Checkpoint"),
                  //               content: TextFormField(
                  //                 onFieldSubmitted: (_) =>
                  //                     Navigator.of(context).pop(),
                  //                 onChanged: (name) =>
                  //                     setState(() => newPlace = name),
                  //               ),
                  //               actions: [
                  //                 TextButton(
                  //                   onPressed: () {
                  //                     addPlace(context, newPlace);
                  //                   },
                  //                   child: Text("Save"),
                  //                 ),
                  //                 TextButton(
                  //                   onPressed: () {
                  //                     setState(() {
                  //                       // wayPointString.add(newPlace);
                  //                       newPlace = "";
                  //                     });
                  //                     Navigator.of(context).pop();
                  //                   },
                  //                   child: Text("Cancel"),
                  //                 ),
                  //               ],
                  //             );
                  //           },
                  //         );
                  //       },
                  //     ),
                  //   ),
                  // ),
                ],
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

  Future<dynamic> save(BuildContext context) {
    List<String> districtList = lang == "en"
        ? [
            "Central and Western",
            "Wan Chai District",
            "Eastern District",
            "Southern District",
            "Yau Tsim Mong District",
            "Sham Shui Po District",
            "Kowloon City District",
            "Wong Tai Sin District",
            "Kwun Tong District",
            "Kwai Tsing District",
            "Tsuen Wan District",
            "Tuen Mun District",
            "Yuen Long District",
            "North District",
            "Tai Po District",
            "Sha Tin District",
            "Sai Kung District",
            "Islands District"
          ]
        : [
            "中西區",
            "灣仔區",
            "東區",
            "南區",
            "油尖旺區",
            "深水埗區",
            "九龍城區",
            "黃大仙區",
            "觀塘區",
            "葵青區",
            "荃灣區",
            "屯門區",
            "元朗區",
            "北區",
            "大埔區",
            "沙田區",
            "西貢區",
            "離島區"
          ];
    String district = districtList[0];
    String routeName = '';
    String description = '';
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(lang == "en" ? "Route Information" : "路線資訊"),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          lang == "en" ? "Route Name: " : "路線名稱: ",
                          style: TextStyle(
                            // color: Colors.white,
                            // fontSize: 25,
                            fontFamily: "OpenSan",
                            // fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: lang == "en" ? 'Route Name' : "路線名稱",
                            // labelStyle: TextStyle(),
                          ),
                          onChanged: (newRouteName) {
                            routeName = newRouteName;
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          lang == "en" ? "District: " : "區域: ",
                          style: TextStyle(
                            // color: Colors.white,
                            // fontSize: 25,
                            fontFamily: "OpenSan",
                            // fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: DropdownButton<String>(
                          value: district,
                          onChanged: (String? newDistrict) {
                            setState(() {
                              district = newDistrict!;
                            });
                          },
                          items: districtList
                              // [
                              //   "Central and Western District",
                              //   "Wan Chai District",
                              //   "Eastern District",
                              //   "Southern District",
                              //   "Yau Tsim Mong District",
                              //   "Sham Shui Po District",
                              //   "Kowloon City District",
                              //   "Wong Tai Sin District",
                              //   "Kwun Tong District",
                              //   "Kwai Tsing District",
                              //   "Tsuen Wan District",
                              //   "Tuen Mun District",
                              //   "Yuen Long District",
                              //   "North District",
                              //   "Tai Po District",
                              //   "Sha Tin District",
                              //   "Sai Kung District",
                              //   "Islands District"
                              // ]
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          lang == "en" ? "Description: " : "描述: ",
                          style: TextStyle(
                            // color: Colors.white,
                            // fontSize: 25,
                            fontFamily: "OpenSan",
                            // fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          maxLines: 10,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: lang == "en" ? 'Description' : "描述",
                            labelStyle: TextStyle(
                                // color: Colors.white,
                                ),
                          ),
                          onChanged: (newDescription) {
                            description = newDescription;
                          },
                        ),
                      ),
                    ],
                  ),
                  Center(
                    child: routeImage == null
                        ? TextButton.icon(
                            onPressed: () async {
                              showCupertinoModalPopup(
                                context: context,
                                builder: (context) {
                                  return CupertinoActionSheet(
                                    actions: [
                                      CupertinoActionSheetAction(
                                          onPressed: () async {
                                            final image = await ImagePicker()
                                                .pickImage(
                                                    source:
                                                        ImageSource.gallery);
                                            setState(() {
                                              routeImage = (File(image!.path));
                                              print(routeImage);
                                            });
                                            Navigator.pop(context);
                                          },
                                          child: Text(lang == "en"
                                              ? "From Gallery"
                                              : "從相片庫")),
                                      CupertinoActionSheetAction(
                                        onPressed: () async {
                                          final image = await ImagePicker()
                                              .pickImage(
                                                  source: ImageSource.camera);
                                          setState(() {
                                            routeImage = (File(image!.path));
                                            print(routeImage);
                                          });
                                          Navigator.pop(context);
                                        },
                                        child: Text(lang == "en"
                                            ? "From Camera"
                                            : "從相機"),
                                      ),
                                    ],
                                    cancelButton: CupertinoActionSheetAction(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child:
                                          Text(lang == "en" ? "Cancel" : "取消"),
                                    ),
                                  );
                                },
                              );
                            },
                            icon: Icon(Icons.add),
                            label: Text(
                                lang == "en" ? "Add Route Image" : "新增路線相片"))
                        : InkWell(
                            child: Image.file(routeImage!),
                            onLongPress: () {
                              showCupertinoModalPopup(
                                context: context,
                                builder: (context) {
                                  return CupertinoActionSheet(
                                    actions: [
                                      CupertinoActionSheetAction(
                                          onPressed: () async {
                                            setState(() {
                                              routeImage = null;
                                            });
                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                              lang == "en" ? "Delete" : "刪除")),
                                    ],
                                    cancelButton: CupertinoActionSheetAction(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child:
                                          Text(lang == "en" ? "Cancel" : "取消"),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
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
                  print("saved");
                  final docRoute =
                      FirebaseFirestore.instance.collection("routes").doc();

                  List<List<String>> imageUrlData = [];
                  String routeImageUrl = "";
                  if (routeImage != null) {
                    final storageReference = FirebaseStorage.instance
                        .ref()
                        .child('routesImages/$routeName/$routeName');
                    await storageReference.putFile(routeImage!);
                    await storageReference.getDownloadURL().then((fileURL) {
                      routeImageUrl = fileURL;
                    });
                    print(routeImageUrl);
                  }
                  for (int i = 0; i < checkPointImage.length; i++) {
                    imageUrlData.add([]);
                    for (int j = 0; j < checkPointImage[i].length; j++) {
                      final storageReference = FirebaseStorage.instance
                          .ref()
                          .child(
                              'routesImages/$routeName/${checkPointName[i]}[$j]');
                      await storageReference.putFile(checkPointImage[i][j]);
                      String returnURL = "";
                      await storageReference.getDownloadURL().then((fileURL) {
                        returnURL = fileURL;
                      });
                      print(returnURL);
                      imageUrlData[i].add(returnURL);
                    }
                  }
                  var checkpointData = [];
                  for (int i = 0; i < checkPointName.length; i++) {
                    checkpointData.add({
                      'checkPointName': checkPointName[i],
                      'checkPointLat': checkPointLat[i],
                      'checkPointLng': checkPointLng[i],
                      'checkPointImage': imageUrlData[i]
                    });
                  }
                  var data = {
                    'name': routeName,
                    'district': district,
                    'description': description,
                    "routeImage": routeImageUrl,
                    'checkpoints': checkpointData
                  };
                  print(data);
                  await docRoute.set(data);
                  final prefs = await SharedPreferences.getInstance();
                  List<String>? savedRouteId =
                      prefs.getStringList('savedRouteId');
                  if (savedRouteId == null) {
                    savedRouteId = [docRoute.id];
                  } else {
                    savedRouteId.add(docRoute.id);
                  }
                  prefs.setStringList('savedRouteId', savedRouteId);
                  print(prefs.getStringList('savedRouteId'));
                  Navigator.of(context).pop();
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text(lang == "en" ? "Save" : "儲存"),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    // description = routeName = "";
                    // district = lang == "en" ? 'Central and Western' : "中西區";
                  });
                  Navigator.of(context).pop();
                },
                child: Text(lang == "en" ? "Cancel" : "取消"),
              ),
            ],
          );
        });
      },
    );
  }

  void _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
  }

  // _addMarker(LatLng position, String id, BitmapDescriptor descriptor) {
  //   // print("_addMarker");
  //   MarkerId markerId = MarkerId(id);
  //   Marker marker =
  //       Marker(markerId: markerId, icon: descriptor, position: position);
  //   markers[markerId] = marker;
  // }

  // _addMarkerCheckpoint() {
  //   for (int i = 0; i < checkPointName.length; i++) {
  //     BitmapDescriptor descriptor;
  //     Map value;
  //     if (i == 0) {
  //       descriptor = BitmapDescriptor.defaultMarker;
  //     } else {
  //       // getDistance("${checkPointLat[i - 1]}, ${checkPointLng[i - 1]}",
  //       //     '${checkPointLat[i]}, ${checkPointLng[i]}');
  //       if (i == checkPointName.length - 1) {
  //         descriptor = BitmapDescriptor.defaultMarkerWithHue(90);
  //       } else {
  //         descriptor = BitmapDescriptor.defaultMarkerWithHue(200);
  //       }
  //     }
  //     MarkerId markerId = MarkerId(checkPointName[i]);
  //     Marker marker = Marker(
  //       markerId: markerId,
  //       icon: descriptor,
  //       position: LatLng(checkPointLat[i], checkPointLng[i]),
  //       infoWindow: InfoWindow(
  //         title: checkPointName[i],
  //         // snippet: distance[i] + "; " + duration[i],
  //       ),
  //     );
  //     markers[markerId] = marker;
  //   }
  // }

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

  Future addPlace(BuildContext context, String input) async {
    setState(() {
      newPlace = "";
    });
    final response = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$input&fields=name%2Cgeometry&inputtype=textquery&key=$googleAPiKey&language=$lang'));
    print(jsonDecode(response.body));
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['candidates'].length == 0) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(lang == "en" ? "Warning" : "警告"),
              content: Text(
                lang == "en"
                    ? "Did not find the place you entered, please input it again."
                    : "無法搜尋你所輸入的地方，請重新輸入。",
                style: TextStyle(color: Colors.red),
              ),
            );
          },
        );
        return;
      }
      double lat = jsonDecode(response.body)['candidates'][0]['geometry']
          ['location']['lat'];
      double lng = jsonDecode(response.body)['candidates'][0]['geometry']
          ['location']['lng'];
      if (lat < 22.15 ||
          lat > 22.58333333 ||
          lng < 113.833333 ||
          lng > 114.533333) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(lang == "en" ? "Warning" : "警告"),
              content: Text(
                lang == "en"
                    ? "The place you entered is not in Hong Kong, please input it again."
                    : "你所輸入的地方並不在香港範圍內，請重新輸入。",
                style: TextStyle(color: Colors.red),
              ),
            );
          },
        );
      } else {
        setState(() {
          checkPointName
              .add(jsonDecode(response.body)['candidates'][0]['name']);
          checkPointLat.add(lat);
          checkPointLng.add(lng);
          checkPointImage.add([]);
          // wayPointString
          //     .add(jsonDecode(response.body)['candidates'][0]['name']);
          // wayPointLatLng.add("$lat,$lng");
        });
        print(jsonDecode(response.body)['candidates'].length);
        print(checkPointName);
        print(checkPointLat);
        print(checkPointLng);
        _getPolyline();
        Navigator.of(context).pop();
      }
    } else {}
  }

  Future changePlace(BuildContext context, String input, int index) async {
    print(index);
    setState(() {
      newPlace = "";
    });
    final response = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$input&fields=name%2Cgeometry&inputtype=textquery&key=$googleAPiKey&language=$lang'));
    print(jsonDecode(response.body));
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['candidates'].length == 0) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(lang == "en" ? "Warning" : "警告"),
              content: Text(
                lang == "en"
                    ? "Did not find the place you entered, please input it again."
                    : "無法搜尋你所輸入的地方，請重新輸入。",
                style: TextStyle(color: Colors.red),
              ),
            );
          },
        );
        return;
      }
      double lat = jsonDecode(response.body)['candidates'][0]['geometry']
          ['location']['lat'];
      double lng = jsonDecode(response.body)['candidates'][0]['geometry']
          ['location']['lng'];
      if (lat < 22.15 ||
          lat > 22.58333333 ||
          lng < 113.833333 ||
          lng > 114.533333) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(lang == "en" ? "Warning" : "警告"),
              content: Text(
                lang == "en"
                    ? "The place you entered is not in Hong Kong, please input it again."
                    : "你所輸入的地方並不在香港範圍，內請重新輸入。",
                style: TextStyle(color: Colors.red),
              ),
            );
          },
        );
      } else {
        // checkPointName.add(jsonDecode(response.body)['candidates'][0]['name']);
        // checkPointLat.add(lat);
        // checkPointLng.add(lng);
        setState(() {
          print(checkPointName.toString());
          checkPointName[index] =
              (jsonDecode(response.body)['candidates'][0]['name']);
          print(checkPointLat.toString());
          checkPointLat[index] = lat;
          print(checkPointLng.toString());
          checkPointLng[index] = lng;
        });
        print(jsonDecode(response.body)['candidates'].length);
        _getPolyline();
        // print(checkPointName);
        // print(checkPointLat);
        // print(checkPointLng);
        Navigator.of(context).pop();
      }
    } else {}
  }

  Future addMaker(BuildContext context) async {
    for (int i = 0; i < checkPointName.length; i++) {
      String distance = "0 m", duration = "0 min";

      BitmapDescriptor descriptor = BitmapDescriptor.defaultMarkerWithHue(90);
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
          print(lang == "en"
              ? "distance: "
              : "距離: " +
                  jsonDecode(response.body)['rows'][0]['elements'][0]
                      ['distance']['text']);
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
                                        child:
                                            Image.file(checkPointImage[i][j]),
                                      ),
                                    ),
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: Text(
                                                lang == "en" ? "Photo" : "相片"),
                                            content: Image.file(
                                                checkPointImage[i][j]),
                                            actions: [
                                              TextButton.icon(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  setState(() {
                                                    checkPointImage[i]
                                                        .removeAt(j);
                                                  });
                                                },
                                                icon: Icon(Icons.delete),
                                                label: Text(lang == "en"
                                                    ? "Delete"
                                                    : "刪除"),
                                              ),
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
                                InkWell(
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.15,
                                    height: MediaQuery.of(context).size.width *
                                        0.15,
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
                                                  final image =
                                                      await ImagePicker()
                                                          .pickImage(
                                                              source:
                                                                  ImageSource
                                                                      .gallery);
                                                  setState(() {
                                                    checkPointImage[i]
                                                        .add(File(image!.path));
                                                    print(checkPointImage[i]
                                                        .last);
                                                  });
                                                  Navigator.pop(context);
                                                },
                                                child: Text(lang == "en"
                                                    ? "From Gallery"
                                                    : "從相片庫")),
                                            CupertinoActionSheetAction(
                                              onPressed: () async {
                                                final image =
                                                    await ImagePicker()
                                                        .pickImage(
                                                            source: ImageSource
                                                                .camera);
                                                setState(() {
                                                  checkPointImage[i]
                                                      .add(File(image!.path));
                                                  print(
                                                      checkPointImage[i].last);
                                                });
                                                Navigator.pop(context);
                                              },
                                              child: Text(lang == "en"
                                                  ? "From Camera"
                                                  : "從相機"),
                                            ),
                                          ],
                                          cancelButton:
                                              CupertinoActionSheetAction(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: Text(
                                                lang == "en" ? "Cancel" : "取消"),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
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
