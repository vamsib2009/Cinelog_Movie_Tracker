import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MovieDetails extends StatelessWidget {
  final Map<String, dynamic> allMovieData;

  const MovieDetails({super.key, required this.allMovieData});

  Future<String> fetchPoster(String title) async {
    const apiKey = '2774b611';
    final url = 'http://www.omdbapi.com/?t=$title&apikey=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['Poster'] ?? '';
    } else {
      throw Exception('Failed to load poster');
    }
  }

  String formatCreatedTime(String createdTime) {
    try {
      DateTime dateTime = DateTime.parse(createdTime);
      DateTime localDateTime = dateTime.toLocal();
      DateFormat dateFormat = DateFormat.yMMMd();
      return dateFormat.format(localDateTime);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  Future<List<int>> fetchMovieStats(int movieId, int userId) async {
    final url = Uri.http(
      '10.0.2.2:8080',
      '/logging/get',
      {
        'movieId': movieId.toString(),
        'userId': userId.toString(),
      },
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<int>();
      } else {
        throw Exception('Failed to load stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching stats: $e');
    }
  }

  Widget buildStatsRow(List<int> stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(Icons.visibility, stats[0], 'Page Views'),
          _buildStatItem(Icons.favorite, stats[1], 'Favorited'),
          _buildStatItem(Icons.check_circle, stats[2], 'Users Watched'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, int count, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  Future<int> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: fetchPoster(allMovieData['name']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        String posterUrl = snapshot.data ?? 'https://via.placeholder.com/150';

        return FutureBuilder<int>(
          future: getUserId(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            int userId = userSnapshot.data!;
            int movieId = int.tryParse(allMovieData['id'].toString()) ?? 0;

            return Scaffold(
              appBar: AppBar(
                backgroundColor: const Color.fromARGB(255, 46, 46, 46),
                title: Text(
                  allMovieData['name'],
                  style: const TextStyle(color: Colors.white),
                ),
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              backgroundColor: const Color.fromARGB(115, 158, 158, 158),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        posterUrl,
                        height: 350,
                        width: 240,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      allMovieData['name'],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      allMovieData['description'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      children: [
                        Chip(
                          label: Text('IMDB: ${allMovieData['imdbrating']}'),
                          backgroundColor: Colors.orange.shade100,
                        ),
                        Chip(
                          label: Text(allMovieData['category']),
                          backgroundColor: Colors.blue.shade100,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    /// 🔥 Stats Section
                    FutureBuilder<List<int>>(
                      future: fetchMovieStats(movieId, userId),
                      builder: (context, statSnapshot) {
                        if (statSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (statSnapshot.hasError) {
                          return const Text('Failed to load stats',
                              style: TextStyle(color: Colors.red));
                        } else if (!statSnapshot.hasData ||
                            statSnapshot.data!.length != 3) {
                          return const Text('No stats available');
                        }
                        return buildStatsRow(statSnapshot.data!);
                      },
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.remove_red_eye, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          'Watched: ${allMovieData['watched'] ? 'Yes' : 'No'}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white),
                        ),
                        const SizedBox(width: 15),
                        Icon(Icons.tv, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          'OTT: ${allMovieData['ottAvailable'] ? 'Yes' : 'No'}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'Release Date: ${formatCreatedTime(allMovieData['releaseDate'] ?? 'N/A')}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          onPressed: () => addToFavorites(context),
                          icon: Icon(Icons.favorite_sharp, color: Colors.red[600]),
                          label: Text(
                            'Add to Favorites',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.7),
                            padding:
                                EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => addToWatchlist(context),
                          icon: Icon(Icons.list_rounded, color: Colors.black),
                          label: Text(
                            'Add to Watchlist',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.7),
                            padding:
                                EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> addToFavorites(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('userId');

    int movieId = int.tryParse(allMovieData['id'].toString()) ?? 0;

    final addfavendpoint = Uri.http('10.0.2.2:8080', 'favorites/add', {
      'userId': userId.toString(),
      'movieId': movieId.toString(),
    });

    try {
      final response = await http.post(addfavendpoint);
      print(response.statusCode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.body)),
      );
    } catch (e) {
      print('Error login: $e');
    }
  }

    Future<void> addToWatchlist(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('userId');

    int movieId = int.tryParse(allMovieData['id'].toString()) ?? 0;

    final addfavendpoint = Uri.http('10.0.2.2:8080', 'watchlist/add', {
      'userId': userId.toString(),
      'movieId': movieId.toString(),
    });

    try {
      final response = await http.post(addfavendpoint);
      print(response.statusCode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.body)),
      );
    } catch (e) {
      print('Error login: $e');
    }
  }

}
