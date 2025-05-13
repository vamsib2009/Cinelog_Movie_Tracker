import 'package:flutter/material.dart';
import 'main_page.dart'; // This is where MyHomePage is defined

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
      home: const MyHomePage(title: 'Movie Application Page'),
    );
  }
}




