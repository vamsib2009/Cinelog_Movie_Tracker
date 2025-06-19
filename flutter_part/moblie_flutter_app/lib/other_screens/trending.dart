import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:moblie_flutter_app/movie_card.dart';
import 'package:moblie_flutter_app/movie_details.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Trending extends StatefulWidget {
  const Trending({
    super.key,
  });

  @override
  _TrendingPageState createState() => _TrendingPageState();
}

class _TrendingPageState extends State<Trending> {
  List<Map<String, dynamic>> allMovieData = [];

  @override
  void initState() {
    super.initState();
    fetchTrendingMovies();
  }

  Future<void> fetchTrendingMovies() async {
    final fetchMovieUrl = Uri.parse('http://10.0.2.2:8080/api/trending');
    try {
      final response = await http.get(fetchMovieUrl);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          allMovieData = data.map<Map<String, dynamic>>((json) {
            return {
              'id': json['id']?.toString() ?? '',
              'name': json['name']?.toString() ?? '',
              'description': json['description'] ?? '',
              'directorName': json['directorName']?.toString() ?? '',
              'category': json['category'] ?? '',
              'imdbrating': json['imdbrating'] ?? 0.0,
              'releaseDate': json['releaseDate']?.toString() ?? '',
              'language': json['language'] ?? '',
              'country': json['country'] ?? '',
              'actorNames': List<String>.from(json['actorNames'] ?? []),
              'tags': List<String>.from(json['tags'] ?? []),
            };
          }).toList();
          print(allMovieData[1]['name']);
        });
      } else {
        print('Failed to fetch movies. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching movies: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main Body
        Padding(
          padding: const EdgeInsets.only(
              left: 12.0, right: 12.0, top: 12.0, bottom: 85),
          child: RefreshIndicator(
            onRefresh: fetchTrendingMovies,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: allMovieData.map((rd) {
                      return Container(
                        height: 370,
                        width: 175,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                        child: InkWell(
                          onTap: () {
                            // Function to log the click
                            addlogfx(rd['id']);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      MovieDetails(allMovieData: rd)),
                            );
                          },
                          child: MovieCard(allMovieData: rd),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> addlogfx(var movieId) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int? userId = prefs.getInt('userId');

  final loggingendpoint = Uri.http('10.0.2.2:8080', 'logging/add', {
    'userId': userId.toString(),
    'movieId': movieId.toString(),
  });

  try {
    final response = await http.post(loggingendpoint);
    print(response.statusCode);
  } catch (e) {
    print('Error login: $e');
  }
}
