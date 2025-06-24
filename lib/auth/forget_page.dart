import 'package:flutter/material.dart';

class ForgetPage extends StatelessWidget {
  const ForgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Forgot Password',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(
              width: MediaQuery.sizeOf(context).width * 0.8,
              child: const Text(
                "Please enter your email address to reset your password.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Form(
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Enter Email Address',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                     
                    },
                    child: const Text('Verify Email'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
