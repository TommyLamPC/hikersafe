// import 'dart:ffi';

import 'package:flutter/material.dart';

class Register extends StatelessWidget {
  const Register({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: Text("Register"),
      ),
      body: SizedBox(
        width: double.infinity,
        // height: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Expanded(
                    flex: 1,
                    child: Text(
                      "Name: ",
                      style: TextStyle(
                        // color: Colors.white,
                        fontSize: 25,
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
                        labelText: 'Name',
                        labelStyle: TextStyle(
                            // color: Colors.white,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: const [
                  Expanded(
                    flex: 1,
                    child: Text(
                      "Email: ",
                      style: TextStyle(
                        // color: Colors.white,
                        fontSize: 25,
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
                        labelText: 'Email Address',
                        labelStyle: TextStyle(
                            // color: Colors.white,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: const [
                  Expanded(
                    flex: 1,
                    child: Text(
                      "Password: ",
                      style: TextStyle(
                        // color: Colors.white,
                        fontSize: 25,
                        fontFamily: "OpenSan",
                        // fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Password',
                        labelStyle: TextStyle(
                            // color: Colors.white,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: const [
                  Expanded(
                    flex: 1,
                    child: Text(
                      "Password Again: ",
                      style: TextStyle(
                        // color: Colors.white,
                        fontSize: 25,
                        fontFamily: "OpenSan",
                        // fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Password Again',
                        labelStyle: TextStyle(
                            // color: Colors.white,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: const [
                  Expanded(
                    flex: 1,
                    child: Text(
                      "Phone Number: ",
                      style: TextStyle(
                        // color: Colors.white,
                        fontSize: 25,
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
                        labelText: 'Email Address',
                        labelStyle: TextStyle(
                            // color: Colors.white,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {},
                  child: const Text("Send me a Email"),
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
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  "OR",
                  style: TextStyle(
                    // color: Colors.white,
                    fontSize: 25,
                    fontFamily: "OpenSan",
                    // fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {},
                  child: const Text("Send me a SMS"),
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
      ),
    );
  }
}
