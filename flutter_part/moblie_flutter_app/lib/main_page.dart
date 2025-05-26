import 'package:flutter/material.dart';
import 'movie_card.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  Future<void> fetchMovies() async {
    final fetchMovieUrl = Uri.parse('http://10.0.2.2:8080/api/movies');
    try {
      final response = await http.get(fetchMovieUrl);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          allMovieData = data.map<Map<String, dynamic>>((json) {
            return {
              'id': json['id'],
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
      appBar: AppBar(
        title: Text(widget.title),
      ),
      backgroundColor: const Color.fromARGB(115, 158, 158, 158),
      body: SafeArea(
        child: Center(
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
                      child: MovieCard(allMovieData: rd),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
