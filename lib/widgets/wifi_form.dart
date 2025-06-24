import 'package:flutter/material.dart';

class WifiForm extends StatefulWidget {
  final Function(String ssid, String password) onSubmit;

  const WifiForm({super.key, required this.onSubmit});

  @override
  _WifiFormState createState() => _WifiFormState();
}

class _WifiFormState extends State<WifiForm> {
  final _formKey = GlobalKey<FormState>();
  String _ssid = '';
  String _password = '';

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            decoration: InputDecoration(labelText: 'SSID'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the SSID';
              }
              return null;
            },
            onChanged: (value) {
              setState(() {
                _ssid = value;
              });
            },
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'Password'),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the password';
              }
              return null;
            },
            onChanged: (value) {
              setState(() {
                _password = value;
              });
            },
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                widget.onSubmit(_ssid, _password);
              }
            },
            child: Text('Send Credentials'),
          ),
        ],
      ),
    );
  }
}
