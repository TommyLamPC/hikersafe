import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HikingMapPage extends StatefulWidget {
  HikingMapPage({Key? key, required this.hikingId}) : super(key: key);
  String hikingId;
  @override
  _HikingMapPageState createState() => _HikingMapPageState();
}

class _HikingMapPageState extends State<HikingMapPage> {
  final Completer<GoogleMapController> _controller = Completer();
  double camLat = 22.340809, camLng = 114.179876;
  Map<MarkerId, Marker> markers = {};
  Map<PolylineId, Polyline> polylines = {
    PolylineId("poly"): Polyline(polylineId: PolylineId("poly")),
    PolylineId("livePoly"): Polyline(polylineId: PolylineId("livePoly")),
  };
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();
  List<LatLng> livePolylineCoordinates = [];
  PolylinePoints livePolylinePoints = PolylinePoints();
  List<String> checkPointName = [];
  List<double> checkPointLat = [];
  List<double> checkPointLng = [];
  List<List<String>> checkPointImage = [];
  int checkedPoint = 0;
  List<String> checkPointDistance = ["0 m"], checkPointDuration = ["0 min"];
  List<int> checkPointDistanceNum = [0], checkPointDurationNum = [0];
  String nextDistance = "0 m", nextDuration = "0 min";
  String destDistance = "0 m", destDuration = "0 min";
  String googleAPiKey = "AIzaSyBfG6onSh1iHDdGpDH_A5ukn995O-vyYX8";
  String hikingId = "", routeName = "";

  late Location location;
  late LocationData currentLocation;
  bool keepTrack = true;

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
    // calculateDistance(22.340809, 114.179876, 22.350448, 114.196811);
    super.initState();
    getLanguage();
    newMethod();
  }

  Future<void> newMethod() async {
    hikingId = widget.hikingId;
    await FirebaseFirestore.instance
        .collection('hiking')
        .doc(hikingId)
        .get()
        .then((value) async {
      checkedPoint = value.data()!['checkedPoint'];
      print("value.data()");
      print(value.data());
      await FirebaseFirestore.instance
          .collection('routes')
          .doc(value.data()!['routeId'])
          .get()
          .then((val) {
        print("val.data()");
        print(val.data());
        for (int i = 0; i < val.data()!['checkpoints'].length; i++) {
          checkPointName.add(val.data()!['checkpoints'][i]['checkPointName']);
          checkPointLat.add(val.data()!['checkpoints'][i]['checkPointLat']);
          checkPointLng.add(val.data()!['checkpoints'][i]['checkPointLng']);
          checkPointImage.add([]);
          for (int j = 0;
              j < val.data()!['checkpoints'][i]['checkPointImage'].length;
              j++) {
            checkPointImage[i]
                .add(val.data()!['checkpoints'][i]['checkPointImage'][j]);
          }
          routeName = val.data()!['name'];
        }
      });
    });

    _getLivePolyline();
    _getPolyline();
    getCheckpointDistance();
    print("getNextCheckpointDistance[1]:$checkedPoint");
    getNextCheckpointDistance();

    location = new Location();
    location.onLocationChanged.listen((LocationData cLoc) async {
      print("location.onLocationChanged");
      camLat = cLoc.latitude!;
      camLng = cLoc.longitude!;

      // print("checkedPoint:$checkedPoint");
      // print("checkPointName.length:${checkPointName.length}");
      // print(
      //     "checkedPoint < checkPointName.length:${checkedPoint < checkPointName.length}");
      if (checkedPoint < checkPointName.length) {
        FirebaseFirestore.instance
            .collection('hiking')
            .doc(hikingId)
            .update({'lat': camLat, 'lng': camLng});
        if (calculateDistance(
              camLat,
              camLng,
              checkPointLat[checkedPoint],
              checkPointLng[checkedPoint],
            ) <=
            100)
          await FirebaseFirestore.instance
              .collection('hiking')
              .doc(hikingId)
              .update({'checkedPoint': ++checkedPoint});

        if (checkedPoint == checkPointName.length) {
          await FirebaseFirestore.instance
              .collection('hiking')
              .doc(hikingId)
              .delete();
          showDialog(
            barrierDismissible: false,
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(lang == "en"
                    ? "You Complete Your Hiking Route!"
                    : "?????????????????????????????????"),
                content: Text(lang == "en" ? "Please Click Finish." : "??????????????????"),
                actions: [
                  TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.done),
                      label: Text(lang == "en" ? "Finish!" : "?????????"))
                ],
              );
            },
          );
        }
        print("getNextCheckpointDistance[2]:$checkedPoint");
        getNextCheckpointDistance();
        _getLivePolyline();
      }
      if (keepTrack) {
        updateLocOnMap();
      }
    });

    setInitialLocation();
  }

  void setInitialLocation() async {
    currentLocation = await location.getLocation();
    camLat = currentLocation.latitude!;
    camLng = currentLocation.longitude!;
    FirebaseFirestore.instance
        .collection('hiking')
        .doc(hikingId)
        .update({'lat': camLat, 'lng': camLng});
    CameraPosition cPosition =
        CameraPosition(target: LatLng(camLat, camLng), zoom: 18, tilt: 80);
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(cPosition));
  }

  void updateLocOnMap() async {
    CameraPosition cPosition =
        CameraPosition(target: LatLng(camLat, camLng), zoom: 18, tilt: 80);
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(cPosition));
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.redAccent,
        title: Text(routeName),
        leading: IconButton(
          onPressed: () async {
            await FirebaseFirestore.instance
                .collection('hiking')
                .doc(hikingId)
                .delete();
            Navigator.pop(context);
          },
          icon: Icon(Icons.logout),
        ),
      ),
      body: Stack(
        alignment: AlignmentDirectional.bottomCenter,
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
                target: LatLng(camLat, camLng), zoom: 18, tilt: 80),
            myLocationEnabled: true,
            tiltGesturesEnabled: true,
            compassEnabled: true,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            markers: Set<Marker>.of(markers.values),
            polylines: Set<Polyline>.of(polylines.values),
            circles: Set.from([
              Circle(
                  circleId: CircleId("id"),
                  center: LatLng(camLat, camLng),
                  fillColor: Colors.blue.withOpacity(0.3),
                  strokeWidth: 3,
                  strokeColor: Colors.blue,
                  radius: 100 //radius
                  )
            ]),
          ),
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              // height: MediaQuery.of(context).size.height * 0.25,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang == "en" ? "Your Coordinates: " : "????????????: ",
                        style: TextStyle(
                          fontSize: 25,
                          fontFamily: "OpenSan",
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "$camLat, $camLng",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 25,
                          fontFamily: "OpenSan",
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Divider(color: Colors.black),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              keepTrack = !keepTrack;
                              if (keepTrack) updateLocOnMap();
                            });
                          },
                          icon: Icon(Icons.map),
                          label: Text(
                              "${lang == "en" ? "Tracking" : "??????"}: ${keepTrack ? lang == "en" ? "On" : "???" : lang == "en" ? "Off" : "???"}"),
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                                keepTrack ? Colors.orange : Colors.grey),
                            foregroundColor: MaterialStateProperty.all<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return StatefulBuilder(
                                  builder: (context, setState) {
                                    return AlertDialog(
                                      title: Text(
                                        lang == "en" ? "Hiking Detail" : "????????????",
                                        style: TextStyle(
                                          fontSize: 30,
                                          fontFamily: "OpenSan",
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              lang == "en"
                                                  ? "Your Coordinates: "
                                                  : "????????????: ",
                                              style: TextStyle(
                                                fontSize: 25,
                                                fontFamily: "OpenSan",
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "$camLat,\n$camLng",
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 25,
                                                fontFamily: "OpenSan",
                                                // fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Divider(color: Colors.black),
                                            if (checkedPoint != 0)
                                              Text(
                                                lang == "en"
                                                    ? "Previous Checkpoint: "
                                                    : "??????????????????",
                                                style: TextStyle(
                                                  fontSize: 25,
                                                  fontFamily: "OpenSan",
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            if (checkedPoint != 0)
                                              Text(
                                                checkPointName[
                                                    checkedPoint - 1],
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 25,
                                                  fontFamily: "OpenSan",
                                                  // fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            if (checkedPoint != 0)
                                              Divider(color: Colors.black),
                                            Text(
                                              lang == "en"
                                                  ? "Next Checkpoint: "
                                                  : "??????????????????",
                                              style: TextStyle(
                                                fontSize: 25,
                                                fontFamily: "OpenSan",
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              checkPointName[checkedPoint],
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 25,
                                                fontFamily: "OpenSan",
                                                // fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Divider(color: Colors.black),
                                            Text(
                                              lang == "en"
                                                  ? "Distance To Next Checkpoint: "
                                                  : "??????????????????????????????: ",
                                              style: TextStyle(
                                                fontSize: 25,
                                                fontFamily: "OpenSan",
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "$nextDistance ($nextDuration)",
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 25,
                                                fontFamily: "OpenSan",
                                                // fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Divider(color: Colors.black),
                                            Text(
                                              lang == "en"
                                                  ? "Distance To Destination: "
                                                  : "??????????????????: ",
                                              style: TextStyle(
                                                fontSize: 25,
                                                fontFamily: "OpenSan",
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "$destDistance ($destDuration)",
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 25,
                                                fontFamily: "OpenSan",
                                                // fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton.icon(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          icon: Icon(Icons.done),
                                          label:
                                              Text(lang == "en" ? "OK" : "???"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                          icon: Icon(Icons.info),
                          label: Text(lang == "en" ? "Show Detail" : "????????????"),
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all<Color>(Colors.blue),
                            foregroundColor: MaterialStateProperty.all<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.live_help),
                          label: Text(lang == "en" ? "Get Help" : "??????"),
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all<Color>(Colors.red),
                            foregroundColor: MaterialStateProperty.all<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    print(12742000 * asin(sqrt(a)));
    return 12742000 * asin(sqrt(a));
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

    addMaker(context);
    if (checkPointName.length >= 2) {
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
          googleAPiKey,
          PointLatLng(checkPointLat[0], checkPointLng[0]),
          PointLatLng(checkPointLat[checkPointName.length - 1],
              checkPointLng[checkPointName.length - 1]),
          travelMode: TravelMode.walking,
          wayPoints: [
            for (int i = 0; i < checkPointName.length; i++)
              PolylineWayPoint(
                  location: "${checkPointLat[i]},${checkPointLng[i]}"),
          ]);
      if (result.points.isNotEmpty) {
        result.points.forEach((PointLatLng point) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        });
      }
      PolylineId id = PolylineId("poly");
      Polyline polyline = Polyline(
          polylineId: id, color: Colors.grey, points: polylineCoordinates);
      polylines[id] = polyline;
      setState(() {});
    }
  }

  _getLivePolyline() async {
    // markers = {};
    livePolylineCoordinates = [];
    livePolylinePoints = PolylinePoints();
    print("_getPolyline");
    if (checkPointName.length == 0) {
      return;
    }

    addMaker(context);
    if (checkPointName.length >= 2) {
      PolylineResult result = await livePolylinePoints
          .getRouteBetweenCoordinates(
              googleAPiKey,
              PointLatLng(camLat, camLng),
              PointLatLng(checkPointLat[checkPointName.length - 1],
                  checkPointLng[checkPointName.length - 1]),
              travelMode: TravelMode.walking,
              wayPoints: [
            for (int i = checkedPoint; i < checkPointName.length; i++)
              PolylineWayPoint(
                  location: "${checkPointLat[i]},${checkPointLng[i]}"),
          ]);
      if (result.points.isNotEmpty) {
        result.points.forEach((PointLatLng point) {
          livePolylineCoordinates.add(LatLng(point.latitude, point.longitude));
        });
      }
      PolylineId id = PolylineId("livePoly");
      Polyline polyline = Polyline(
          polylineId: id, color: Colors.blue, points: livePolylineCoordinates);
      polylines[id] = polyline;
      print("polylines");
      print(polylines);
      setState(() {});
    }
  }

  getCheckpointDistance() async {
    for (int i = 1; i < checkPointName.length; i++) {
      final response = await http.get(Uri.parse(
          'https://maps.googleapis.com/maps/api/distancematrix/json?destinations='
          '${checkPointLat[i]},${checkPointLng[i]}'
          '&origins='
          '${checkPointLat[i - 1]},${checkPointLng[i - 1]}'
          '&mode=walking&key=$googleAPiKey&language=$lang'));
      print(jsonDecode(response.body));
      if (response.statusCode == 200) {
        setState(() {
          print("distance: " +
              jsonDecode(response.body)['rows'][0]['elements'][0]['distance']
                  ['text']);
          checkPointDistance.add(jsonDecode(response.body)['rows'][0]
              ['elements'][0]['distance']['text']);
          checkPointDistanceNum.add(jsonDecode(response.body)['rows'][0]
              ['elements'][0]['distance']['value']);
          print("duration: " +
              jsonDecode(response.body)['rows'][0]['elements'][0]['distance']
                  ['text']);
          checkPointDuration.add(jsonDecode(response.body)['rows'][0]
              ['elements'][0]['duration']['text']);
          checkPointDurationNum.add(jsonDecode(response.body)['rows'][0]
              ['elements'][0]['duration']['value']);
          print("checkPointDistanceNum.length");
          print(checkPointDistanceNum.length);
          if (checkPointDistanceNum.length == checkPointName.length &&
              checkPointDurationNum.length == checkPointName.length) {
            print("getNextCheckpointDistance[3]:$checkedPoint");
            getNextCheckpointDistance();
          }
        });
      }
    }
  }

  getNextCheckpointDistance() async {
    print("getNextCheckpointDistance:checkedPoint:$checkedPoint");
    final response = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/distancematrix/json?destinations='
        '${camLat},${camLng}'
        '&origins='
        '${checkPointLat[checkedPoint]},${checkPointLng[checkedPoint]}'
        '&mode=walking&key=$googleAPiKey&language=$lang'));
    print(jsonDecode(response.body));
    if (response.statusCode == 200) {
      String unit;
      int unitNum;
      setState(() {
        num tempNextDistance = jsonDecode(response.body)['rows'][0]['elements']
            [0]['distance']['value'];
        if (tempNextDistance < 1000) {
          unit = lang == "en" ? " m" : "???";
          unitNum = 1;
        } else {
          unit = lang == "en" ? " km" : "??????";
          unitNum = 1000;
        }
        nextDistance =
            (tempNextDistance / unitNum).toStringAsFixed(2).toString() + unit;
        num tempNextDuration = jsonDecode(response.body)['rows'][0]['elements']
            [0]['duration']['value'];
        nextDuration =
            (tempNextDuration / 60).toStringAsFixed(0).toString() + " min";
        num tempDestDistance = tempNextDistance,
            tempDestDuration = tempNextDuration;
        if (checkPointDistanceNum.length == checkPointName.length &&
            checkPointDurationNum.length == checkPointName.length) {
          print("checkPointName[i]");
          print("$tempDestDistance &  $tempDestDuration");
          for (int i = checkedPoint; i < checkPointName.length; i++) {
            tempDestDistance += checkPointDistanceNum[i];
            tempDestDuration += checkPointDurationNum[i];
            print(checkPointName[i]);
            print("$tempDestDistance &  $tempDestDuration");
          }
          if (tempDestDistance < 1000) {
            unit = lang == "en" ? " m" : "???";
            unitNum = 1;
          } else {
            unit = lang == "en" ? " km" : "??????";
            unitNum = 1000;
          }
          destDistance =
              (tempDestDistance / unitNum).toStringAsFixed(2).toString() + unit;
          destDuration =
              (tempDestDuration / 60).toStringAsFixed(0).toString() + " min";
        }

        print("nextDistance + nextDuration");
        print(nextDistance + nextDuration);
        print("destDistance + destDuration");
        print(destDistance + destDuration);
      });
    }
  }

  Future addMaker(BuildContext context) async {
    for (int i = 0; i < checkPointName.length; i++) {
      String distance = "0 m", duration = "0 min";

      BitmapDescriptor descriptor;
      if (i == checkedPoint) {
        descriptor =
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta);
      } else if (i == checkPointName.length - 1) {
        descriptor = BitmapDescriptor.defaultMarker;
      } else if (i == 0) {
        descriptor =
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      } else if (i < checkedPoint) {
        descriptor =
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      } else {
        descriptor = BitmapDescriptor.defaultMarkerWithHue(200);
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
        snippet: lang == "en" ? "Click for more infomation" : "???????????????????????????",
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
                            "${lang == "en" ? "Distance" : "??????"}: ${checkPointDistance[i]}",
                            style: TextStyle(fontSize: 15),
                          ),
                          Text(
                            "${lang == "en" ? "Duration" : "??????"}: ${checkPointDuration[i]}",
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
                                                lang == "en" ? "Photo" : "??????"),
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
                                                      : "???")),
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
                          // Center(
                          //   child: Wrap(
                          //     alignment: WrapAlignment.start,
                          //     children: [
                          //       for (int j = 0;
                          //           j < checkPointImage[i].length;
                          //           j++)
                          //         InkWell(
                          //           child: SizedBox(
                          //             width: MediaQuery.of(context).size.width *
                          //                 0.15,
                          //             height:
                          //                 MediaQuery.of(context).size.width *
                          //                     0.15,
                          //             child: Card(
                          //               child:
                          //                   Image.file(checkPointImage[i][j]),
                          //             ),
                          //           ),
                          //           onTap: () {
                          //             showDialog(
                          //               context: context,
                          //               builder: (context) {
                          //                 return AlertDialog(
                          //                   title: Text("Photo"),
                          //                   content: Image.file(
                          //                       checkPointImage[i][j]),
                          //                   actions: [
                          //                     TextButton.icon(
                          //                       onPressed: () {
                          //                         Navigator.pop(context);
                          //                         setState(() {
                          //                           checkPointImage[i]
                          //                               .removeAt(j);
                          //                         });
                          //                       },
                          //                       icon: Icon(Icons.delete),
                          //                       label: Text("Delete"),
                          //                     ),
                          //                     TextButton.icon(
                          //                       onPressed: () {
                          //                         Navigator.pop(context);
                          //                       },
                          //                       icon: Icon(Icons.check),
                          //                       label: Text("Ok"),
                          //                     ),
                          //                   ],
                          //                 );
                          //               },
                          //             );
                          //           },
                          //         ),
                          //       InkWell(
                          //         child: SizedBox(
                          //           width: MediaQuery.of(context).size.width *
                          //               0.15,
                          //           height: MediaQuery.of(context).size.width *
                          //               0.15,
                          //           child: Card(
                          //             color: Colors.grey[300],
                          //             child: Icon(Icons.add),
                          //           ),
                          //         ),
                          //         onTap: () async {
                          //           showCupertinoModalPopup(
                          //             context: context,
                          //             builder: (context) {
                          //               return CupertinoActionSheet(
                          //                 actions: [
                          //                   CupertinoActionSheetAction(
                          //                       onPressed: () async {
                          //                         final image =
                          //                             await ImagePicker()
                          //                                 .pickImage(
                          //                                     source:
                          //                                         ImageSource
                          //                                             .gallery);
                          //                         setState(() {
                          //                           checkPointImage[i]
                          //                               .add(File(image!.path));
                          //                           print(checkPointImage[i]
                          //                               .last);
                          //                         });
                          //                         Navigator.pop(context);
                          //                       },
                          //                       child: Text("From Gallery")),
                          //                   CupertinoActionSheetAction(
                          //                     onPressed: () async {
                          //                       final image =
                          //                           await ImagePicker()
                          //                               .pickImage(
                          //                                   source: ImageSource
                          //                                       .camera);
                          //                       setState(() {
                          //                         checkPointImage[i]
                          //                             .add(File(image!.path));
                          //                         print(
                          //                             checkPointImage[i].last);
                          //                       });
                          //                       Navigator.pop(context);
                          //                     },
                          //                     child: Text("From Camera"),
                          //                   ),
                          //                 ],
                          //                 cancelButton:
                          //                     CupertinoActionSheetAction(
                          //                   onPressed: () {
                          //                     Navigator.pop(context);
                          //                   },
                          //                   child: Text("Cancel"),
                          //                 ),
                          //               );
                          //             },
                          //           );
                          //         },
                          //       ),
                          //       for (int z = checkPointImage[i].length;
                          //           z < 3;
                          //           z++)
                          //         SizedBox(
                          //           width: MediaQuery.of(context).size.width *
                          //               0.15,
                          //         ),
                          //     ],
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.check),
                        label: Text(lang == "en" ? "OK" : "???"),
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
