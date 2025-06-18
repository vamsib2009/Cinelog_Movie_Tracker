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

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final poster = data['Poster'];
        if (poster != null && poster != 'N/A') {
          return poster;
        }
      }
    } catch (_) {
      // Ignore and fall back to default
    }

    return 'https://dummyimage.com/300x450/cccccc/ffffff&text=No+Poster';
  }

  String formatCreatedTime(String? createdTime) {
    if (createdTime == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(createdTime).toLocal();
      return DateFormat.yMMMd().format(dateTime);
    } catch (_) {
      return 'Invalid Date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: fetchPoster(allMovieData['name']),
      builder: (context, snapshot) {
        String posterUrl = snapshot.data ??
            'https://dummyimage.com/300x450/cccccc/ffffff&text=No+Poster';

        return Container(
          height: 400,
          width: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 3,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.network(
                  posterUrl,
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.network(
                    'https://dummyimage.com/300x450/cccccc/ffffff&text=No+Poster',
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        allMovieData['name'] ?? 'Unknown',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        allMovieData['description'] ?? 'No description available',
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
                            'IMDB: ${allMovieData['imdbrating'] ?? 'N/A'}',
                            style: GoogleFonts.montserrat(fontSize: 10),
                          ),
                          Text(
                            allMovieData['category'] ?? '',
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      //const Spacer(),
                      Text(
                        'Release: ${formatCreatedTime(allMovieData['releaseDate'])}',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
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
