import 'package:flutter/material.dart';
//import 'package:http/http.dart' as http;

class MovieCard extends StatelessWidget {

  MovieCard({super.key});


  @override
  Widget build(context)
  {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        height: 400,
        width: 300,
        decoration: BoxDecoration(
          shape:BoxShape.rectangle,
          color: Colors.white54,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
        ),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildProfile(),
            ],
          ),
      ),
    );
  }

Widget buildProfile() {
  //final urlProfile =
  final backgroundProfile =
      'https://images.pexels.com/photos/177598/pexels-photo-177598.jpeg?auto=compress&cs=tinysrgb&w=600';
  final picProfile =
      'https://images.pexels.com/photos/771742/pexels-photo-771742.jpeg?auto=compress&cs=tinysrgb&w=600';

  return Stack(
    clipBehavior: Clip.none,
    children: [
      Container(
        height: 120,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(
              image: NetworkImage(
                backgroundProfile,
              ),
              fit: BoxFit.cover,
              opacity: 0.80,
              alignment: Alignment.center,
            ),
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.deepPurple,
                  Colors.orangeAccent,
                ])),
      ),
      Positioned(
        bottom: -25,
        left: 20,
        right: 20,
        child: Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(60),
              boxShadow: [
                BoxShadow(color: Colors.white, spreadRadius: 4),
              ],
              image: DecorationImage(
                image: NetworkImage(
                  picProfile,
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}


}