import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MovieDetails extends StatefulWidget {
  final Map<String, dynamic> allMovieData;

  const MovieDetails({super.key, required this.allMovieData});

  @override
  State<MovieDetails> createState() => _MovieDetailsState();
}

class _MovieDetailsState extends State<MovieDetails> {
  bool watched = false;

  double? userRating;

  String? userReview;

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
@override
Widget build(BuildContext context) {
  return FutureBuilder<String>(
    future: fetchPoster(widget.allMovieData['name']),
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
          int movieId = int.tryParse(widget.allMovieData['id'].toString()) ?? 0;

          return Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF1C1C1E),
              title: Text(
                widget.allMovieData['name'],
                style: const TextStyle(color: Colors.white),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF121212),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      posterUrl,
                      height: 360,
                      width: 240,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Chip(
                    label: Text(
                      watched ? 'Watched' : 'Not Watched',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor:
                        watched ? Colors.green.shade600 : Colors.grey.shade700,
                  ),
                  const SizedBox(height: 12),

                  Text(
                    widget.allMovieData['name'],
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  Text(
                    widget.allMovieData['description'],
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),
                  Divider(color: Colors.white24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_4, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        'Director: ${widget.allMovieData['directorName'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  Text(
                    userRating != null
                        ? 'User Rating: $userRating'
                        : 'User Rating: N/A',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    userReview != null
                        ? 'User Review: $userReview'
                        : 'User Review: N/A',
                    style: const TextStyle(color: Colors.white70),
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text('IMDB: ${widget.allMovieData['imdbrating']}'),
                        backgroundColor: Colors.deepOrange.shade200,
                      ),
                      Chip(
                        label: Text(widget.allMovieData['category']),
                        backgroundColor: Colors.blueAccent.shade100,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  buildTagChips(widget.allMovieData['tags']),

                  const SizedBox(height: 20),
                  Divider(color: Colors.white24),

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

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        'Released: ${formatCreatedTime(widget.allMovieData['releaseDate'] ?? 'N/A')}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  /// Buttons
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          buildActionButton(
                            onPressed: () => addToFavorites(context),
                            icon: Icons.favorite,
                            label: 'Favorite',
                            color: Colors.redAccent,
                          ),
                          buildActionButton(
                            onPressed: () => addToWatchlist(context),
                            icon: Icons.list,
                            label: 'Watchlist',
                            color: Colors.teal,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          buildActionButton(
                            onPressed: () => toggleWatched(context),
                            icon: watched ? Icons.visibility_off : Icons.visibility,
                            label:
                                watched ? 'Unmark Watched' : 'Mark as Watched',
                            color: Colors.orange,
                          ),
                          buildActionButton(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20)),
                                ),
                                builder: (context) =>
                                    reviewBottomSheetContent(context),
                              );
                            },
                            icon: Icons.rate_review,
                            label: userReview != null
                                ? 'Edit Review'
                                : 'Write Review',
                            color: Colors.indigoAccent,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget buildActionButton({
  required VoidCallback onPressed,
  required IconData icon,
  required String label,
  required Color color,
}) {
  return ElevatedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, color: Colors.white),
    label: Text(label, style: const TextStyle(color: Colors.white)),
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}


  Future<void> addToFavorites(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('userId');

    int movieId = int.tryParse(widget.allMovieData['id'].toString()) ?? 0;

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

  Future<void> getWatched(context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('userId');

    int movieId = int.tryParse(widget.allMovieData['id'].toString()) ?? 0;

    final uri = Uri.http('10.0.2.2:8080', 'watched/getwatched', {
      'movieId': movieId.toString(),
      'userId': userId.toString(),
    });

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          watched = data['watched'] ?? false;
          userRating = (data['userRating'] as num?)?.toDouble();
          userReview = data['userReview'];
        });
      } else {
        // Handle error or keep default values
        print('Error ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to fetch watched data: $e');
    }
  }

  Future<void> toggleWatched(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('userId');

    int movieId = int.tryParse(widget.allMovieData['id'].toString()) ?? 0;

    final addfavendpoint = Uri.http('10.0.2.2:8080', 'watched/toggle', {
      'userId': userId.toString(),
      'movieId': movieId.toString(),
    });

    try {
      final response = await http.put(addfavendpoint);
      print(response.statusCode);
      setState(() {
        getWatched(context);
      });
    } catch (e) {
      print('Error Changing $e');
    }
  }

  Future<void> addToWatchlist(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('userId');

    int movieId = int.tryParse(widget.allMovieData['id'].toString()) ?? 0;

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

  Future<void> _submitReview(
      BuildContext context, double rating, String userReview) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('userId');

    int movieId = int.tryParse(widget.allMovieData['id'].toString()) ?? 0;

    final payload = {
      "userId": userId.toString(),
      "movieId": movieId.toString(),
      "userRating": rating,
      "userReview": userReview,
    };

    final url = Uri.parse("http://10.0.2.2:8080/watched/updaterating");

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Review submitted successfully!")));
        setState(() {
          getWatched(context);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Error: ${response.statusCode} ${response.reasonPhrase}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Submission failed: $e")),
      );
    }
  }

  Widget buildTagChips(List<String> tags) {
    final List<Color> chipColors = [
      Colors.teal.shade100,
      Colors.amber.shade100,
      Colors.pink.shade100,
      Colors.blue.shade100,
      Colors.green.shade100,
      Colors.purple.shade100,
      Colors.orange.shade100,
    ];

    return Center(
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          itemCount: tags.length,
          itemBuilder: (context, index) {
            final tag = tags[index];
            final color = chipColors[index % chipColors.length];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Chip(
                label: Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget reviewBottomSheetContent(context) {
    double userRating = 5.0;
    final TextEditingController reviewController =
        TextEditingController(text: userReview ?? '');

    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Review for ${widget.allMovieData['name'] ?? 'Movie'}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                Slider(
                  value: userRating,
                  min: 0,
                  max: 10,
                  divisions: 100,
                  label: userRating.toStringAsFixed(1),
                  onChanged: (value) => setState(() => userRating = value),
                ),
                TextField(
                  controller: reviewController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: "Write your review",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.send),
                        label: const Text("Submit"),
                        onPressed: () async {
                          await _submitReview(
                            context,
                            userRating,
                            reviewController.text,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.cancel),
                        label: const Text("Cancel"),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
