import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:moblie_flutter_app/main_page.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool userAuthenticated = false;
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    userAuthenticated = false;
  }

  void handleLogin() async {
      final success = await loginfx(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (success) {
        // Navigate to home or dashboard
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MyHomePage(title: 'Welcome')),
      );
      } else {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed')),
        );
      }
    }

  @override
  Widget build(context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      //Widget for a form, can decorate with a container
                      containedTFF(_usernameController, 'Username',
                          Icon(Icons.supervised_user_circle_rounded)),
                      SizedBox(
                        height: 20,
                      ),
                      containedTFF(_passwordController, 'Password',
                          Icon(Icons.password)),
                      SizedBox(
                        height: 20,
                      ),

                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            handleLogin();
                            _usernameController.clear();
                            _passwordController.clear();
                            ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Signing in...')));

                          }
                        },
                        child: Text('Submit'),
                      )
                    ],
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

Widget containedTFF(var xController, String text, Icon icon) {
  return TextFormField(
      controller: xController,
      decoration: InputDecoration(
          labelText: text, border: OutlineInputBorder(), prefixIcon: icon),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter some text';
        }
        return null;
      });
}

Future<bool> loginfx(String username, String password) async {
  final loginendpoint = Uri.http('10.0.2.2:8080', '/auth/login', {
    'username': username,
    'password': password,
  });

  try {
    final response = await http.post(loginendpoint);

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      print(data);

       SharedPreferences prefs = await SharedPreferences.getInstance();
       await prefs.setInt('userId', data['userId']);
       await prefs.setString('role', data['role']);

      return true;
    }
  } catch (e) {
    print('Error login: $e');
    return false;
  }

  return false;
}
