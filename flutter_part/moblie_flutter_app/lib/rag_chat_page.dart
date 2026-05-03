import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:moblie_flutter_app/api_config.dart';
import 'package:moblie_flutter_app/movie_card.dart' show getCategoryColor, getCategoryIcon;
import 'package:moblie_flutter_app/movie_details.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ChatMessage {
  final String role; // 'user' | 'assistant' | 'error'
  final String text;
  final List<Map<String, dynamic>>? movies;

  _ChatMessage({required this.role, required this.text, this.movies});
}

class RagChatPage extends StatefulWidget {
  const RagChatPage({Key? key}) : super(key: key);

  @override
  State<RagChatPage> createState() => _RagChatPageState();
}

class _RagChatPageState extends State<RagChatPage> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final query = _controller.text.trim();
    if (query.isEmpty || _loading) return;

    // Build history BEFORE adding the new user message. Skip error bubbles —
    // they aren't part of the model's prior output. Cap at 3 turns (6 msgs).
    final priorTurns = _messages
        .where((m) => m.role == 'user' || m.role == 'assistant')
        .toList();
    final recent = priorTurns.length <= 6
        ? priorTurns
        : priorTurns.sublist(priorTurns.length - 6);
    final historyJson = recent
        .map((m) => {'role': m.role, 'content': m.text})
        .toList();

    setState(() {
      _messages.add(_ChatMessage(role: 'user', text: query));
      _loading = true;
      _controller.clear();
    });
    _scrollToBottom();

    final httpClient = http.Client();
    bool assistantStarted = false;
    try {
      final url = Uri.http(ragHost, '/search/stream');
      final req = http.Request('POST', url)
        ..headers['Content-Type'] = 'application/json'
        ..body = json.encode({
          'query': query,
          'max_suggestions': 3,
          'history': historyJson,
        });

      final resp = await httpClient.send(req);
      debugPrint('[rag] /search/stream status=${resp.statusCode}');

      if (resp.statusCode != 200) {
        final body = await resp.stream.bytesToString();
        debugPrint('[rag] error body: $body');
        setState(() {
          _messages.add(_ChatMessage(
            role: 'error',
            text: 'Server error ${resp.statusCode}: $body',
          ));
        });
        return;
      }

      // SSE stream: events are `data: <json>\n\n`. We buffer raw chunks and
      // split on the SSE event boundary ourselves, since intermediate proxies
      // sometimes coalesce or split lines unexpectedly.
      String buffer = '';
      int eventCount = 0;
      await for (final chunk in resp.stream.transform(utf8.decoder)) {
        buffer += chunk;
        while (true) {
          final idx = buffer.indexOf('\n\n');
          if (idx < 0) break;
          final eventBlock = buffer.substring(0, idx);
          buffer = buffer.substring(idx + 2);
          for (final line in eventBlock.split('\n')) {
            if (!line.startsWith('data: ')) continue;
            eventCount++;
            if (eventCount <= 3) debugPrint('[rag] event: $line');
        final dynamic event;
        try {
          event = json.decode(line.substring(6));
        } catch (_) {
          continue;
        }

        final type = event['type'];
        if (type == 'text') {
          final delta = (event['delta'] ?? '').toString();
          if (delta.isEmpty) continue;
          if (!assistantStarted) {
            assistantStarted = true;
            setState(() {
              _loading = false; // hide typing dots
              _messages.add(_ChatMessage(role: 'assistant', text: delta));
            });
          } else {
            setState(() {
              final last = _messages.last;
              _messages[_messages.length - 1] = _ChatMessage(
                role: 'assistant',
                text: last.text + delta,
                movies: last.movies,
              );
            });
          }
          _scrollToBottom();
        } else if (type == 'done') {
          final rawMovies = event['movies'];
          final movies = rawMovies is List
              ? rawMovies.map<Map<String, dynamic>>((m) {
                  final raw = Map<String, dynamic>.from(m as Map);
                  return {
                    ...raw,
                    'actorNames': List<String>.from(raw['actorNames'] ?? []),
                    'language': List<String>.from(raw['language'] ?? []),
                    'country': List<String>.from(raw['country'] ?? []),
                    'tags': List<String>.from(raw['tags'] ?? []),
                  };
                }).toList()
              : null;
          if (!assistantStarted) {
            // Edge case: no text streamed (shouldn't happen, but safe).
            setState(() {
              _loading = false;
              _messages.add(_ChatMessage(
                role: 'assistant',
                text: '',
                movies: movies,
              ));
            });
          } else if (movies != null) {
            setState(() {
              final last = _messages.last;
              _messages[_messages.length - 1] = _ChatMessage(
                role: 'assistant',
                text: last.text,
                movies: movies,
              );
            });
          }
          _scrollToBottom();
            }
          }
        }
      }
      debugPrint('[rag] stream closed. total events=$eventCount');
    } catch (e, st) {
      debugPrint('[rag] exception: $e\n$st');
      setState(() {
        _messages.add(_ChatMessage(
          role: 'error',
          text: 'Could not reach the RAG service. Is uvicorn running?\n($e)',
        ));
      });
    } finally {
      httpClient.close();
      if (mounted) setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'What are you feeling to\nwatch or learn about\ntoday?',
              textAlign: TextAlign.center,
              style: GoogleFonts.bebasNeue(
                fontSize: 44,
                color: Colors.white,
                letterSpacing: 1.4,
                height: 1.05,
                shadows: [
                  Shadow(
                    color: Colors.green.shade400.withOpacity(0.5),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Try: "feel-good telugu family movie" or\n"who directed Inception?"',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.white.withOpacity(0.55),
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Markdown styling for assistant messages — matches the chat bubble theme.
  late final MarkdownStyleSheet _markdownStyle = MarkdownStyleSheet(
    p: GoogleFonts.poppins(
        color: Colors.white, fontSize: 14, height: 1.4),
    strong: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w700),
    em: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 14,
        height: 1.4,
        fontStyle: FontStyle.italic),
    listBullet: GoogleFonts.poppins(
        color: Colors.white, fontSize: 14, height: 1.4),
    h1: GoogleFonts.poppins(
        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
    h2: GoogleFonts.poppins(
        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
    h3: GoogleFonts.poppins(
        color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
    code: GoogleFonts.firaCode(
        color: Colors.amber.shade200,
        fontSize: 13,
        backgroundColor: Colors.black.withOpacity(0.35)),
    codeblockDecoration: BoxDecoration(
      color: Colors.black.withOpacity(0.35),
      borderRadius: BorderRadius.circular(6),
    ),
    blockquote: GoogleFonts.poppins(
        color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic),
    blockquoteDecoration: BoxDecoration(
      border: Border(
        left: BorderSide(color: Colors.green.shade300, width: 3),
      ),
    ),
    blockquotePadding: const EdgeInsets.only(left: 10, top: 2, bottom: 2),
    a: TextStyle(
        color: Colors.green.shade300,
        decoration: TextDecoration.underline),
    blockSpacing: 6,
    listIndent: 16,
  );

  Widget _buildMessage(_ChatMessage m) {
    final isUser = m.role == 'user';
    final isError = m.role == 'error';
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isUser
        ? Colors.green.shade700.withOpacity(0.85)
        : isError
            ? Colors.red.shade700.withOpacity(0.85)
            : Colors.white.withOpacity(0.12);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              border: Border.all(
                color: isUser
                    ? Colors.green.shade300.withOpacity(0.4)
                    : Colors.white.withOpacity(0.1),
              ),
            ),
            child: (isUser || isError)
                ? Text(
                    m.text,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  )
                : MarkdownBody(
                    // Markdown treats a lone `\n` as a soft break (no gap).
                    // Promote single newlines to blank-line paragraph breaks,
                    // but leave existing `\n\n` runs untouched so we don't
                    // create absurd vertical gaps.
                    data: m.text.replaceAll(
                      RegExp(r'(?<!\n)\n(?!\n)'),
                      '\n\n',
                    ),
                    selectable: false,
                    styleSheet: _markdownStyle,
                  ),
          ),
          if (m.movies != null && m.movies!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                height: 190,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: m.movies!.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (ctx, i) =>
                      _ChatMovieCard(movie: m.movies![i]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: _TypingDots(),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ask anything about your movies...',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.08),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: _loading
                ? Colors.green.shade900
                : Colors.green.shade600,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _loading ? null : _send,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.arrow_upward,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Reserve space at the bottom so the input bar sits above the
    // draggable nav sheet (which is ~13% of screen height when collapsed).
    final bottomReserve = MediaQuery.of(context).size.height * 0.15;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomReserve),
      child: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.only(top: 12, bottom: 12),
                    itemCount: _messages.length + (_loading ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i >= _messages.length) return _buildLoadingBubble();
                      return _buildMessage(_messages[i]);
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }
}

class _ChatMovieCard extends StatefulWidget {
  final Map<String, dynamic> movie;
  const _ChatMovieCard({required this.movie});

  @override
  State<_ChatMovieCard> createState() => _ChatMovieCardState();
}

class _ChatMovieCardState extends State<_ChatMovieCard> {
  String? _posterUrl;
  bool _watched = false;

  @override
  void initState() {
    super.initState();
    _loadPoster();
    _loadWatched();
  }

  Future<void> _loadPoster() async {
    const apiKey = '2774b611';
    final title = (widget.movie['name'] ?? '').toString();
    if (title.isEmpty) return;
    final url = 'http://www.omdbapi.com/?t=$title&apikey=$apiKey';
    try {
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final poster = data['Poster'];
        if (poster != null && poster != 'N/A' && mounted) {
          setState(() => _posterUrl = poster);
        }
      }
    } catch (_) {}
  }

  Future<void> _loadWatched() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    final movieId = int.tryParse(widget.movie['id'].toString()) ?? 0;
    if (userId == null) return;
    final uri = Uri.http(apiHost, 'watched/getwatched', {
      'movieId': movieId.toString(),
      'userId': userId.toString(),
    });
    try {
      final resp = await http.get(uri);
      if (resp.statusCode == 200 && mounted) {
        final data = json.decode(resp.body);
        setState(() => _watched = data['watched'] ?? false);
      }
    } catch (_) {}
  }

  Color _scoreColor(dynamic rating) {
    final s = double.tryParse((rating ?? '').toString());
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
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 3,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _watchedDot() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _watched ? Colors.green : Colors.grey.shade600,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
      ),
      child: Icon(
        _watched ? Icons.check : Icons.hourglass_empty,
        color: Colors.white,
        size: 12,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MovieDetails(allMovieData: movie),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 130,
          height: 190,
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
            children: [
              // Poster fills the whole card
              Positioned.fill(
                child: _posterUrl == null
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
                        _posterUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.black26,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image,
                              color: Colors.white70, size: 28),
                        ),
                      ),
              ),
              // Watched indicator (top-left)
              Positioned(
                top: 6,
                left: 6,
                child: _watchedDot(),
              ),
              // IMDb badge (top-right)
              Positioned(
                top: 6,
                right: 6,
                child: _glassBadge(
                  color: _scoreColor(movie['imdbrating']).withOpacity(0.85),
                  icon: Icons.star,
                  text: '${movie['imdbrating'] ?? 'N/A'}',
                ),
              ),
              // Category badge (bottom-left)
              Positioned(
                bottom: 6,
                left: 6,
                child: _glassBadge(
                  color: getCategoryColor(movie['category']?.toString())
                      .withOpacity(0.8),
                  icon: getCategoryIcon(movie['category']?.toString()),
                  text: (movie['category'] ?? '').toString(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (ctx, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final t = (_ctrl.value + i * 0.2) % 1.0;
              final scale = 0.55 + (1 - (t - 0.5).abs() * 2) * 0.55;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 8 * scale,
                height: 8 * scale,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                  shape: BoxShape.circle,
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
