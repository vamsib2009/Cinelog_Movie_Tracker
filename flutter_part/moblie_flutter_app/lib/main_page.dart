import 'package:flutter/material.dart';
import 'package:moblie_flutter_app/movie_details.dart';
import 'movie_card.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> allMovieData = [];
  int _selectedIndex = 0; // Track the selected page index

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

  // Function to handle page changes
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildBeautifulAppBar("All Movies"),
      backgroundColor: const Color.fromARGB(115, 158, 158, 158),
      body: Stack(
        children: [
          // Main Body
          SafeArea(
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
          ),
          
          // Draggable Bottom Sheet
          SafeArea(
            child: DraggableScrollableSheet(
              initialChildSize: 0.1, // Initial height (10% of the screen)
              minChildSize: 0.1, // Minimum height (10% of the screen)
              maxChildSize: 0.5, // Maximum height (50% of the screen)
              builder: (context, scrollController) {
                return Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      // 4 Icons for Navigation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          IconButton(
                            icon: Icon(Icons.home),
                            onPressed: () {
                              _onItemTapped(0); // Navigate to home
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.auto_graph),
                            onPressed: () {
                              _onItemTapped(1); // Navigate to settings
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.favorite),
                            onPressed: () {
                              _onItemTapped(2); // Navigate to profile
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.list),
                            onPressed: () {
                              _onItemTapped(3); // Navigate to notifications
                            },
                          ),
                        ],
                      ),
                      // ListView inside the bottom sheet
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: 3, // Change as per your content
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text('Item $index'),
                              onTap: () {
                                // Handle item tap if needed
                                print('Item $index tapped');
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
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
