import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:moblie_flutter_app/movie_card.dart';
import 'package:moblie_flutter_app/movie_details.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> allMovieData = [];

  @override
  void initState() {
    super.initState();
    fetchMovies();
  }

  // void _filterMovies(String query) {
  //   setState(() {
  //     allMovieData = allMovieData.where((movie) {
  //       final movieName = movie['name']?.toLowerCase() ?? '';
  //       final movieDescription = movie['description']?.toLowerCase() ?? '';
  //       final movieCategory = movie['category']?.toLowerCase() ?? '';
  //       return movieName.contains(query.toLowerCase()) ||
  //           movieDescription.contains(query.toLowerCase()) ||
  //           movieCategory.contains(query.toLowerCase());
  //     }).toList();
  //   });
  // }

  Future<void> fetchMovies() async {
    final fetchMovieUrl = Uri.parse('http://10.0.2.2:8080/api/movies');
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
        });
      } else {
        print('Failed to fetch movies. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching movies: $e');
    }
  }

  Future<void> fetchSearchedMovies(String keyword) async {
    final fetchMovieUrl =
        Uri.parse('http://10.0.2.2:8080/api/search?keyword=$keyword');
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
        });
      } else {
        print('Failed to fetch movies. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching movies: $e');
    }
  }

  TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main Body
        Padding(
          padding: const EdgeInsets.only(
              left: 27.0, right: 12.0, top: 12.0, bottom: 85),
          child: RefreshIndicator(
            onRefresh: fetchMovies,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                constraints: BoxConstraints(minHeight: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    searchField(),
                    SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      child: Wrap(
                        spacing: 15,
                        runSpacing: 15,
                        children: allMovieData.map((rd) {
                          return Container(
                            height: 370,
                            width: 175,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.transparent,
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

  Widget searchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(width: 0.5),
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.grey.withValues(alpha: 0.3),
        //     spreadRadius: 2,
        //     blurRadius: 5,
        //     // offset: Offset(0, 3),
        //   ),
        // ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: fetchSearchedMovies,
        onSubmitted: fetchSearchedMovies,
        decoration: InputDecoration(
          hintText: 'Search Movies',
          border: InputBorder.none,
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    fetchSearchedMovies('');
                  },
                )
              : null,
        ),
      ),
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
