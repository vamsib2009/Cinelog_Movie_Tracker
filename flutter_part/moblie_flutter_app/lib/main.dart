import 'package:flutter/material.dart';
import 'login.dart'; //where we display the first login page
import 'package:flutter_dotenv/flutter_dotenv.dart';


void main() {
  dotenv.load(fileName: ".env");
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
      color: Color(0xFF0D1B2A),
      home: LoginPage(), //MyHomePage(title: 'Movie Application Page'),
    );
  }
}
