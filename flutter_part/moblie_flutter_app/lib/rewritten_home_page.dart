import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moblie_flutter_app/my_home_page.dart';
import 'package:moblie_flutter_app/other_screens/favorites.dart';
import 'package:moblie_flutter_app/other_screens/trending.dart';
import 'package:moblie_flutter_app/other_screens/watchlist.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';

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

  PreferredSizeWidget buildBeautifulAppBar(String title, BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: ClipRRect(
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.black.withOpacity(0.35),
              elevation: 20,
              centerTitle: true,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  color: Colors.greenAccent.shade400,
                    iconSize: 28,
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  splashRadius: 24,
                ),
              ),
              title: Padding(
                padding: const EdgeInsets.only(top:8.0),
                child: Text(
                  title,
                  style: GoogleFonts.bebasNeue(
                    fontSize: 32,
                    color: Colors.white,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        color: Colors.green.shade400.withOpacity(0.6),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: IconButton(
                    icon: const Icon(CupertinoIcons.square_arrow_right),
                    color: Colors.greenAccent.shade400,
                    iconSize: 28,
                    splashRadius: 24,
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
              shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
            ),
          ),
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
  Widget buildSideDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade800, Colors.green.shade400],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircleAvatar(
                  radius: 35,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/300'),
                ),
                SizedBox(height: 10),
                Text("Welcome User", style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.movie),
            title: const Text("Movies"),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text("Favorites"),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: () {
              Navigator.pop(context); // Close drawer
              // Handle logout logic
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFF0D1B2A) // Deep Navy
        , // Light grey
        appBar: buildBeautifulAppBar(_titles[_selectedPage], context),
        drawer: buildSideDrawer(context), // 👈 Include this here

        body: Stack(
          children: [
            getSelectedPage(_selectedPage), // Main content
            bottomModalSheet(context), // Draggable sheet on top
          ],
        ),
      ),
    );
  }
Widget bottomModalSheet(BuildContext context) {
  return DraggableScrollableSheet(
    initialChildSize: 0.13,
    minChildSize: 0.13,
    maxChildSize: 0.8,
    builder: (context, scrollController) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // ⬇️ Grab handle
                  Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  buildIconElements(),
                  const SizedBox(height: 20),

                  // Add your custom content here
                  Text(
                    'Explore More Content',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.green.shade900,
                    ),
                  ),
                  const SizedBox(height: 300),
                  const Text('Even more...'),
                  const SizedBox(height: 300),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

  Widget buildIconElements() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
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
      duration: const Duration(milliseconds: 50),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFC8E6C9).withOpacity(0.25) // softer than 0xFFE8F5E9
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF2E7D32)
                      .withOpacity(0.25), // shadow like dark green
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
            size: 26,
            color: isSelected ? const Color(0xFF1B5E20) : Colors.grey.shade500,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color:
                  isSelected ? const Color(0xFF004D40) : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    ),
  );
}
}
