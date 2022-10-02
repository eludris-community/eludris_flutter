import 'package:eludris/routes/loggedin.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  Home({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Name',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (String value) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => LoggedIn(
                        value,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                child: const Text('Login'),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => LoggedIn(
                            _controller.text,
                          )));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
