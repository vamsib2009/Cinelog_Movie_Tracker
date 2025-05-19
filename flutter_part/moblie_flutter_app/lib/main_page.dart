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
                Container(height: 400, width: 200, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white), child: MovieCard(movieTitle: 'The Titanic'),),
                Container(height: 400, width: 200, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white), child: MovieCard(movieTitle: 'The Dark Knight'),),
                Container(height: 400, width: 200, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white),child: MovieCard(movieTitle: 'Bullet Train'),),
                Container(height: 400, width: 200, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white), child: MovieCard(movieTitle: 'Jersey'),),
              ],
            ),
          ),
      ),
    );
  }
}
