// import 'dart:ffi';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hikersafe/google_sign_in.dart';
import 'package:hikersafe/home_page.dart';
import 'package:provider/provider.dart';
import 'login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) => GoogleSignInProvider(),
        child: MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            bottomSheetTheme: BottomSheetThemeData(
                backgroundColor: Colors.black.withOpacity(0)),
          ),
          home: HomePage(),
        ),
      );
}
