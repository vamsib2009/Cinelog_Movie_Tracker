import 'package:flutter/material.dart';

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
                      containedTFF(_usernameController, 'Username', Icon(Icons.supervised_user_circle_rounded)),
                      SizedBox(height: 20,),
                      containedTFF(_passwordController, 'Password', Icon(Icons.password)),
                      SizedBox(height: 20,),
                      
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
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
          labelText: text,
          border: OutlineInputBorder(),
          prefixIcon: icon),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter some text';
        }
        return null;
      });
}

