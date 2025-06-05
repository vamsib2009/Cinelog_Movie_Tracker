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
              'description': json['description'],
              'category': json['category'],
              'imdbrating': json['imdbrating'],
              'releaseDate': json['releaseDate']?.toString() ?? '',
              'ottAvailable': json['ottAvailable'],
              'watched': json['watched'],
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
          Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: RefreshIndicator(
                  onRefresh: fetchMovies,
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: allMovieData.map((rd) {
                        return Container(
                          height: 450,
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