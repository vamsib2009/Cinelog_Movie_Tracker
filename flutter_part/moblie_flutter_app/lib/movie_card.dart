import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';


class MovieCard extends StatefulWidget {
  final Map<String, dynamic> allMovieData;

  const MovieCard({super.key, required this.allMovieData});

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {

    bool watched = false;

    @override
      void initState(){
      getWatched(context);
      super.initState();
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
        });
      } else {
        // Handle error or keep default values
        print('Error ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to fetch watched data: $e');
    }
  }


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

  Color getScoreColor(dynamic rating) {
    if (rating == null || rating == 'N/A') return Colors.grey;

    double? score = double.tryParse(rating.toString());
    if (score == null) return Colors.grey;

    if (score >= 8.0) {
      return Colors.green[800]!; // Dark green
    } else if (score >= 6.0) {
      return Colors.green[400]!; // Light green
    } else if (score >= 5.0) {
      return Colors.amber[700]!; // Yellow-orange
    } else {
      return Colors.red[400]!; // Red for poor ratings
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: fetchPoster(widget.allMovieData['name']),
      builder: (context, snapshot) {
        String posterUrl = snapshot.data ??
            'https://dummyimage.com/300x450/cccccc/ffffff&text=No+Poster';

        return Container(
          height: 300,
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
                child: Stack(
                  children: [
                    Image.network(
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
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: getScoreColor(widget.allMovieData['imdbrating'])
                              .withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                size: 12, color: Colors.amber),
                            const SizedBox(width: 3),
                            Text(
                              '${widget.allMovieData['imdbrating'] ?? 'N/A'}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: getCategoryColor(widget.allMovieData['category'])
                                .withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                getCategoryIcon(widget.allMovieData['category']),
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.allMovieData['category'] ?? '',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.white),
                              ),
                            ],
                          )),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.allMovieData['name'] ?? 'Unknown',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.allMovieData['description'] ??
                                'No description available',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Spacer(),
                          Text(
                            'Release: ${formatCreatedTime(widget.allMovieData['releaseDate'])}',
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
                    // 🔘 Transparent button
                    // Positioned(
                    //   bottom: 8,
                    //   right: 8,
                    //   child: ClipRRect(
                    //     borderRadius: BorderRadius.circular(30),
                    //     child: Material(
                    //       color: Colors.black
                    //           .withOpacity(0.5), // semi-transparent black
                    //       child: InkWell(
                    //         onTap: () => _showCategoryOverlay(
                    //             context, allMovieData['category']),
                    //         child: Padding(
                    //           padding: const EdgeInsets.all(6.0),
                    //           child: Icon(
                    //             Icons.category,
                    //             color: Colors.white,
                    //             size: 20,
                    //           ),
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    Positioned(bottom:4, right:4, child: buildWatchedIndicator(watched)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildWatchedIndicator(bool watched) {
  return InkWell(
    splashColor: Colors.transparent,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: watched ? Colors.green : Colors.grey.shade500,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            watched ? Icons.check_circle : Icons.hourglass_empty,
            color: Colors.white,
            size: 16,
          ),
          // const SizedBox(width: 4),
          // Text(
          //   watched ? "Watched" : "Not Watched",
          //   style: const TextStyle(
          //     color: Colors.white,
          //     fontSize: 12,
          //     fontWeight: FontWeight.w500,
          //   ),
          // ),
        ],
      ),
    ),
  );
}


}

//Function to get Color vased on enum

Color getCategoryColor(String? category) {
  switch (category?.toLowerCase()) {
    case 'action':
      return Colors.redAccent;
    case 'adventure':
      return Colors.orange;
    case 'animation':
      return Colors.purple;
    case 'biography':
      return Colors.brown;
    case 'comedy':
      return Colors.yellow[700]!;
    case 'crime':
      return Colors.indigo;
    case 'documentary':
      return Colors.blueGrey;
    case 'drama':
      return Colors.deepOrange;
    case 'family':
      return Colors.teal;
    case 'fantasy':
      return Colors.deepPurple;
    case 'history':
      return Colors.green[900]!;
    case 'horror':
      return Colors.black87;
    case 'musical':
      return Colors.pink;
    case 'mystery':
      return Colors.blue[900]!;
    case 'romance':
      return Colors.pinkAccent;
    case 'scifi':
      return Colors.cyan;
    case 'sport':
      return Colors.green[400]!;
    case 'thriller':
      return Colors.grey[850]!;
    case 'war':
      return Colors.brown[800]!;
    case 'western':
      return Colors.orange[900]!;
    default:
      return Colors.grey; // fallback
  }
}

IconData getCategoryIcon(String? category) {
  switch (category?.toLowerCase()) {
    case 'action':
      return Icons.flash_on;
    case 'adventure':
      return Icons.explore;
    case 'animation':
      return Icons.animation;
    case 'biography':
      return Icons.person;
    case 'comedy':
      return Icons.emoji_emotions;
    case 'crime':
      return Icons.gavel;
    case 'documentary':
      return Icons.video_library;
    case 'drama':
      return Icons.theater_comedy;
    case 'family':
      return Icons.family_restroom;
    case 'fantasy':
      return Icons.auto_awesome;
    case 'history':
      return Icons.menu_book;
    case 'horror':
      return Icons.nightlight_round;
    case 'musical':
      return Icons.music_note;
    case 'mystery':
      return Icons.question_mark;
    case 'romance':
      return Icons.favorite;
    case 'scifi':
      return Icons.travel_explore;
    case 'sport':
      return Icons.sports_soccer;
    case 'thriller':
      return Icons.local_police;
    case 'war':
      return Icons.military_tech;
    case 'western':
      return Icons.west;
    default:
      return Icons.movie;
  }
}

void _showCategoryOverlay(BuildContext context, String? category) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(getCategoryIcon(category)),
                const SizedBox(width: 8),
                Text(
                  category ?? 'Unknown',
                  style: GoogleFonts.montserrat(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // You can add more metadata, similar movies, etc., here
          ],
        ),
      );
    },
  );
}
