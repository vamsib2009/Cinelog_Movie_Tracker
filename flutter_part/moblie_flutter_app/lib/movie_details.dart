import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:moblie_flutter_app/api_config.dart';
import 'package:moblie_flutter_app/movie_card.dart'
    show getCategoryColor, getCategoryIcon;
import 'package:moblie_flutter_app/my_home_page.dart' show addlogfx;
import 'package:shared_preferences/shared_preferences.dart';

const _bgColor = Color(0xFF0D1B2A); // matches rewritten_home_page.dart
const _omdbApiKey = '2774b611';

class MovieDetails extends StatefulWidget {
  final Map<String, dynamic> allMovieData;
  const MovieDetails({super.key, required this.allMovieData});

  @override
  State<MovieDetails> createState() => _MovieDetailsState();
}

class _MovieDetailsState extends State<MovieDetails> {
  // Async-loaded fields. Defaults shown until the relevant fetch settles.
  String? _posterUrl;
  bool _watched = false;
  double? _userRating;
  String? _userReview;
  List<int>? _stats;
  List<Map<String, dynamic>> _similar = [];
  int? _userId;

  bool _statsLoading = true;
  bool _similarLoading = true;

  int get _movieId =>
      int.tryParse(widget.allMovieData['id'].toString()) ?? 0;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  // Single entry-point: load userId, then fan out to four parallel fetches.
  // Replaces the old setup which fetched poster/stats from inside FutureBuilder
  // on every rebuild, and never called getWatched at all.
  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final uid = prefs.getInt('userId') ?? 0;
    setState(() => _userId = uid);
    await Future.wait([
      _loadPoster(),
      _loadWatched(),
      _loadStats(uid),
      _loadSimilar(),
    ]);
  }

  Future<void> _loadPoster() async {
    final title = (widget.allMovieData['name'] ?? '').toString();
    if (title.isEmpty) return;
    try {
      final resp = await http.get(
          Uri.parse('http://www.omdbapi.com/?t=$title&apikey=$_omdbApiKey'));
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final poster = data['Poster'];
        if (poster != null && poster != 'N/A') {
          setState(() => _posterUrl = poster);
        }
      }
    } catch (_) {}
  }

  Future<void> _loadWatched() async {
    if (_userId == null) return;
    final uri = Uri.http(apiHost, 'watched/getwatched', {
      'movieId': _movieId.toString(),
      'userId': _userId.toString(),
    });
    try {
      final resp = await http.get(uri);
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          _watched = data['watched'] ?? false;
          _userRating = (data['userRating'] as num?)?.toDouble();
          _userReview = data['userReview'];
        });
      }
    } catch (_) {}
  }

  Future<void> _loadStats(int userId) async {
    final url = Uri.http(apiHost, '/logging/get', {
      'movieId': _movieId.toString(),
      'userId': userId.toString(),
    });
    try {
      final resp = await http.get(url);
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        setState(() {
          _stats = data.cast<int>();
          _statsLoading = false;
        });
      } else {
        setState(() => _statsLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  Future<void> _loadSimilar() async {
    final id = widget.allMovieData['id'].toString();
    final url =
        Uri.parse('http://$apiHost/api/similarmoviesbyposter?movieId=$id');
    try {
      final resp = await http.get(url);
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as List<dynamic>;
        setState(() {
          _similar = data
              .map<Map<String, dynamic>>((j) => {
                    'id': j['id']?.toString() ?? '',
                    'name': j['name']?.toString() ?? '',
                    'description': j['description'] ?? '',
                    'directorName': j['directorName']?.toString() ?? '',
                    'category': j['category'] ?? '',
                    'imdbrating': j['imdbrating'] ?? 0.0,
                    'releaseDate': j['releaseDate']?.toString() ?? '',
                    'language': j['language'] ?? '',
                    'country': j['country'] ?? '',
                    'actorNames': List<String>.from(j['actorNames'] ?? []),
                    'tags': List<String>.from(j['tags'] ?? []),
                  })
              .toList();
          _similarLoading = false;
        });
      } else {
        setState(() => _similarLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _similarLoading = false);
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      return DateFormat.yMMMd().format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return '';
    }
  }

  // ------- ACTIONS -------

  Future<void> _addToFavorites() async {
    if (_userId == null) return;
    final uri = Uri.http(apiHost, 'favorites/add', {
      'userId': _userId.toString(),
      'movieId': _movieId.toString(),
    });
    try {
      final resp = await http.post(uri);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(resp.body)));
    } catch (_) {}
  }

  Future<void> _addToWatchlist() async {
    if (_userId == null) return;
    final uri = Uri.http(apiHost, 'watchlist/add', {
      'userId': _userId.toString(),
      'movieId': _movieId.toString(),
    });
    try {
      final resp = await http.post(uri);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(resp.body)));
    } catch (_) {}
  }

  Future<void> _toggleWatched() async {
    if (_userId == null) return;
    final uri = Uri.http(apiHost, 'watched/toggle', {
      'userId': _userId.toString(),
      'movieId': _movieId.toString(),
    });
    try {
      await http.put(uri);
      if (!mounted) return;
      await _loadWatched();
    } catch (_) {}
  }

  void _openReviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewSheet(
        movieName: (widget.allMovieData['name'] ?? 'Movie').toString(),
        initialRating: _userRating ?? 5.0,
        initialReview: _userReview ?? '',
        onSubmit: _submitReview,
      ),
    );
  }

  Future<void> _submitReview(double rating, String review) async {
    if (_userId == null) return;
    final url = Uri.parse('http://$apiHost/watched/updaterating');
    try {
      final resp = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': _userId.toString(),
          'movieId': _movieId.toString(),
          'userRating': rating,
          'userReview': review,
        }),
      );
      if (!mounted) return;
      if (resp.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted')),
        );
        await _loadWatched();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error ${resp.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: $e')),
      );
    }
  }

  // ------- BUILD -------

  @override
  Widget build(BuildContext context) {
    final m = widget.allMovieData;
    final name = (m['name'] ?? '').toString();
    final description = (m['description'] ?? '').toString();
    final director = (m['directorName'] ?? '').toString();
    final category = (m['category'] ?? '').toString();
    final rating = m['imdbrating'];
    final releaseDate = m['releaseDate']?.toString();
    final actors = List<String>.from(m['actorNames'] ?? []);
    final language = (m['language'] is List)
        ? (m['language'] as List).cast<String>().join(', ')
        : (m['language'] ?? '').toString();
    final country = (m['country'] is List)
        ? (m['country'] as List).cast<String>().join(', ')
        : (m['country'] ?? '').toString();
    final tags = List<String>.from(m['tags'] ?? []);

    return Scaffold(
      backgroundColor: _bgColor,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: Colors.black.withOpacity(0.35),
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.greenAccent.shade400),
              title: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.bebasNeue(
                  fontSize: 26,
                  color: Colors.white,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      color: Colors.green.shade400.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 90, 16, 32),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Wide screens (landscape phone, tablets, iPad) split the hero
            // poster off into a fixed-width left column with all the cards
            // stacking on the right - keeps the poster from stretching huge
            // and the card column readable. The "More like this" carousel
            // always spans full width below.
            final wide = constraints.maxWidth >= 700;

            final detailsBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailsCard(name, releaseDate, description, director,
                    language, country, actors),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _tagsRow(tags),
                ],
                const SizedBox(height: 18),
                _yourActivityCard(),
                const SizedBox(height: 14),
                _statsCard(),
                const SizedBox(height: 22),
                _actionGrid(wide: wide),
              ],
            );

            if (wide) {
              // Cap poster width so it doesn't stretch absurdly on iPad
              // landscape (~1180dp would otherwise give a 440dp poster).
              final posterWidth = constraints.maxWidth * 0.36;
              final clampedPoster = posterWidth.clamp(260.0, 360.0);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: clampedPoster,
                        child: _heroPoster(category, rating),
                      ),
                      const SizedBox(width: 24),
                      Expanded(child: detailsBlock),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _similarSection(),
                ],
              );
            }

            // Narrow / portrait phone: original single-column layout.
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heroPoster(category, rating),
                const SizedBox(height: 18),
                detailsBlock,
                const SizedBox(height: 28),
                _similarSection(),
              ],
            );
          },
        ),
      ),
    );
  }

  // ------- COMPONENTS -------

  Widget _heroPoster(String category, dynamic rating) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _posterUrl != null
                ? Image.network(
                    _posterUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _posterFallback(),
                  )
                : _posterFallback(),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 130,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: _glassBadge(
                color: _ratingColor(rating).withOpacity(0.85),
                icon: Icons.star,
                text: 'IMDb ${rating ?? 'N/A'}',
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: _watchedDot(),
            ),
            if (category.isNotEmpty)
              Positioned(
                bottom: 12,
                left: 12,
                child: _glassBadge(
                  color: getCategoryColor(category).withOpacity(0.8),
                  icon: getCategoryIcon(category),
                  text: category,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _posterFallback() {
    return Container(
      color: Colors.black26,
      alignment: Alignment.center,
      child: const Icon(Icons.movie, color: Colors.white24, size: 80),
    );
  }

  Widget _watchedDot() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _watched ? Colors.green.shade600 : Colors.grey.shade700,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
      ),
      child: Icon(
        _watched ? Icons.check : Icons.hourglass_empty,
        color: Colors.white,
        size: 16,
      ),
    );
  }

  Color _ratingColor(dynamic r) {
    final s = double.tryParse((r ?? '').toString());
    if (s == null) return Colors.grey;
    if (s >= 8.0) return Colors.green.shade800;
    if (s >= 6.0) return Colors.green.shade400;
    if (s >= 5.0) return Colors.amber.shade700;
    return Colors.red.shade400;
  }

  Widget _glassBadge({
    required Color color,
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 8,
                offset: Offset(2, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _detailsCard(
    String name,
    String? releaseDate,
    String description,
    String director,
    String language,
    String country,
    List<String> actors,
  ) {
    final formatted = _formatDate(releaseDate);
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: GoogleFonts.bebasNeue(
              fontSize: 32,
              color: Colors.white,
              letterSpacing: 1.2,
              height: 1.0,
            ),
          ),
          if (formatted.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                formatted,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.5,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (director.isNotEmpty)
            _infoRow(Icons.movie_creation, 'Director', director),
          if (language.isNotEmpty)
            _infoRow(Icons.language, 'Language', language),
          if (country.isNotEmpty) _infoRow(Icons.public, 'Country', country),
          if (actors.isNotEmpty)
            _infoRow(Icons.people, 'Cast', actors.join(', ')),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.greenAccent.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagsRow(List<String> tags) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: tags.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            alignment: Alignment.center,
            child: Text(
              '#${tags[i]}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white.withOpacity(0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _yourActivityCard() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.greenAccent.shade400),
              const SizedBox(width: 8),
              Text(
                'YOUR ACTIVITY',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _watched
                      ? Colors.green.shade600.withOpacity(0.85)
                      : Colors.grey.shade700.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _watched ? Icons.check_circle : Icons.hourglass_empty,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _watched ? 'Watched' : 'Not Watched',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_userRating != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _ratingColor(_userRating).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        _userRating!.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (_userReview != null && _userReview!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
                border: Border(
                  left: BorderSide(color: Colors.green.shade300, width: 3),
                ),
              ),
              child: Text(
                _userReview!,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withOpacity(0.85),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statsCard() {
    Widget body;
    if (_statsLoading) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_stats == null || _stats!.length != 3) {
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Stats unavailable',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withOpacity(0.5),
          ),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      body = Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem(Icons.visibility, _stats![0], 'Views'),
          _statItem(Icons.favorite, _stats![1], 'Favorited'),
          _statItem(Icons.check_circle, _stats![2], 'Watched'),
        ],
      );
    }
    return _glassCard(child: body);
  }

  Widget _statItem(IconData icon, int count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.greenAccent.shade400, size: 24),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _actionGrid({bool wide = false}) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // 4 across on landscape/tablet so the buttons stack as one tidy row
      // instead of two huge ones; 2 across on phones.
      crossAxisCount: wide ? 4 : 2,
      childAspectRatio: wide ? 2.6 : 3.2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _actionTile(
          icon: _watched ? Icons.check_circle : Icons.check_circle_outline,
          label: _watched ? 'Unmark Watched' : 'Mark Watched',
          color: Colors.green.shade600,
          onTap: _toggleWatched,
        ),
        _actionTile(
          icon: Icons.list_alt,
          label: 'Watchlist',
          color: Colors.teal.shade600,
          onTap: _addToWatchlist,
        ),
        _actionTile(
          icon: Icons.favorite,
          label: 'Favorite',
          color: Colors.red.shade400,
          onTap: _addToFavorites,
        ),
        _actionTile(
          icon: Icons.rate_review,
          label: _userReview != null ? 'Edit Review' : 'Write Review',
          color: Colors.indigo.shade400,
          onTap: _openReviewSheet,
        ),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.85), color.withOpacity(0.55)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _similarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Icon(Icons.auto_awesome,
                  size: 18, color: Colors.greenAccent.shade400),
              const SizedBox(width: 8),
              Text(
                'MORE LIKE THIS',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: _similarLoading
              ? const Center(child: CircularProgressIndicator())
              : _similar.isEmpty
                  ? Center(
                      child: Text(
                        'No similar movies found',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.zero,
                      itemCount: _similar.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) =>
                          _SimilarCard(movie: _similar[i]),
                    ),
        ),
      ],
    );
  }
}

// Each card loads its OMDB poster ONCE on first mount and caches it in
// State - the parent screen no longer triggers refetches on every rebuild.
class _SimilarCard extends StatefulWidget {
  final Map<String, dynamic> movie;
  const _SimilarCard({required this.movie});

  @override
  State<_SimilarCard> createState() => _SimilarCardState();
}

class _SimilarCardState extends State<_SimilarCard> {
  String? _poster;

  @override
  void initState() {
    super.initState();
    _loadPoster();
  }

  Future<void> _loadPoster() async {
    final title = (widget.movie['name'] ?? '').toString();
    if (title.isEmpty) return;
    try {
      final resp = await http.get(
          Uri.parse('http://www.omdbapi.com/?t=$title&apikey=$_omdbApiKey'));
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final p = data['Poster'];
        if (p != null && p != 'N/A') setState(() => _poster = p);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        addlogfx(widget.movie['id']);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MovieDetails(allMovieData: widget.movie),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 130,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withOpacity(0.15)),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 6,
                offset: Offset(2, 4),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _poster == null
                  ? Container(
                      color: Colors.black26,
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                    )
                  : Image.network(
                      _poster!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.black26,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image,
                            color: Colors.white70, size: 28),
                      ),
                    ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.85),
                      ],
                    ),
                  ),
                  child: Text(
                    (widget.movie['name'] ?? '').toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewSheet extends StatefulWidget {
  final String movieName;
  final double initialRating;
  final String initialReview;
  final Future<void> Function(double rating, String review) onSubmit;
  const _ReviewSheet({
    required this.movieName,
    required this.initialRating,
    required this.initialReview,
    required this.onSubmit,
  });

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  late double _rating;
  late TextEditingController _reviewCtrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
    _reviewCtrl = TextEditingController(text: widget.initialReview);
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Color _ratingColor(double r) {
    if (r >= 8.0) return Colors.green.shade800;
    if (r >= 6.0) return Colors.green.shade400;
    if (r >= 5.0) return Colors.amber.shade700;
    return Colors.red.shade400;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF132238),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.15)),
          left: BorderSide(color: Colors.white.withOpacity(0.15)),
          right: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.movieName,
            style: GoogleFonts.bebasNeue(
              fontSize: 26,
              color: Colors.white,
              letterSpacing: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Rate and review',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _ratingColor(_rating).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _rating.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.greenAccent.shade400,
                    inactiveTrackColor: Colors.white.withOpacity(0.2),
                    thumbColor: Colors.greenAccent.shade400,
                    overlayColor:
                        Colors.greenAccent.shade400.withOpacity(0.2),
                    valueIndicatorColor: Colors.greenAccent.shade700,
                  ),
                  child: Slider(
                    value: _rating,
                    min: 0,
                    max: 10,
                    divisions: 100,
                    label: _rating.toStringAsFixed(1),
                    onChanged: (v) => setState(() => _rating = v),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reviewCtrl,
            maxLines: 4,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
            cursorColor: Colors.greenAccent.shade400,
            decoration: InputDecoration(
              hintText: 'Write your review...',
              hintStyle: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.4),
                fontSize: 13,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Colors.white.withOpacity(0.15)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Colors.white.withOpacity(0.15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.greenAccent.shade400),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  label: Text('Cancel',
                      style: GoogleFonts.poppins(color: Colors.white70)),
                  onPressed:
                      _submitting ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: _submitting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                  label: Text('Submit',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _submitting
                      ? null
                      : () async {
                          setState(() => _submitting = true);
                          await widget.onSubmit(_rating, _reviewCtrl.text);
                          if (mounted) {
                            setState(() => _submitting = false);
                          }
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
