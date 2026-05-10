import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:moblie_flutter_app/movie_card.dart';
import 'package:moblie_flutter_app/movie_details.dart';
import 'package:moblie_flutter_app/api_config.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTrendingMovies();
  }

  Future<void> fetchTrendingMovies() async {
    final fetchMovieUrl = Uri.parse('http://$apiHost/api/trending');
    try {
      final response = await http.get(fetchMovieUrl);
      if (!mounted) return;
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                  if (_isLoading && allMovieData.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 80),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Same responsive grid math as Discover: ~2 cols on
                        // phones, ~4 on tablets / phone landscape, ~6 on iPad
                        // landscape. Cards stay near the 175dp target.
                        const spacing = 15.0;
                        const targetCardWidth = 175.0;
                        final available = constraints.maxWidth;
                        final columns =
                            (available / (targetCardWidth + spacing))
                                .round()
                                .clamp(2, 6);
                        final cardWidth =
                            (available - spacing * (columns - 1)) / columns;
                        final cardHeight = cardWidth * (370 / 175);
                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: allMovieData.map((rd) {
                            return SizedBox(
                              width: cardWidth,
                              height: cardHeight,
                              child: InkWell(
                                onTap: () {
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
                        );
                      },
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

  final loggingendpoint = Uri.http(apiHost, 'logging/add', {
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
