import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

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
      DateFormat dateFormat = DateFormat
          .yMMMd(); //.add_jm(); Removed the part where we add the time

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
          height: 200,
          width: 150,
          //margin: const EdgeInsets.symmetric(vertical: 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 1,
                offset: Offset(1, 1),
              )
            ],
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                child: Image.network(
                  posterUrl,
                  height: 270,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        allMovieData['name'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        allMovieData['description'],
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'IMDB: ${allMovieData['imdbrating']}',
                            style: GoogleFonts.montserrat(fontSize: 10),
                          ),
                          Text(
                            allMovieData['category'],
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Watched: ${allMovieData['watched'] ? 'Yes' : 'No'}',
                            style: GoogleFonts.montserrat(fontSize: 10),
                          ),
                          Text(
                            'OTT: ${allMovieData['ottAvailable'] ? 'Yes' : 'No'}',
                            style: GoogleFonts.montserrat(fontSize: 10),
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
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
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
