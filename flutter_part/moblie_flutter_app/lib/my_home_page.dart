import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:moblie_flutter_app/movie_card.dart';
import 'package:moblie_flutter_app/movie_details.dart';
import 'package:moblie_flutter_app/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> allMovieData = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  // Search state. _activeSearch is the query currently applied to the list -
  // empty means we're in paginated-browse mode. _searchVersion stamps each
  // search request so a stale response can't overwrite a newer one (e.g. user
  // submits "Inception", then quickly clears and submits "Tenet" before the
  // first reply lands).
  String _activeSearch = '';
  int _searchVersion = 0;

  @override
  void initState() {
    super.initState();
    fetchMovies(); // First page
    _scrollController.addListener(() {
      // Pagination only applies to the regular browse view, not search results.
      if (_activeSearch.isEmpty &&
          _scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 300 &&
          !_isLoading &&
          _hasMore) {
        fetchMovies(); // Load next page
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
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
  if (_isLoading) return;
  setState(() {
    _isLoading = true;
  });

  final fetchMovieUrl = Uri.parse('http://$apiHost/api/movies?page=$_currentPage&size=15');
  try {
    final response = await http.get(fetchMovieUrl);
    if (!mounted) return;
    if (response.statusCode == 200) {
      print(_currentPage);
      List<dynamic> data = json.decode(response.body);
      setState(() {
        allMovieData.addAll(data.map<Map<String, dynamic>>((json) {
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
        }));

        _hasMore = data.length == 15; // If less than size, no more pages
        _currentPage++;
      });
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  // Called per keystroke. We DO NOT search here - searching only happens on
  // submit (Enter). This handler just keeps the X clear icon in sync and
  // auto-resets to the paginated browse if the user manually deletes all
  // characters.
  void _onSearchChanged(String value) {
    if (value.trim().isEmpty && _activeSearch.isNotEmpty) {
      _resetToPaginated();
      return;
    }
    setState(() {}); // refresh the X suffix-icon visibility
  }

  // Restore the regular paginated browse list. Used when the user clears the
  // search box or presses the X button.
  void _resetToPaginated() {
    if (_activeSearch.isEmpty) return; // already in browse mode
    _searchVersion++; // invalidate any in-flight search
    setState(() {
      _activeSearch = '';
      allMovieData = [];
      _currentPage = 0;
      _hasMore = true;
    });
    fetchMovies();
  }

  Future<void> _runSearch(String keyword) async {
    final myVersion = ++_searchVersion;
    setState(() {
      _activeSearch = keyword;
      _isLoading = true;
    });

    final fetchMovieUrl =
        Uri.parse('http://$apiHost/api/search?keyword=$keyword');
    try {
      final response = await http.get(fetchMovieUrl);
      // Discard if a newer search has been kicked off in the meantime.
      if (myVersion != _searchVersion || !mounted) return;

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
          _hasMore = false; // search results aren't paginated
        });
      } else {
        print('Failed to fetch movies. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching movies: $e');
    } finally {
      if (mounted && myVersion == _searchVersion) {
        setState(() => _isLoading = false);
      }
    }
  }

  TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main Body
        Padding(
          padding: const EdgeInsets.only(
              left: 27.0, right: 12.0, top: 12.0, bottom: 85),
          child: RefreshIndicator(
            onRefresh: fetchMovies,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                constraints: BoxConstraints(minHeight: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    searchField(),
                    SizedBox(height: 10),
                    if (_isLoading && allMovieData.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 80),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Column count is derived from available width so the
                        // grid adapts: ~2 cols on phones, ~4 on tablets / phone
                        // landscape, ~6 on iPad landscape. Cards stay near the
                        // original 175dp target instead of stretching huge.
                        const spacing = 15.0;
                        const targetCardWidth = 175.0;
                        final available = constraints.maxWidth;
                        final columns = (available / (targetCardWidth + spacing))
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
                              height: cardHeight,
                              width: cardWidth,
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
        ),
      ],
    );
  }

  Widget searchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(width: 0.5),
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.grey.withValues(alpha: 0.3),
        //     spreadRadius: 2,
        //     blurRadius: 5,
        //     // offset: Offset(0, 3),
        //   ),
        // ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: _onSearchChanged,
        // Search only fires on Enter - typing alone never hits the network.
        onSubmitted: (v) {
          final t = v.trim();
          if (t.isEmpty) {
            _resetToPaginated();
          } else {
            _runSearch(t);
          }
        },
        decoration: InputDecoration(
          hintText: 'Search Movies',
          border: InputBorder.none,
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    _resetToPaginated();
                  },
                )
              : null,
        ),
      ),
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
