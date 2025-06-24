import 'package:flutter/material.dart';
import 'package:ramstech/auth/forget_page.dart';
import 'package:ramstech/auth/sign_up_page.dart';
import 'package:ramstech/pages/home_page.dart';
import 'package:ramstech/services/firebase_auth_service.dart';
import 'package:ramstech/widgets/custom_button.dart';
import 'package:ramstech/widgets/google_auth_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final bool _isLoadingGoogle = false;
  bool _obscureText = true;
  bool _rememberMe = false;

  @override
  void dispose() {
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
                  'Hello Again',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.8,
                  child: const Text(
                    "Welcome back, You've been missed!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Enter Email Address',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
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
                          prefixIcon: Icon(Icons.lock_outline),
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                        obscureText: _obscureText,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                // title: const Text('Remember me'),
                                value: _rememberMe,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },

                                semanticLabel: 'Remember me',
                                // controlAffinity: ListTileControlAffinity.leading,
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _rememberMe = !_rememberMe;
                                  });
                                },
                                child: const Text(
                                  'Remember me',
                                  style: TextStyle(fontSize: 13.0),
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ForgetPage(),
                                ),
                              );
                            },
                            child: const Text('Forgot Password?'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      CustomButton(
                        label: "Sign In",
                        isLoading: _isLoading,
                        onPressed: () {
                          _login();
                        },
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
                              GoogleAuthButton(
                                onPressed: _googleSignIn,
                                isLoading: _isLoading,
                              )
                            ],
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account?"),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignUpPage(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(' Sign Up'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _login() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseAuthMethod.signIn(
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
