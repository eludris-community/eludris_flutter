import 'package:eludris/routes/loggedin.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _controller = TextEditingController();

  //boolean to deactivate the button
  bool buttonEnabled = true;

  //Method to validate input
  validateNameInput(String input) {
    if (input.trim().length < 2 || input.trim().length > 32) {
      setState(() {
        buttonEnabled = false;
      });
    } else {
      setState(() {
        buttonEnabled = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
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
                    onChanged: validateNameInput,
                    onSubmitted: (String value) {
                      if (buttonEnabled) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => LoggedIn(
                              value,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: buttonEnabled
                        ? () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => LoggedIn(
                                      _controller.text,
                                    )));
                          }
                        : null,
                    child: const Text('Login'),
                  ),
                ),
              ),
            ],
          ),
          Visibility(
            visible: !buttonEnabled,
              child: const Text('Username must be between 2 and 32 characters long',  style: TextStyle(color: Colors.red),)),
        ],
      ),
    );
  }
}
