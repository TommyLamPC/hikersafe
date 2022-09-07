import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hikersafe/bottom_navigation_controller.dart';
import 'package:hikersafe/login.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
        body: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasData) {
              return BottomNavigation();
            } else if (snapshot.hasError) {
              return Center(child: Text("Error"));
            } else {
              return LoginPage();
            }
          },
        ),
      );
}
