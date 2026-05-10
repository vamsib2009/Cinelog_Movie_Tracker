import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moblie_flutter_app/login.dart';
import 'package:moblie_flutter_app/my_home_page.dart';
import 'package:moblie_flutter_app/other_screens/favorites.dart';
import 'package:moblie_flutter_app/other_screens/trending.dart';
import 'package:moblie_flutter_app/other_screens/watchlist.dart';
import 'package:moblie_flutter_app/rag_chat_page.dart';
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
  // Tabs we cache. Once a cached tab is opened, it stays mounted via Offstage
  // so revisiting it doesn't refire any fetches in initState. Ask (index 1)
  // is intentionally not cached - it has no init fetch, and rebuilding is
  // cheap. Discover/Trending/Watchlist/Favorites (2-5) all hit endpoints in
  // initState, so they're worth keeping alive.
  static const _cachedIndices = [2, 3, 4, 5];
  final Set<int> _mountedCached = {};

  @override
  void initState() {
    super.initState();
    _selectedPage = 1;
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF132238),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        title: Text(
          'Sign out?',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'You will need to sign back in to use Cinelog.',
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.7),
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sign out',
                style: GoogleFonts.poppins(
                    color: Colors.greenAccent.shade400,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    // Replace the entire navigation stack with the login screen so the user
    // can't back-navigate into the (now logged-out) home page, and so any
    // cached tab state is fully torn down.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  Widget _buildPageForIndex(int index) {
    switch (index) {
      case 1:
        return const RagChatPage();
      case 2:
        return MyHomePage(title: 'All Movies');
      case 3:
        return Trending();
      case 4:
        return Watchlist();
      case 5:
        return Favorite();
      default:
        return const RagChatPage();
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
              // Drawer not finished yet - hamburger hidden until it ships.
              // Re-enable along with the `drawer:` line on the Scaffold.
              // leading: Builder(
              //   builder: (context) => IconButton(
              //     icon: const Icon(Icons.menu),
              //     color: Colors.greenAccent.shade400,
              //     iconSize: 28,
              //     onPressed: () => Scaffold.of(context).openDrawer(),
              //     splashRadius: 24,
              //   ),
              // ),
              title: Padding(
                padding: const EdgeInsets.only(top: 8.0),
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
                    tooltip: 'Sign out',
                    onPressed: _handleLogout,
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
    'Ask Cinelog',
    'Discover',
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
        //drawer: buildSideDrawer(context),

        body: Stack(
          // The children list keeps a STABLE NUMBER of slots in a fixed order
          // so Flutter's position-based reconciliation preserves State across
          // tab switches. Each cached tab has a permanent slot that flips
          // between SizedBox.shrink (before first visit) and Offstage(page)
          // (after first visit).
          children: [
            // Slot 0: Ask. Always rebuilt fresh, only rendered when active.
            _selectedPage == 1
                ? _buildPageForIndex(1)
                : const SizedBox.shrink(),
            // Slots 1-4: Discover, Trending, Watchlist, Favorites.
            for (final pageIdx in _cachedIndices)
              _mountedCached.contains(pageIdx)
                  ? Offstage(
                      offstage: _selectedPage != pageIdx,
                      child: TickerMode(
                        enabled: _selectedPage == pageIdx,
                        child: _buildPageForIndex(pageIdx),
                      ),
                    )
                  : const SizedBox.shrink(),
            // Last slot: draggable sheet on top.
            bottomModalSheet(context),
          ],
        ),
      ),
    );
  }

  Widget bottomModalSheet(BuildContext context) {
    return DraggableScrollableSheet(
      // 0.13 was tight on shorter devices (640px tall = 83px sheet) - the
      // grab handle + nav row could overflow vertically. 0.15 gives ~10px
      // breathing room everywhere without changing the visual much.
      initialChildSize: 0.15,
      minChildSize: 0.15,
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(25)),
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
          _buildNavItem(CupertinoIcons.sparkles, 'Ask', 1),
          _buildNavItem(CupertinoIcons.compass_fill, 'Discover', 2),
          _buildNavItem(CupertinoIcons.flame_fill, 'Trending', 3),
          _buildNavItem(CupertinoIcons.square_list_fill, 'Watchlist', 4),
          _buildNavItem(CupertinoIcons.heart_fill, 'Favorites', 5),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _selectedPage == index;

    // Expanded gives each of the 5 items an equal slice of the row width so
    // the Row can never overflow horizontally, regardless of device. Center
    // keeps the selected highlight tight around its content (instead of
    // stretching across the whole slot).
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPage = index;
            if (_cachedIndices.contains(index)) _mountedCached.add(index);
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 50),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFC8E6C9)
                      .withOpacity(0.25) // softer than 0xFFE8F5E9
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
                  size: 24,
                  color: isSelected
                      ? const Color(0xFF1B5E20)
                      : Colors.grey.shade500,
                ),
                const SizedBox(height: 4),
                // FittedBox scales the label down if its slot can't fit "Watchlist"
                // / "Favorites" at the chosen font size on very narrow devices.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF004D40)
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
