import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart'; // Adjust the import path if needed

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String sanitizeEmail(String email) {
    return email.replaceAll('.', ',');
  }

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  bool _obscurePassword = true;
  bool _isLoading = false;

  bool _showErrorBox = false;
  double _errorOpacity = 1.0;
  String? _customErrorMessage;

  String? _usernameErrorMessage;
  String? _emailErrorMessage;
  String? _passwordErrorMessage;

  Future<void> _registerUser() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _usernameErrorMessage = null;
      _emailErrorMessage = null;
      _passwordErrorMessage = null;
      _showErrorBox = false;
      _customErrorMessage = null;
    });

    bool hasEmpty = false;
    if (username.isEmpty) {
      _usernameErrorMessage = 'Please fill the username';
      hasEmpty = true;
    }
    if (email.isEmpty) {
      _emailErrorMessage = 'Please fill the email';
      hasEmpty = true;
    }
    if (password.isEmpty) {
      _passwordErrorMessage = 'Please fill the password';
      hasEmpty = true;
    }
    if (hasEmpty) {
      setState(() {});
      return;
    }

    setState(() => _isLoading = true);
    try {
      final UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

// 👇 Add this block for Profile Data (name, email, photoUrl, etc.)
      final emailKey = sanitizeEmail(email);
      final profileRef = FirebaseDatabase.instance.ref("Profile Data/$emailKey");

      await profileRef.set({
        "name": username,
        "email": email,
        "photoUrl": "",
        "language": "English",
        "address": {
          "street1": "",
          "street2": "",
          "pincode": "",
          "city": "",
          "state": "",
          "country": "",
        }
      });

      await _db.child('Users').child(emailKey).set({
        'username': username,
        'email': email,
        'location': '',
        'firstTime': true,
        'theme': 'light',
        'language': 'English',
        'languageCode': 'en',
        'preferences': {
          'favCuisine': '',
          'favTime': '',
          'priceLevel': '',
          'favSnack': ''
        }
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', 'English');
      await prefs.setString('languageCode', 'en');

      appLocale.value = const Locale('en');

      _showPopUp('Registration successful');

      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        _showPopUp('Check your internet connection');
      } else if (e.code == 'email-already-in-use') {
        setState(() => _emailErrorMessage = 'Email already in use');
      } else if (e.code == 'weak-password') {
        setState(() => _passwordErrorMessage = 'Password is too weak');
      } else {
        _showPopUp('Registration failed');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPopUp(String message) {
    setState(() {
      _customErrorMessage = message;
      _showErrorBox = true;
      _errorOpacity = 1.0;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _errorOpacity = 0.0);
    });
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() {
          _showErrorBox = false;
          _customErrorMessage = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset('assets/register.jpg', fit: BoxFit.cover),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 30),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Register',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _usernameController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: const TextStyle(color: Colors.black54),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: _usernameErrorMessage != null ? Colors.red : Colors.black,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: _usernameErrorMessage != null ? Colors.red : Colors.black,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  if (_usernameErrorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _usernameErrorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Colors.black54),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: _emailErrorMessage != null ? Colors.red : Colors.black,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: _emailErrorMessage != null ? Colors.red : Colors.black,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  if (_emailErrorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _emailErrorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Colors.black54),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: _passwordErrorMessage != null ? Colors.red : Colors.black,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: _passwordErrorMessage != null ? Colors.red : Colors.black,
                          width: 2,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.black54,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  if (_passwordErrorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _passwordErrorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Already have an account? Login',
                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                    onPressed: _registerUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('Register', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          if (_showErrorBox && _customErrorMessage != null)
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.15,
              left: 40,
              right: 40,
              child: AnimatedOpacity(
                opacity: _errorOpacity,
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOut,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _customErrorMessage!,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
