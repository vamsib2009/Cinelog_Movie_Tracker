import 'package:flutter/material.dart';
import 'login.dart'; //where we display the first login page

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie Application',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      color: Colors.grey,
      home: LoginPage(), //MyHomePage(title: 'Movie Application Page'),
    );
  }
}




