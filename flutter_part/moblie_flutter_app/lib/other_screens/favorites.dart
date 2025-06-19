import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:moblie_flutter_app/movie_card.dart';
import 'package:moblie_flutter_app/movie_details.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Favorite extends StatefulWidget {
  const Favorite({
    super.key,
  });

  @override
  _FavoritePageState createState() => _FavoritePageState();
}

class _FavoritePageState extends State<Favorite> {
  List<Map<String, dynamic>> allMovieData = [];

  @override
  void initState() {
    super.initState();
    fetchFavoriteMovies();
  }

  Future<void> fetchFavoriteMovies() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('userId');

    final fetchMovieUrl = Uri.http('10.0.2.2:8080', 'favorites/get', {
      'userId': userId.toString(),
    });
    try {
      final response = await http.post(fetchMovieUrl);

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
        });
      } else {
        print('Failed to fetch movies. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching movies: $e');
    }
  }

  Future<void> removeFavoriteMovie(String movieId, BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('userId');

    final fetchMovieUrl = Uri.http('10.0.2.2:8080', 'favorites/delete',
        {'userId': userId.toString(), 'movieId': movieId.toString()});
    try {
      final response = await http.post(fetchMovieUrl);

      if (response.statusCode == 200) {
        //List<dynamic> data = json.decode(response.body);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Removed from favorites')));
        setState(() {
          fetchFavoriteMovies();
        });
      } else {
        print(
            'Failed to remove movie from favorites. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error removing movies: $e');
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
            onRefresh: fetchFavoriteMovies,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                constraints: BoxConstraints(minHeight: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      child: Wrap(
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
                              child: SizedBox(
                                width:150,
                                height:300,
                                child: Stack(children: [
                                  Positioned.fill(child: MovieCard(allMovieData: rd)),
                                  Positioned(
                                    bottom:4,
                                    right: 4,
                                    child: Container(
                                      width: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.5), shape: BoxShape.circle),
                                      child: IconButton(
                                        splashColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        tooltip: 'Remove from favorites',
                                        icon: Icon(
                                          Icons.close,
                                          color: Colors.blueGrey,
                                        ),
                                        iconSize: 27,
                                        onPressed: () =>
                                            {removeFavoriteMovie(rd['id'], context)},
                                      ),
                                    ),
                                  ),
                                ]),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
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
