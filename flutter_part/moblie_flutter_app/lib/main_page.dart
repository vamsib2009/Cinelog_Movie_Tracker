import 'package:flutter/material.dart';
import 'movie_card.dart';

class MyHomePage extends StatelessWidget {
  final String title;

  const MyHomePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      backgroundColor: const Color.fromARGB(115, 158, 158, 158),
      body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              //crossAxisAlignment: CrossAxisAlignment.start,
              direction: Axis.vertical,
              spacing: 20,
              runSpacing: 20,
              children: [
                Container(height: 300, width: 200,child: MovieCard(movieTitle: 'Titanic'),),
                Container(height: 300, width: 200,child: MovieCard(movieTitle: 'The Dark Knight'),),
                Container(height: 300, width: 200,child: MovieCard(movieTitle: 'Bullet Train'),),
                Container(height: 300, width: 200,child: MovieCard(movieTitle: 'Jersey'),),
              ],
            ),
          ),
      ),
    );
  }
}
