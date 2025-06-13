import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moblie_flutter_app/my_home_page.dart';
import 'package:moblie_flutter_app/other_screens/favorites.dart';
import 'package:moblie_flutter_app/other_screens/trending.dart';
import 'package:moblie_flutter_app/other_screens/watchlist.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';

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
    _selectedPage = 1;
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
        return Favorite();
      default:
        return MyHomePage(title: 'All Movies');
    }
  }

  AppBar buildBeautifulAppBar(String title, BuildContext context) {
    return AppBar(
      elevation: 20,
      toolbarHeight: 65,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: IconButton(
          icon: Icon(
            CupertinoIcons.square_arrow_left,
            color: Colors.green.shade900,
          ),
          iconSize: 30,
          splashRadius: 24,
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.clear();
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFE8F5E9), // Light green (shade50)
              Color(0xFFE8F5E9), // Light green (shade50)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 5,
                offset: Offset(2, 2)),
          ],
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.bebasNeue(
          fontSize: 30,
          fontWeight: FontWeight.w600,
          color: Colors.green.shade900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  final List<String> _titles = [
    'Dummy',
    'Welcome!',
    'Trending This Week!',
    'Watchlist',
    'MY Favorites',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFECEFF1) // Blue grey 50
      , // Light grey
      appBar: buildBeautifulAppBar(_titles[_selectedPage], context),
      body: Stack(
        children: [
          getSelectedPage(_selectedPage), // Main content
          bottomModalSheet(context), // Draggable sheet on top
        ],
      ),
    );
  }

  Widget bottomModalSheet(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.1, // 20% of screen height
      minChildSize: 0.1,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.green.shade50,
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

  Widget buildIconElements() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(CupertinoIcons.house_fill, 'Home', 1),
          _buildNavItem(CupertinoIcons.flame_fill, 'Trending', 2),
          _buildNavItem(CupertinoIcons.square_list_fill, 'Watchlist', 3),
          _buildNavItem(CupertinoIcons.heart_fill, 'Favorites', 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _selectedPage == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPage = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.green.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.greenAccent.withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? Colors.green.shade900 : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.green.shade700 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
