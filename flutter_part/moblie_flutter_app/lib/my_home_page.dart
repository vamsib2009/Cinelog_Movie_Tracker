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
  final _searchController = TextEditingController();

  AppBar buildBeautifulAppBar(String title) {
    return AppBar(
      elevation: 5,
      toolbarHeight: 60,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 2),
        child: IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          iconSize: 40,
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.clear(); // Optional: Clear user session
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4ECDC4), Color(0xFF556270)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          iconSize: 40,
          onPressed: () {
            // handle search or other action
          },
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    fetchMovies();
  }

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
    return Scaffold(
      appBar: buildBeautifulAppBar("All Movies"),
      backgroundColor: const Color.fromARGB(115, 158, 158, 158),
      body: Stack(
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