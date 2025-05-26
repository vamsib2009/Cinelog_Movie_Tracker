import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class MovieCard extends StatelessWidget {
  final Map<String, dynamic> allMovieData;

  const MovieCard({super.key, required this.allMovieData});

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

  //Function to process the datetime from JSON to Flutter Display datetime
  String formatCreatedTime(String createdTime) {
    // print(createdTime);
    try {
      // Parse the created time string into a DateTime object
      DateTime dateTime = DateTime.parse(createdTime);

      // Convert the DateTime object to the local time
      DateTime localDateTime = dateTime.toLocal();

      // Define a formatter for date and time
      DateFormat dateFormat = DateFormat.yMMMd(); //.add_jm(); Removed the part where we add the time

      // Format the DateTime object into the desired format
      String formattedDateTime = dateFormat.format(localDateTime);

      return formattedDateTime;
    } catch (e) {
      // Handle error when parsing date
      // print('Error parsing date: $e');
      return 'Invalid Date';
    }
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

        return Container(
          height: 400,
          width: 220,
          //margin: const EdgeInsets.symmetric(vertical: 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              )
            ],
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: Image.network(
                  posterUrl,
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        allMovieData['name'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        allMovieData['description'],
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'IMDB: ${allMovieData['imdbrating']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            allMovieData['category'],
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Watched: ${allMovieData['watched'] ? 'Yes' : 'No'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'OTT: ${allMovieData['ottAvailable'] ? 'Yes' : 'No'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(
                            'Release Date: ${formatCreatedTime(allMovieData['releaseDate'] ?? 'N/A')}',
                            style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
