import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MovieCard extends StatelessWidget {
  final String movieTitle;
  late String directorName;

  MovieCard({super.key, required this.movieTitle,});

  Future<String> fetchPoster(String title) async {
    const apiKey = '2774b611';
    final url = 'http://www.omdbapi.com/?t=$title&apikey=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      directorName = data['Director'];
      return data['Poster'] ?? '';
    } else {
      throw Exception('Failed to load poster');
    }
  }

  @override
  Widget build(BuildContext context) {
    final picProfile =
        'https://images.pexels.com/photos/771742/pexels-photo-771742.jpeg?auto=compress&cs=tinysrgb&w=600';

    return FutureBuilder<String>(
      future: fetchPoster(movieTitle),
      builder: (context, snapshot) {
        Widget background;

        if (snapshot.connectionState == ConnectionState.waiting) {
          background = Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError || snapshot.data == null || snapshot.data == '') {
          background = Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [Colors.deepPurple, Colors.orangeAccent],
              ),
            ),
            child: const Center(child: Text("Failed to load image")),
          );
        } else {
          background = Container(
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [Colors.deepPurple, Colors.orangeAccent],
              ),
              image: DecorationImage(
                image: NetworkImage(snapshot.data!),
                fit: BoxFit.fitWidth,
                opacity: 0.8,
                alignment: Alignment.center,
              ),
            ),
          );
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            background,
            Positioned(
              top: 175,
              left: 20,
              right: 20,
              child: Center(
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      const BoxShadow(color: Colors.white, spreadRadius: 4),
                    ],
                    image: DecorationImage(
                      image: NetworkImage(picProfile),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
