import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ramstech/auth/login_page.dart';
import 'package:ramstech/pages/home_page.dart';
import 'package:ramstech/services/firebase_auth_service.dart';
import 'package:ramstech/widgets/custom_button.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool check = false;

  // Add loading state
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 25, 10, 10),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const Text(
                  'Welcome',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.8,
                  child: const Text(
                    "Join us and start your journey with us!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Enter Username',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a username';
                            }
                            if (value.length < 3) {
                              return 'Username must be at least 3 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Enter Email Address',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Enter Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                            border: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                            ),
                          ),
                          obscureText: _obscureText,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        CheckboxListTile(
                          value: check,
                          onChanged: (value) {
                            setState(() {
                              check = value!;
                            });
                          },
                          title:
                              const Text("I agree to the terms and conditions"),
                          subtitle: const Text(
                            "By signing up, you agree to our terms and conditions.",
                            style: TextStyle(color: Colors.grey),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: Colors.black,
                          checkColor: Colors.white,
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5)),
                          contentPadding: const EdgeInsets.all(0),
                        ),
                        const SizedBox(height: 10),
                        CustomButton(
                          label: "Sign Up",
                          onPressed: () {
                            _signUp();
                          },
                          disabled: !check,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 30),
                        Column(
                          children: [
                            Text(
                              'or continue with',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                OutlinedButton(
                                  onPressed: () {
                                    // Add Google Sign Up logic
                                  },
                                  style: OutlinedButton.styleFrom(
                                    fixedSize: Size(
                                      MediaQuery.sizeOf(context).width * 0.8,
                                      60,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/images/google-logo.svg',
                                        height: 30,
                                        width: 30,
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Google',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Already have an account?"),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginPage(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text(' Login'),
                            ),
                          ],
                        ),
                      ],
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuthMethod.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await FirebaseAuthMethod.setPersistance(true);
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (context) {
          return const HomePage();
        },
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  _googleSignIn() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await FirebaseAuthMethod.googleSignInAndNavigate(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable To Login with Google: $e'),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
