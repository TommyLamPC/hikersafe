// import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:hikersafe/google_sign_in.dart';
import 'package:provider/provider.dart';

// GoogleSignIn _googleSignIn = GoogleSignIn(
//   scopes: <String>['email'],
// );

// class Login extends StatelessWidget {
//   const Login({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         bottomSheetTheme:
//             BottomSheetThemeData(backgroundColor: Colors.black.withOpacity(0)),
//       ),
//       home: const LoginPage(),
//     );
//   }
// }

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.redAccent,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.hiking_rounded,
                color: Colors.white,
                size: 250,
              ),
              const Text(
                "HikeSafe",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 50,
                  fontFamily: "OpenSan",
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 30, right: 30, top: 200),
                child: Column(
                  children: [
                    // Card(
                    //   color: Colors.white.withOpacity(0.1),
                    //   child: Padding(
                    //     padding: const EdgeInsets.all(8.0),
                    //     child: Column(
                    //       crossAxisAlignment: CrossAxisAlignment.start,
                    //       children: [
                    //         Text(
                    //           "Email: ",
                    //           style: TextStyle(
                    //             color: Colors.white,
                    //             fontSize: 30,
                    //             fontFamily: "OpenSan",
                    //             // fontWeight: FontWeight.bold,
                    //           ),
                    //         ),
                    //         TextField(
                    //           decoration: InputDecoration(
                    //             border: OutlineInputBorder(),
                    //             labelText: 'Email Address',
                    //             labelStyle: TextStyle(
                    //               color: Colors.white,
                    //             ),
                    //           ),
                    //           onChanged: (input) {
                    //             emailAddress = input;
                    //             print(emailAddress == "iLoveHiking@gmail.com");
                    //           },
                    //         ),
                    //         Text(
                    //           "Password: ",
                    //           style: TextStyle(
                    //             color: Colors.white,
                    //             fontSize: 30,
                    //             fontFamily: "OpenSan",
                    //             // fontWeight: FontWeight.bold,
                    //           ),
                    //         ),
                    //         TextField(
                    //           obscureText: true,
                    //           decoration: InputDecoration(
                    //             border: OutlineInputBorder(),
                    //             labelText: 'Password',
                    //             labelStyle: TextStyle(
                    //               color: Colors.white,
                    //             ),
                    //           ),
                    //           onChanged: (input) {
                    //             password = input;
                    //             print(password == "H1234567");
                    //           },
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(height: 20),
                    // Row(
                    //   children: [
                    //     Expanded(
                    //       child: TextButton(
                    //         onLongPress: () {
                    //           Navigator.push(
                    //             context,
                    //             MaterialPageRoute(
                    //                 builder: (context) => BottomNavigation()),
                    //           );
                    //         },
                    //         onPressed: () {
                    //           if (emailAddress == "iLoveHiking@gmail.com" &&
                    //               password == "H1234567") {
                    //             Navigator.push(
                    //               context,
                    //               MaterialPageRoute(
                    //                   builder: (context) => BottomNavigation()),
                    //             );
                    //           } else {
                    //             showDialog(
                    //               context: context,
                    //               builder: (context) {
                    //                 return AlertDialog(
                    //                   title: Text("Login Failed"),
                    //                   content: Text(
                    //                       "Please check the email address and password you entered."),
                    //                   actions: [
                    //                     TextButton(
                    //                       onPressed: () {
                    //                         Navigator.pop(context);
                    //                       },
                    //                       child: Text("OK"),
                    //                     ),
                    //                   ],
                    //                 );
                    //               },
                    //             );
                    //           }
                    //         },
                    //         child: const Text("Login"),
                    //         style: TextButton.styleFrom(
                    //           backgroundColor: Colors.blueAccent,
                    //           primary: Colors.white,
                    //           textStyle: const TextStyle(
                    //             fontSize: 20,
                    //             fontFamily: "OpenSan",
                    //             fontWeight: FontWeight.bold,
                    //           ),
                    //         ),
                    //       ),
                    //     ),
                    //     const SizedBox(
                    //       width: 10,
                    //     ),
                    //     Expanded(
                    //       child: TextButton(
                    //         onPressed: () {
                    //           Navigator.push(
                    //             context,
                    //             MaterialPageRoute(
                    //                 builder: (context) =>
                    //                     const ResetPassword()),
                    //           );
                    //         },
                    //         child: const Text("Reset Password"),
                    //         style: TextButton.styleFrom(
                    //           backgroundColor: Colors.grey,
                    //           primary: Colors.white,
                    //           textStyle: const TextStyle(
                    //             fontSize: 20,
                    //             fontFamily: "OpenSan",
                    //             fontWeight: FontWeight.bold,
                    //           ),
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    // SizedBox(
                    //   width: double.infinity,
                    //   child: TextButton(
                    //     onPressed: () {
                    //       Navigator.push(
                    //         context,
                    //         MaterialPageRoute(
                    //             builder: (context) => const Register()),
                    //       );
                    //     },
                    //     child: const Text("Sign Up"),
                    //     style: TextButton.styleFrom(
                    //       backgroundColor: Colors.green,
                    //       primary: Colors.white,
                    //       textStyle: const TextStyle(
                    //         fontSize: 20,
                    //         fontFamily: "OpenSan",
                    //         fontWeight: FontWeight.bold,
                    //       ),
                    //     ),
                    //   ),
                    // ),

                    // _currentUser != null
                    //     ? Text("${_currentUser!.displayName}")
                    //     : SizedBox(),

                    // _currentUser != null
                    //     ? Text("${_currentUser!.email}")
                    //     : SizedBox(),
                    // _currentUser != null
                    //     ? Text("${_currentUser!.id}")
                    //     : SizedBox(),
                    // _currentUser != null ? photo : SizedBox(),

                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () async {
                          final provider = Provider.of<GoogleSignInProvider>(
                              context,
                              listen: false);
                          provider.googleLogin();
                        },
                        icon: Icon(Icons.login),
                        label: Text("Login from Google"),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.green,
                          primary: Colors.white,
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontFamily: "OpenSan",
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
