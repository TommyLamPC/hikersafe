import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'route_info.dart';

class SearchRoutePage extends StatefulWidget {
  const SearchRoutePage({Key? key}) : super(key: key);

  @override
  _SearchRoutePageState createState() => _SearchRoutePageState();
}

class Route {
  late String cnName, engName, cnDistrict, engDistrict;
  Route(cnName, engName, cnDistrict, engDistrict) {
    this.cnName = cnName;
    this.engName = engName;
    this.cnDistrict = cnDistrict;
    this.engDistrict = engDistrict;
  }
}

class _SearchRoutePageState extends State<SearchRoutePage> {
  List<Route> route = [
    // Route("蝌蚪坪", "FO DAU PING", "沙田", "Sha Tin"),
    // Route("尖風山", "HEBE HILL", "西貢", "Sai Kung"),
    // Route("大埔滘黃徑", "TAI PO KAU YELLOW WALK", "大埔", "Tai Po"),
    // Route("獅子山", "LION ROCK", "黃大仙", "Wong Tai Sin"),
    // Route("大上托", "TAI SHEUNG TOK", "西貢", "Sai Kung"),
    // Route("大老山", "TATE'S CAIRN", "黃大仙", "Wong Tai Sin"),
    // Route("摩星嶺", "MOUNT DAVIS", "中西區", "Central and Western"),
    // Route("太平山", "Victoria_Peak", "中西區", "Central and Western"),
    // Route("渣甸山", "Jardines Lookout", "灣仔區", "Wan Chai"),
    // Route("龍脊", "Dragons Back", "南區", "Southern"),
  ];
  List<Widget> routeWidget = [];
  TextEditingController searchValue = TextEditingController();
  @override
  void initState() {
    super.initState();
    getLanguage();
    setRoute();
    FirebaseFirestore.instance.collection("routes").snapshots().listen((event) {
      event.docs.forEach((element) {
        setRouteWidget(element.data(), element.id);
        route.add(
            Route(element.data()['name'], "", element.data()['district'], ""));
      });
    });
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
        title: TextField(
          controller: searchValue,
          decoration: InputDecoration(
            // border: OutlineInputBorder(),
            labelText: lang == "en" ? 'Keyword to Search Route' : "搜尋路線關鍵字",
            // labelStyle: TextStyle(
            //   color: Colors.white,
            // ),
          ),
          onChanged: (value) => setState(() {}),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              for (int i = 0; i < route.length; i++)
                if (route[i]
                        .cnDistrict
                        .toLowerCase()
                        .contains(searchValue.text.toLowerCase()) ||
                    route[i]
                        .engDistrict
                        .toLowerCase()
                        .contains(searchValue.text.toLowerCase()) ||
                    route[i]
                        .cnName
                        .toLowerCase()
                        .contains(searchValue.text.toLowerCase()) ||
                    route[i]
                        .engName
                        .toLowerCase()
                        .contains(searchValue.text.toLowerCase()))
                  routeWidget[i]
            ],
          ),
        ),
      ),
    );
  }

  setRoute() {
    for (int i = 0; i < route.length; i++) {
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
                              route[i].cnName,
                              style: TextStyle(
                                fontSize: 40,
                                fontFamily: "OpenSan",
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              route[i].engName,
                              style: TextStyle(
                                fontSize: 20,
                                fontFamily: "OpenSan",
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              route[i].cnDistrict,
                              style: TextStyle(
                                fontSize: 30,
                                fontFamily: "OpenSan",
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              route[i].engDistrict,
                              style: TextStyle(
                                fontSize: 15,
                                fontFamily: "OpenSan",
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // onTap: () {
                //   Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //       builder: (context) => RouteInfoPage(
                //         routeId: "",
                //       ),
                //     ),
                //   );
                // },
              ),
            ),
          ),
        );
      });
    }
  }

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
