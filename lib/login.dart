import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'main.dart'; // This gives access to appLocale and isDarkMode


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String sanitizeEmail(String email) {
    return email.replaceAll('.', ',');
  }

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _obscurePassword = true;
  bool _isLoading = false;

  bool _showErrorBox = false;
  double _errorOpacity = 1.0;
  String? _customErrorMessage;

  String? _emailErrorMessage;
  String? _passwordErrorMessage;

  void _showForgotPasswordDialog() {
    final overlay = Overlay.of(context);
    final TextEditingController _resetEmailController = TextEditingController();

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black54,
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Reset Password',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Enter your registered email and we will send you a password reset link.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Email address',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => entry.remove(),
                        child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final email = _resetEmailController.text.trim();
                          if (email.isEmpty) {
                            entry.remove();
                            _showPopUp("Please enter your email");
                            return;
                          }

                          try {
                            await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                            entry.remove();
                            _showPopUp("Password reset email sent!");
                          } on FirebaseAuthException catch (e) {
                            entry.remove();
                            if (e.code == 'user-not-found') {
                              _showPopUp("No user found with that email.");
                            } else if (e.code == 'invalid-email') {
                              _showPopUp("Invalid email format.");
                            } else {
                              _showPopUp("Failed to send reset email.");
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Send', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
  }

  Future<void> _setUserLanguageAfterLogin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final emailKey = sanitizeEmail(user.email!);
    final snapshot = await FirebaseDatabase.instance.ref("Profile Data/$emailKey").get();

    if (snapshot.exists) {
      final data = snapshot.value as Map;
      final language = data['language'] ?? 'English';

      String langCode;
      switch (language) {
        case 'Hindi':
          langCode = 'hi';
          break;
        case 'Marathi':
          langCode = 'mr';
          break;
        case 'Gujarati':
          langCode = 'gu';
          break;
        default:
          langCode = 'en';
      }

      appLocale.value = Locale(langCode);
    } else {
      appLocale.value = const Locale('en');
    }
  }

  Future<void> _loginUser() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    setState(() {
      _emailErrorMessage = null;
      _passwordErrorMessage = null;
      _showErrorBox = false;
      _customErrorMessage = null;
    });

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        if (email.isEmpty) _emailErrorMessage = 'Please enter your email';
        if (password.isEmpty) _passwordErrorMessage = 'Please enter your password';
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);

      await _setUserLanguageAfterLogin();

      final emailKey = sanitizeEmail(email);
      final dbRef = FirebaseDatabase.instance.ref("Users/$emailKey/firstTime");
      final snapshot = await dbRef.once();
      final firstTime = snapshot.snapshot.value;

      if (firstTime == null || firstTime == true) {
        await _setUserLanguageAfterLogin(); // Load user's saved language
        Navigator.pushReplacementNamed(context, '/msq');
      } else {
        await _setUserLanguageAfterLogin(); // Load user's saved language
        Navigator.pushReplacementNamed(context, '/home');
      }


      _showPopUp('Login successful');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        _showPopUp('Check your internet connection');
      } else if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-email') {
        setState(() {
          _emailErrorMessage = 'Incorrect email';
          _passwordErrorMessage = 'Incorrect password';
        });
      } else {
        _showPopUp('Login failed');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      final email = userCred.user?.email ?? '';
      final emailKey = sanitizeEmail(email);
      final name = userCred.user?.displayName ?? 'User';

      final userRef = FirebaseDatabase.instance.ref().child('Users').child(emailKey);
      final snapshot = await userRef.get();

      if (!snapshot.exists) {
        await userRef.set({
          'username': name,
          'email': email,
          'location': '',
          'firstTime': true,
          'theme': 'light',
          'preferences': {
            'favCuisine': '',
            'favTime': '',
            'priceLevel': '',
            'favSnack': ''
          }
        });
        Navigator.pushReplacementNamed(context, '/msq');
      } else {
        final firstTime = snapshot.child('firstTime').value == true;
        Navigator.pushReplacementNamed(context, firstTime ? '/msq' : '/home');
      }
    } catch (_) {
      _showPopUp('Check your internet connection');
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
            child: Image.asset('assets/loginpage.jpg', fit: BoxFit.cover),
          ),
          Center(
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
                  const Text('Login', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      labelStyle: const TextStyle(color: Colors.black),
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: _emailErrorMessage != null ? Colors.red : Colors.black),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: _emailErrorMessage != null ? Colors.red : Colors.black),
                      ),
                    ),
                  ),
                  if (_emailErrorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(_emailErrorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                    ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      labelStyle: const TextStyle(color: Colors.black),
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: _passwordErrorMessage != null ? Colors.red : Colors.black),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: _passwordErrorMessage != null ? Colors.red : Colors.black),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.black),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  if (_passwordErrorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(_passwordErrorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/register'),
                        child: const Text('new user?Register', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                    onPressed: _loginUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('Login', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 10),
                  const Text('or', style: TextStyle(color: Colors.black)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _signInWithGoogle,
                    child: Image.asset('assets/google.png', height: 35, width: 35),
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
                    color: Colors.grey[800],
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
