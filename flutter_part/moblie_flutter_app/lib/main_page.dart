import 'package:flutter/material.dart';
import 'movie_card.dart';

class MyHomePage extends StatelessWidget {
  final String title;

  const MyHomePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      backgroundColor: const Color.fromARGB(115, 158, 158, 158),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to the Movie App!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              MovieCard(),
            ],
          ),
        ),
      ),
    );
  }
}
