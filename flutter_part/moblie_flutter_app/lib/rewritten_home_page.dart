import 'package:flutter/material.dart';
import 'package:moblie_flutter_app/my_home_page.dart';
import 'package:moblie_flutter_app/other_screens/favorites.dart';
import 'package:moblie_flutter_app/other_screens/trending.dart';
import 'package:moblie_flutter_app/other_screens/watchlist.dart';
import 'package:shared_preferences/shared_preferences.dart';


class RewrittenHomePage extends StatefulWidget {
  const RewrittenHomePage({Key? key}) : super(key: key);

  @override
  _RewrittenHomePageState createState() => _RewrittenHomePageState();
}

class _RewrittenHomePageState extends State<RewrittenHomePage> {
  late int _selectedPage;
  
  @override
  void initState() {
    super.initState();
    _selectedPage =1;
  }

Widget getSelectedPage(int index) {
  switch (index) {
    case 1:
      return MyHomePage(title: 'All Movies');
    case 2:
      return Trending();
    case 3:
      return Watchlist();
    case 4:
      return Favorites();
    default:
      return MyHomePage(title: 'All Movies');
  }
}

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
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: buildBeautifulAppBar('All Movies'),
    body: Stack(
      children: [
        getSelectedPage(_selectedPage),          // Main content
        bottomModalSheet(context), // Draggable sheet on top
      ],
    ),
  );
}


  Widget bottomModalSheet(BuildContext context) {
  return DraggableScrollableSheet(
    initialChildSize: 0.1,  // 20% of screen height
    minChildSize: 0.1,
    maxChildSize: 0.8,
    builder: (context, scrollController) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.greenAccent,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          controller: scrollController, // Needed for dragging to work
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              children: [
                buildIconElements(),
                SizedBox(height: 300),
                Text('More content...'),
                SizedBox(height: 300),
                Text('Even more...'),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget buildIconElements()
{
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      IconButton(
        icon: const Icon(Icons.home_filled),
        iconSize: 40,
        onPressed: () {
          setState(() {
            _selectedPage = 1;
          });
        },
      ),
      IconButton(
        icon: const Icon(Icons.whatshot_outlined),
        iconSize: 40,
        onPressed: () {
          setState(() {
            _selectedPage = 2;
          });

        },
      ),
      IconButton(
        icon: const Icon(Icons.list_outlined),
        iconSize: 40,
        onPressed: () {
          setState(() {
            _selectedPage = 3;
          });

        },
      ),
      IconButton(
        icon: const Icon(Icons.favorite_outline),
        iconSize: 40,
        onPressed: () {
          setState(() {
            _selectedPage = 4;
          });
        },
      ),
    ],
  );
}

}


